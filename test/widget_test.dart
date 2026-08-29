import 'package:flutter_test/flutter_test.dart';

import 'package:plant_app/main.dart';
import 'package:plant_app/state/auth_scope.dart';

void main() {
  testWidgets('App boots to the welcome screen when signed out', (tester) async {
    final auth = AuthController.instance;
    auth.status = AuthStatus.signedOut;

    await tester.pumpWidget(PlantPalApp(auth: auth));
    await tester.pump();

    expect(find.text('Know every\nleaf you own.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
