import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown element tag for inline math (`$...$`).
const String inlineMathTag = 'math_inline';

/// Markdown element tag for display math (`$$...$$` on its own lines).
const String blockMathTag = 'math_block';

/// Inline math: `$...$`, following Pandoc's tex_math_dollars rules so that
/// currency such as "$5 and $10" is not treated as math.
///
/// - The opening `$` must be followed by a non-space character.
/// - The closing `$` must be preceded by a non-space character and must not
///   be followed by a digit.
/// - `\$` is an escaped dollar sign (handled by Markdown's escape syntax,
///   which runs before this one at the backslash position).
class InlineMathSyntax extends md.InlineSyntax {
  InlineMathSyntax()
    : super(r'\$(?=[^\s$])((?:\\.|[^\\$\n])*?[^\s\\$])\$(?!\d)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text(inlineMathTag, match[1]!));
    return true;
  }
}

/// Display math: a paragraph that starts with a `$$` line and ends with a
/// `$$` line. A single line `$$ ... $$` is also accepted.
class BlockMathSyntax extends md.BlockSyntax {
  const BlockMathSyntax();

  static final RegExp _open = RegExp(r'^ {0,3}\$\$(.*)$');
  static final RegExp _close = RegExp(r'^(.*)\$\$\s*$');

  @override
  RegExp get pattern => _open;

  @override
  md.Node parse(md.BlockParser parser) {
    final String first = _open.firstMatch(parser.current.content)![1]!;
    parser.advance();

    final Match? sameLineClose = _close.firstMatch(first);
    if (sameLineClose != null) {
      return md.Element.text(blockMathTag, sameLineClose[1]!.trim());
    }

    final List<String> lines = <String>[if (first.trim().isNotEmpty) first];
    while (!parser.isDone) {
      final String line = parser.current.content;
      parser.advance();
      final Match? close = _close.firstMatch(line);
      if (close != null) {
        lines.add(close[1]!);
        break;
      }
      lines.add(line);
    }
    return md.Element.text(blockMathTag, lines.join('\n').trim());
  }
}

/// Renders [inlineMathTag] inside the surrounding paragraph.
///
/// Returning a `Text.rich` lets flutter_markdown_plus merge the math into the
/// paragraph's single rich text, so it wraps with the text around it.
class InlineMathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String tex = element.textContent;
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Math.tex(
              tex,
              mathStyle: MathStyle.text,
              textStyle: parentStyle,
              onErrorFallback: (FlutterMathException e) =>
                  _MathSource('\$$tex\$', style: parentStyle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [blockMathTag] as a horizontally scrollable display equation.
class BlockMathBuilder extends MarkdownElementBuilder {
  BlockMathBuilder({this.selectable = false});

  /// Uses [SelectableMath], which copies the selected part as TeX.
  final bool selectable;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final String tex = element.textContent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: selectable
            ? _SelectableBlockMath(tex: tex, style: parentStyle)
            : Math.tex(
                tex,
                mathStyle: MathStyle.display,
                textStyle: parentStyle,
                onErrorFallback: (FlutterMathException e) =>
                    _MathSource('\$\$$tex\$\$', style: parentStyle),
              ),
      ),
    );
  }
}

/// A display equation rendered with [SelectableMath] that never opens the
/// software keyboard.
class _SelectableBlockMath extends StatefulWidget {
  const _SelectableBlockMath({required this.tex, this.style});

  final String tex;
  final TextStyle? style;

  @override
  State<_SelectableBlockMath> createState() => _SelectableBlockMathState();
}

class _SelectableBlockMathState extends State<_SelectableBlockMath> {
  final FocusNode _focusNode = _NoKeyboardFocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableMath.tex(
      widget.tex,
      focusNode: _focusNode,
      mathStyle: MathStyle.display,
      textStyle: widget.style,
      onErrorFallback: (FlutterMathException e) =>
          _MathSource('\$\$${widget.tex}\$\$', style: widget.style),
    );
  }
}

/// Keeps [SelectableMath] from opening a text input connection on focus.
///
/// flutter_math_fork 0.7.4 opens a read-only text input connection whenever
/// the widget gains focus with a keyboard token. It exists only to provide
/// the browser context menu on web, but runs on every platform, so tapping a
/// formula shows the software keyboard on Android. Selection and its toolbar
/// do not depend on that connection.
class _NoKeyboardFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() => kIsWeb && super.consumeKeyboardToken();
}

/// Shows the TeX source as-is when it cannot be parsed.
class _MathSource extends StatelessWidget {
  const _MathSource(this.source, {this.style});

  final String source;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      source,
      style: (style ?? const TextStyle()).copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

/// A [MarkdownBody] with `$...$` and `$$...$$` math support.
class MarkdownMathBody extends StatelessWidget {
  const MarkdownMathBody({
    super.key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
  });

  final String data;
  final bool selectable;
  final MarkdownStyleSheet? styleSheet;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      selectable: selectable,
      shrinkWrap: true,
      styleSheet: styleSheet,
      blockSyntaxes: const <md.BlockSyntax>[BlockMathSyntax()],
      inlineSyntaxes: <md.InlineSyntax>[InlineMathSyntax()],
      builders: <String, MarkdownElementBuilder>{
        inlineMathTag: InlineMathBuilder(),
        blockMathTag: BlockMathBuilder(selectable: selectable),
      },
    );
  }
}
