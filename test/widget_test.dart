import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('App shows splash then opens dashboard', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());

    expect(find.text('MePlan'), findsOneWidget);
    expect(find.text('Your calm productivity space'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Plan with clarity'), findsOneWidget);
    expect(find.text('Create first task'), findsOneWidget);
  });
}
