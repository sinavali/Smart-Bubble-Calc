import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bubble_calc_mobile/main.dart';

void main() {
  testWidgets('SmartBubbleCalcApp smoke test and navigation tabs verification', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBubbleCalcApp());
    await tester.pumpAndSettle();

    // Verify Title & Terminal Header
    expect(find.text('SMART BUBBLE CALC // حباب سنج'), findsOneWidget);

    // Verify Navigation Bar Items
    expect(find.text('بازار و حباب'), findsOneWidget);
    expect(find.text('طلافروشی'), findsOneWidget);
    expect(find.text('تحلیلگر هوشمند'), findsOneWidget);
    expect(find.text('تنظیمات'), findsOneWidget);
  });
}
