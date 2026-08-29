import 'package:flutter_test/flutter_test.dart';

import 'package:plant_app/main.dart';

void main() {
  testWidgets('Welcome screen renders and routes into the app', (tester) async {
    await tester.pumpWidget(const PlantPalApp());
    await tester.pumpAndSettle();

    expect(find.text('Know every\nleaf you own.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Lands on Home inside the root shell.
    expect(find.text('Two plants need\nyou today.'), findsOneWidget);
  });
}
