import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:starter_app/chart_plotter_screen.dart';

void main() {
  testWidgets('chart plotter loads with all data layers', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ChartPlotterScreen()));
    await tester.pumpAndSettle();

    // Verify the gptplotter-style app labels are present
    expect(find.text('LakeGuard Pro'), findsOneWidget);
    expect(find.text('AquaPlotter'), findsOneWidget);

    // Verify GPS status is displayed
    expect(find.text('GPS'), findsOneWidget);

    // Verify interactive layer controls are present
    expect(find.text('ON'), findsWidgets);
    expect(find.text('OFF'), findsWidgets);
    expect(find.text('MENU'), findsOneWidget);
  });
}
