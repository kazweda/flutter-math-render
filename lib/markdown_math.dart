import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import 'math_selection.dart';

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
            child: _InlineMath(tex: tex, style: parentStyle),
          ),
        ],
      ),
    );
  }
}

/// An inline formula. Keeps its TeX so that copying the surrounding
/// selectable text can put the formula back as `$...$`.
class _InlineMath extends StatelessWidget {
  const _InlineMath({required this.tex, this.style});

  final String tex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return MathSelectionAdapter(
      text: '\$$tex\$',
      child: Math.tex(
        tex,
        mathStyle: MathStyle.text,
        textStyle: style,
        onErrorFallback: (FlutterMathException e) =>
            _MathSource('\$$tex\$', style: style),
      ),
    );
  }
}

/// Returns the text of [span] inside [selection], with each inline formula
/// written as `$tex$`.
///
/// SelectableText represents a [WidgetSpan] as U+FFFC, so its own Copy puts
/// that invisible character on the clipboard in place of the formula.
@visibleForTesting
String selectedTextWithTex(InlineSpan span, TextSelection selection) {
  final StringBuffer out = StringBuffer();
  int offset = 0;
  span.visitChildren((InlineSpan child) {
    if (child is TextSpan) {
      final String text = child.text ?? '';
      final int start = (selection.start - offset).clamp(0, text.length);
      final int end = (selection.end - offset).clamp(0, text.length);
      out.write(text.substring(start, end));
      offset += text.length;
    } else if (child is PlaceholderSpan) {
      if (offset >= selection.start && offset < selection.end) {
        final Widget? widget = child is WidgetSpan ? child.child : null;
        out.write(widget is _InlineMath ? '\$${widget.tex}\$' : '\u{FFFC}');
      }
      offset += 1;
    }
    return true;
  });
  return out.toString();
}

/// The default context menu, with Copy writing inline formulas as TeX.
Widget _mathContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) {
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: <ContextMenuButtonItem>[
      for (final ContextMenuButtonItem item
          in editableTextState.contextMenuButtonItems)
        item.type == ContextMenuButtonType.copy
            ? item.copyWith(
                onPressed: () => _copyWithTex(
                  editableTextState,
                  SelectionChangedCause.toolbar,
                ),
              )
            : item,
    ],
  );
}

/// [EditableTextState.copySelection] with inline formulas copied as TeX.
void _copyWithTex(EditableTextState state, SelectionChangedCause cause) {
  final TextEditingValue value = state.textEditingValue;
  final InlineSpan? span = state.renderEditable.text;
  if (value.selection.isCollapsed || span == null) return;
  Clipboard.setData(
    ClipboardData(text: selectedTextWithTex(span, value.selection)),
  );
  if (cause != SelectionChangedCause.toolbar) return;
  state.bringIntoView(value.selection.extent);
  state.hideToolbar(false);
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      break;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
      // Collapse the selection and hide the toolbar and handles.
      state.userUpdateTextEditingValue(
        TextEditingValue(
          text: value.text,
          selection: TextSelection.collapsed(offset: value.selection.end),
        ),
        SelectionChangedCause.toolbar,
      );
  }
}

/// Copy with the keyboard (⌘C / Ctrl+C) from selectable text.
class _CopyWithTexIntent extends Intent {
  const _CopyWithTexIntent();
}

/// The platform's copy shortcut, as in [DefaultTextEditingShortcuts].
SingleActivator _copyActivator() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return const SingleActivator(LogicalKeyboardKey.keyC, meta: true);
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return const SingleActivator(LogicalKeyboardKey.keyC, control: true);
  }
}

/// Copies the selection of the focused selectable text with [_copyWithTex].
///
/// Disabled when the focus is elsewhere (for example in a [SelectableMath]),
/// so the key falls through to the default handling.
class _CopyWithTexAction extends ContextAction<_CopyWithTexIntent> {
  EditableTextState? _state(BuildContext? context) =>
      context?.findAncestorStateOfType<EditableTextState>();

  @override
  bool isEnabled(_CopyWithTexIntent intent, [BuildContext? context]) {
    final EditableTextState? state = _state(context);
    return state != null && !state.textEditingValue.selection.isCollapsed;
  }

  @override
  void invoke(_CopyWithTexIntent intent, [BuildContext? context]) {
    final EditableTextState? state = _state(context);
    if (state != null) _copyWithTex(state, SelectionChangedCause.keyboard);
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
            : MathSelectionAdapter(
                text: '\$\$$tex\$\$',
                child: Math.tex(
                  tex,
                  mathStyle: MathStyle.display,
                  textStyle: parentStyle,
                  onErrorFallback: (FlutterMathException e) =>
                      _MathSource('\$\$$tex\$\$', style: parentStyle),
                ),
              ),
      ),
    );
  }
}

/// A display equation rendered with [SelectableMath].
class _SelectableBlockMath extends StatelessWidget {
  const _SelectableBlockMath({required this.tex, this.style});

  final String tex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SelectableMath.tex(
      tex,
      textSelectionControls: _selectionControls(Theme.of(context).platform),
      mathStyle: MathStyle.display,
      textStyle: style,
      onErrorFallback: (FlutterMathException e) =>
          _MathSource('\$\$$tex\$\$', style: style),
    );
  }
}

/// The toolbar controls for [platform], or null for SelectableMath's default.
TextSelectionControls? _selectionControls(TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return _cupertinoMathSelectionControls;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return null;
  }
}

final TextSelectionControls _cupertinoMathSelectionControls =
    _CupertinoMathSelectionControls();

/// Cupertino controls that offer Select all unless the whole formula is
/// already selected, as Material does.
///
/// Cupertino offers it only for a collapsed selection, which a formula never
/// has once the toolbar is shown, so iOS would never offer it.
class _CupertinoMathSelectionControls extends CupertinoTextSelectionControls {
  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
        value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
  }
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
///
/// When [selectable], copying puts inline formulas on the clipboard as
/// `$...$`, from the context menu and from the keyboard (⌘C / Ctrl+C). On web
/// the context menu is the browser's unless the app calls
/// [BrowserContextMenu.disableContextMenu]; the keyboard shortcut works either
/// way, since it is handled here before the browser's own copy.
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
    final Widget body = MarkdownBody(
      data: data,
      selectable: selectable,
      contextMenuBuilder: _mathContextMenuBuilder,
      shrinkWrap: true,
      styleSheet: styleSheet,
      blockSyntaxes: const <md.BlockSyntax>[BlockMathSyntax()],
      inlineSyntaxes: <md.InlineSyntax>[InlineMathSyntax()],
      builders: <String, MarkdownElementBuilder>{
        inlineMathTag: InlineMathBuilder(),
        blockMathTag: BlockMathBuilder(selectable: selectable),
      },
    );
    if (!selectable) return LineBreakSelectionContainer(child: body);
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        _copyActivator(): const _CopyWithTexIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CopyWithTexIntent: _CopyWithTexAction(),
        },
        child: body,
      ),
    );
  }
}
