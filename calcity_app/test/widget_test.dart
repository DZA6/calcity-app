import 'package:flutter_test/flutter_test.dart';
import 'package:calcity_app/main.dart';

void main() {
  testWidgets('CalCity app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CalCityApp());
    await tester.pump();

    // Verify the app loaded without crashing
    expect(find.byType(CalCityApp), findsOneWidget);
  });
}
