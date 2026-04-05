import 'package:flutter_test/flutter_test.dart';
import 'package:torah_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TorahDailyApp());
    // Just verify it launches without error
    expect(find.text('חברותא'), findsOneWidget);
  });
}
