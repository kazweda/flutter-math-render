import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_math_render/formulas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final Formula f in <Formula>[...mathFormulas, ...chemistryFormulas]) {
    testWidgets('${f.id}: ${f.tex}', (WidgetTester tester) async {
      Object? parseError;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Math.tex(
                    f.tex,
                    onErrorFallback: (FlutterMathException e) {
                      parseError = e.message;
                      return Text(f.tex);
                    },
                  ),
                  Wrap(
                    children: <Widget>[
                      const Text('inline '),
                      Math.tex(f.tex, mathStyle: MathStyle.text),
                      const Text(' end'),
                    ],
                  ),
                  SelectableMath.tex(f.tex),
                ],
              ),
            ),
          ),
        ),
      );
      expect(parseError, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
