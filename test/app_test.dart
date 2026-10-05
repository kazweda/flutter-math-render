import 'package:flutter_math_render/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches the sample content between English and Japanese', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MathRenderApp());
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Quadratic formula'), findsOneWidget);

    await tester.tap(find.text('JA'));
    await tester.pumpAndSettle();
    expect(find.text('数学'), findsOneWidget);
    expect(find.text('解の公式'), findsOneWidget);

    await tester.tap(find.text('Markdown'));
    await tester.pumpAndSettle();
    expect(find.text('二次方程式'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Quadratic equations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
