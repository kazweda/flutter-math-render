import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_render/markdown_math.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tall inline formula should make its line taller, so that it stays inside
/// its own paragraph and doesn't overlap the blocks above and below (#36).
void main() {
  // Tall formulas found in kazweda/math-memo-app#12.
  const Map<String, String> tall = <String, String>{
    'quadratic formula': r'x=\frac{-b \pm \sqrt{b^{2} - 4ac}}{2a}',
    'quadratic formula, dfrac': r'x=\dfrac{-b \pm \sqrt{b^{2} - 4ac}}{2a}',
    'limit': r'\displaystyle\lim_{x \to 0} \frac{\sin x}{x} = 1',
    'sum': r'\displaystyle\sum_{k=1}^{n} k^{2} = \frac{n(n+1)(2n+1)}{6}',
    'cases': r'\begin{cases} x + y = 3 \\ x - y = 1 \end{cases}',
  };

  // The paragraph (RichText) or, when selectable, the EditableText that holds
  // the formula.
  Rect blockOf(WidgetTester tester) => tester.getRect(
    find
        .ancestor(
          of: find.byType(Math),
          matching: find.byWidgetPredicate(
            (Widget w) => w is RichText || w is EditableText,
          ),
        )
        .first,
  );

  for (final MapEntry<String, String> f in tall.entries) {
    for (final String context in <String>['paragraph', 'heading', 'list']) {
      for (final bool selectable in <bool>[false, true]) {
        testWidgets('${f.key} fits its $context (selectable: $selectable)', (
          WidgetTester tester,
        ) async {
          final String line = switch (context) {
            'paragraph' => 'before \$${f.value}\$ after',
            'heading' => '## before \$${f.value}\$ after',
            _ => '- before \$${f.value}\$ after',
          };
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: MarkdownMathBody(data: line, selectable: selectable),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);

          final Rect math = tester.getRect(find.byType(Math));
          final Rect block = blockOf(tester);
          expect(
            block.top,
            lessThanOrEqualTo(math.top + 0.5),
            reason: 'formula $math sticks out above its block $block',
          );
          expect(
            block.bottom,
            greaterThanOrEqualTo(math.bottom - 0.5),
            reason: 'formula $math sticks out below its block $block',
          );
        });
      }
    }
  }
}
