import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:starter_app/chart_plotter_screen.dart';

void main() {
  testWidgets('chart plotter loads with all data layers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChartPlotterScreen()));
    await tester.pumpAndSettle();

    expect(find.text('LAKE COMMAND IN DEPTH'), findsWidgets);
    expect(find.text('42.485'), findsOneWidget);

    // Verify overlay toolbox button exists
    expect(find.byIcon(Icons.layers), findsOneWidget);
  });
}
