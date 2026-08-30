import 'package:flutter_test/flutter_test.dart';

import 'package:partyapp_admin/main.dart';

void main() {
  testWidgets('Admin app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());
    await tester.pump();
    expect(find.text('داشبورد حفلة'), findsOneWidget);
  });
}
