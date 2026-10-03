/// Excluded on CI (Linux) with `--exclude-tags golden`; run locally on macOS.
@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_render/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden images are rendered on the host (macOS) and are only comparable
/// on the same platform. Regenerate with:
///   flutter test --update-goldens test/golden_test.dart
void main() {
  final Map<String, List<Formula>> sets = <String, List<Formula>>{
    'math': mathFormulas,
    'chemistry': chemistryFormulas,
  };
  sets.forEach((String group, List<Formula> formulas) {
    for (final Formula f in formulas) {
      testWidgets('$group/${f.id}', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Material(
              color: Colors.white,
              child: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: const ValueKey<String>('formula'),
                  child: ColoredBox(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Math.tex(
                        f.tex,
                        textStyle: const TextStyle(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await expectLater(
          find.byKey(const ValueKey<String>('formula')),
          matchesGoldenFile('goldens/$group/${f.id}.png'),
        );
      });
    }
  });
}
