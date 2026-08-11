import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calcity_app/main.dart';

void main() {
  Future<void> _run(WidgetTester tester) async {
    // Phone-like viewport: 1080x1920 physical @ 2.75 density = 392x698 logical
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CalCityApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final log = StringBuffer();
    log.writeln('screen logical size: ${tester.view.physicalSize / tester.view.devicePixelRatio}');

    // AppBar of the home screen should sit at the TOP (y near 0)
    final appBars = find.byType(AppBar);
    log.writeln('AppBars found: ${appBars.evaluate().length}');
    if (appBars.evaluate().isNotEmpty) {
      final y = tester.getTopLeft(appBars.first).dy;
      log.writeln('first AppBar top-left y: $y');
      expect(y, lessThan(60), reason: 'AppBar must be at the top, got y=$y');
    }

    // NavigationBar should sit at the BOTTOM (y near screenHeight - barHeight)
    final nav = find.byType(NavigationBar);
    log.writeln('NavigationBar found: ${nav.evaluate().length}');
    if (nav.evaluate().isNotEmpty) {
      final y = tester.getTopLeft(nav).dy;
      final screenH = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      log.writeln('NavigationBar top-left y: $y of screen height $screenH');
      expect(y, greaterThan(screenH - 160), reason: 'NavigationBar must be near the bottom, got y=$y of $screenH');
    }

    // Home content (hero) should be present
    expect(find.text('California City'), findsWidgets,
        reason: 'hero title should render');

    debugPrint(log.toString());
  }

  testWidgets('LAYOUT DIAGNOSTIC: app fills the screen', (tester) async {
    // The app's MaterialApp.builder installs a custom ErrorWidget.builder;
    // restore the harness default before the framework's post-test check.
    final origBuilder = ErrorWidget.builder;
    try {
      await _run(tester);
    } finally {
      ErrorWidget.builder = origBuilder;
    }
  });
}
