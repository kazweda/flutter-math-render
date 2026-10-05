import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      expect(parseMath(r'the answer is $x^2$'), <String>['i:x^2']);
      expect(parseMath(r'解は $x^2$ です'), <String>['i:x^2']);
    });
    test('multiple in one line', () {
      expect(parseMath(r'$a$ and $b$'), <String>['i:a', 'i:b']);
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
    // The same cases in English and Japanese.
    const Map<String, String> samples = <String, String>{
      'en': '''
## Heading

A paragraph with \$x^2\$ and a fraction \$\\frac{1}{2}\$ inline.

\$\$
\\int_0^1 x\\,dx
\$\$

- In a list \$\\sqrt{2}\$
- Currency \$5 and \$10

An invalid formula \$\\frac{1}{\$
''',
      'ja': '''
## 見出し

文中の \$x^2\$ と分数 \$\\frac{1}{2}\$ を含む段落。

\$\$
\\int_0^1 x\\,dx
\$\$

- リスト内 \$\\sqrt{2}\$
- 通貨 \$5 and \$10

不正な式 \$\\frac{1}{\$
''',
    };

    for (final MapEntry<String, String> sample in samples.entries) {
      for (final bool selectable in <bool>[false, true]) {
        testWidgets('renders without exceptions '
            '(${sample.key}, selectable: $selectable)', (
          WidgetTester tester,
        ) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MarkdownMathBody(
                    data: sample.value,
                    selectable: selectable,
                  ),
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
    }

    testWidgets('tapping a selectable block formula does not show the '
        'keyboard on Android', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownMathBody(data: r'$$x^2$$', selectable: true),
          ),
        ),
      );
      await tester.tap(find.byType(SelectableMath));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.testTextInput.hasAnyClients, isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets(
      'toolbar actions of a selectable block formula',
      (WidgetTester tester) async {
        String? clipboard;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownMathBody(
                data: r'$$\frac{a}{b} + c$$',
                selectable: true,
              ),
            ),
          ),
        );

        final bool isCupertino = defaultTargetPlatform == TargetPlatform.iOS;
        final String selectAll = isCupertino ? 'Select All' : 'Select all';

        Future<void> longPressFormula() async {
          await tester.longPress(find.byType(SelectableMath));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        // Copy puts the selected part on the clipboard as TeX.
        await longPressFormula();
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(clipboard, isNotEmpty);

        // Select all is offered for a partial selection, and Copy then gives
        // the whole formula.
        await longPressFormula();
        await tester.tap(find.text(selectAll));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Everything is selected now, so Select all is no longer offered.
        expect(find.text(selectAll), findsNothing);
        await tester.tap(find.text('Copy'));
        await tester.pumpAndSettle();
        expect(clipboard, r'\frac{a}{b}+c');
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.android,
        TargetPlatform.iOS,
      }),
    );
    group('copying selectable text with inline math', () {
      late String? clipboard;

      Future<void> pumpParagraph(WidgetTester tester, String data) async {
        clipboard = null;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            if (call.method == 'Clipboard.setData') {
              clipboard =
                  (call.arguments as Map<Object?, Object?>)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownMathBody(data: data, selectable: true),
            ),
          ),
        );
      }

      Future<void> doubleTapAt(WidgetTester tester, Offset position) async {
        await tester.tapAt(position);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(position);
        await tester.pumpAndSettle();
      }

      testWidgets(
        'copies a double-tapped formula as TeX',
        (WidgetTester tester) async {
          await pumpParagraph(tester, r'A **double root** when $D = 0$ holds');
          await doubleTapAt(tester, tester.getCenter(find.byType(Math)));
          await tester.tap(find.text('Copy'));
          await tester.pumpAndSettle();
          // Not U+FFFC, which SelectableText uses for the formula.
          expect(clipboard, r'$D = 0$');
        },
        variant: const TargetPlatformVariant(<TargetPlatform>{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );

      testWidgets(
        'copies a whole paragraph with its formulas as TeX',
        (WidgetTester tester) async {
          await pumpParagraph(
            tester,
            r'If $D > 0$, two roots; if $D = 0$, one',
          );
          final EditableTextState state = tester.state(
            find.byType(EditableText),
          );
          state.selectAll(SelectionChangedCause.toolbar);
          state.showToolbar();
          await tester.pumpAndSettle();
          await tester.tap(find.text('Copy'));
          await tester.pumpAndSettle();
          expect(clipboard, r'If $D > 0$, two roots; if $D = 0$, one');
        },
        variant: const TargetPlatformVariant(<TargetPlatform>{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );

      Future<void> pressCopyShortcut(WidgetTester tester) async {
        final LogicalKeyboardKey modifier = switch (defaultTargetPlatform) {
          TargetPlatform.iOS ||
          TargetPlatform.macOS => LogicalKeyboardKey.metaLeft,
          _ => LogicalKeyboardKey.controlLeft,
        };
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(modifier);
        await tester.pumpAndSettle();
      }

      testWidgets('copies with the keyboard shortcut as TeX', (
        WidgetTester tester,
      ) async {
        await pumpParagraph(tester, r'If $D > 0$, two roots; if $D = 0$, one');
        // Focus the text, then select all of it.
        await tester.tapAt(tester.getTopLeft(find.byType(EditableText)));
        await tester.pumpAndSettle();
        final EditableTextState state = tester.state(find.byType(EditableText));
        state.selectAll(SelectionChangedCause.keyboard);
        await tester.pumpAndSettle();
        await pressCopyShortcut(tester);
        expect(clipboard, r'If $D > 0$, two roots; if $D = 0$, one');
        // The selection stays, as with the default keyboard copy.
        expect(state.textEditingValue.selection.isCollapsed, isFalse);
      }, variant: TargetPlatformVariant.all());

      testWidgets('leaves the keyboard shortcut alone without a selection', (
        WidgetTester tester,
      ) async {
        await pumpParagraph(tester, r'If $D > 0$, two roots');
        await tester.tapAt(tester.getTopLeft(find.byType(EditableText)));
        await tester.pumpAndSettle();
        await pressCopyShortcut(tester);
        expect(clipboard, isNull);
      }, variant: TargetPlatformVariant.all());
    });

    testWidgets('Select All after a double tap on a phone with a notch', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1260, 2736);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(top: 204, bottom: 102);
      addTearDown(tester.view.reset);
      // A toolbar button painted outside the area that receives taps
      // fails the tap instead of silently hitting the widget underneath.
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('lab')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: const <Widget>[
                SizedBox(height: 200),
                MarkdownMathBody(
                  data: 'before\n\n\$\$\\frac{a}{b} + c\$\$\n\nafter',
                  selectable: true,
                ),
              ],
            ),
          ),
        ),
      );

      final Offset formula = tester.getCenter(find.byType(SelectableMath));
      await tester.tapAt(formula);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(formula);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();
      // The whole formula is selected, so only Copy is left.
      expect(find.text('Select All'), findsNothing);
      expect(find.text('Copy'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });
}
