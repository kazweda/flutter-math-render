import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_render/markdown_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

/// Returns the tex of every math node, prefixed with `i:` or `b:`.
List<String> parseMath(String source) {
  final md.Document doc = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: const <md.BlockSyntax>[BlockMathSyntax()],
    inlineSyntaxes: <md.InlineSyntax>[InlineMathSyntax()],
    encodeHtml: false,
  );
  final List<String> found = <String>[];
  void walk(List<md.Node> nodes) {
    for (final md.Node n in nodes) {
      if (n is md.Element) {
        if (n.tag == inlineMathTag) found.add('i:${n.textContent}');
        if (n.tag == blockMathTag) found.add('b:${n.textContent}');
        if (n.children != null) walk(n.children!);
      }
    }
  }

  walk(doc.parse(source));
  return found;
}

void main() {
  group('inline math', () {
    test('simple', () {
      expect(parseMath(r'解は $x^2$ です'), <String>['i:x^2']);
    });
    test('multiple in one line', () {
      expect(parseMath(r'$a$ と $b$'), <String>['i:a', 'i:b']);
    });
    test('currency is not math', () {
      expect(parseMath(r'$5 and $10'), isEmpty);
      expect(parseMath(r'price: $5-$10'), isEmpty);
      expect(parseMath(r'it costs $ 5 or $ 10'), isEmpty);
    });
    test('escaped dollar is not math', () {
      expect(parseMath(r'\$x\$'), isEmpty);
    });
    test('dollar inside code span is not math', () {
      expect(parseMath(r'`$x$`'), isEmpty);
    });
    test('escaped dollar inside math', () {
      expect(parseMath(r'$\$5$'), <String>[r'i:\$5']);
    });
    test('underscore and asterisk are kept as TeX', () {
      expect(parseMath(r'$a_1 * b_2$'), <String>['i:a_1 * b_2']);
    });
  });

  group('block math', () {
    test('multi line', () {
      expect(parseMath('\$\$\n\\frac{1}{2}\n\$\$'), <String>[r'b:\frac{1}{2}']);
    });
    test('single line', () {
      expect(parseMath(r'$$\sqrt{2}$$'), <String>[r'b:\sqrt{2}']);
    });
    test('matrix with line breaks', () {
      expect(
        parseMath(
          '\$\$\n\\begin{pmatrix} a & b \\\\\nc & d \\end{pmatrix}\n\$\$',
        ),
        <String>['b:\\begin{pmatrix} a & b \\\\\nc & d \\end{pmatrix}'],
      );
    });
  });

  group('widget', () {
    const String sample = '''
## 見出し

文中の \$x^2\$ と分数 \$\\frac{1}{2}\$ を含む段落。

\$\$
\\int_0^1 x\\,dx
\$\$

- リスト内 \$\\sqrt{2}\$
- 通貨 \$5 and \$10

不正な式 \$\\frac{1}{\$
''';

    for (final bool selectable in <bool>[false, true]) {
      testWidgets('renders without exceptions (selectable: $selectable)', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarkdownMathBody(data: sample, selectable: selectable),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        // 3 inline formulas, 1 invalid one shown as source, and the block
        // formula when it is not selectable.
        expect(find.byType(Math), findsNWidgets(selectable ? 4 : 5));
        // The block formula is selectable only when the body is selectable.
        expect(
          find.byType(SelectableMath),
          selectable ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining(r'$\frac{1}{$', findRichText: true),
          findsOneWidget,
        );
      });
    }
  });
}
