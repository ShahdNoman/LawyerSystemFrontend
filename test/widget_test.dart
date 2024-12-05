import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firstproject/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // بناء التطبيق وتفعيل الإطار
    await tester.pumpWidget(MyApp());  // لا حاجة لـ const هنا

    // تحقق من أن العداد يبدأ من 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // النقر على الأيقونة '+' وتفعيل الإطار
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // تحقق من أن العداد قد تم زيادته
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
