import 'package:flutter_test/flutter_test.dart';
import 'package:tiger_vs_goat/main.dart';

void main() {
  testWidgets('Role selection screen shows buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TigerVsGoatsApp());

    // Verify that role selection text and buttons are present.
    expect(find.text('Choose Your Side'), findsOneWidget);
    expect(find.text('Play as Tiger'), findsOneWidget);
    expect(find.text('Play as Goats'), findsOneWidget);
  });
}
