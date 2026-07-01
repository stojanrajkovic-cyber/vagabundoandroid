// Osnovni smoke test.
//
// NAPOMENA: VagabundoApp zahtijeva Firebase.initializeApp() prije
// runApp() (vidi main.dart), a Firebase nije dostupan u test okruženju
// bez dodatnog mockovanja (firebase_core_platform_interface test double-a).
// Zato ovdje NE testiramo VagabundoApp direktno — to ostavljamo za Fazu 9
// (Testing & Release), kad dodamo Firebase mock setup.
//
// Za sada testiramo izolovan, Firebase-nezavisan widget (PrimaryButton)
// da test suite bude zelen i da hvata regresije na reusable komponentama.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vagabundo/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton prikazuje label i reaguje na tap',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Prijavi se',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Prijavi se'), findsOneWidget);
    expect(tapped, isFalse);

    await tester.tap(find.text('Prijavi se'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton prikazuje loading indikator i blokira tap',
      (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Prijavi se',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Prijavi se'), findsNothing);

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(tapped, isFalse);
  });
}
