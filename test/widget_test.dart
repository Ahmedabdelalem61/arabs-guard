import 'package:flutter_test/flutter_test.dart';

import 'package:arabs_guard/main.dart';

void main() {
  testWidgets('shows protection entry points', (WidgetTester tester) async {
    await tester.pumpWidget(const ArabsGuardApp());

    expect(find.text('Arabs Guard'), findsWidgets);
    expect(find.text('Set up protection'), findsOneWidget);
    expect(find.text('A calmer internet starts here'), findsOneWidget);
  });
}
