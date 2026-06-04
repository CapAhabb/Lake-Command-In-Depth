import 'package:flutter_test/flutter_test.dart';

import 'package:starter_app/main.dart';

void main() {
  testWidgets('splash enters menu-driven blueprint app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Enter Menus'), findsOneWidget);
    expect(
      find.textContaining('Everything after this is menus and submenus.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Enter Menus'));
    await tester.pumpAndSettle();

    expect(find.text('Lake Michigan Blueprint'), findsAtLeastNWidgets(1));
    expect(find.text('Lake Overview'), findsAtLeastNWidgets(1));
    expect(find.text('General Fish Locations'), findsOneWidget);

    await tester.tap(find.text('Run Blueprint'));
    await tester.pumpAndSettle();

    expect(find.text('Trip Controls'), findsOneWidget);
    expect(find.text('Recommended Menu Route'), findsOneWidget);
  });
}
