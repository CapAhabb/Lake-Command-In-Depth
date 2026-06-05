import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:starter_app/chart_plotter_screen.dart';

void main() {
  testWidgets('chart plotter loads with all data layers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ChartPlotterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the app name/logo is present
    expect(find.text('LAKE COMMAND'), findsOneWidget);
    expect(find.text('IN DEPTH'), findsOneWidget);
    
    // Verify GPS coordinates are displayed
    expect(find.textContaining('42.4851° N'), findsOneWidget);
    
    // Verify overlay toolbox button exists
    expect(find.byIcon(Icons.layers), findsOneWidget);
  });
}
