import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';

import '../../helpers/pump_app.dart';

Future<void> _openLogin(WidgetTester tester, FakeAuthRepository auth) async {
  await pumpApp(tester, auth: auth);
  await tester.tap(find.text("Los geht's"));
  await tester.pumpAndSettle();
}

Future<void> _requestCode(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.tap(find.widgetWithText(FilledButton, 'Code senden'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('rejects an implausible email without calling the backend', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _openLogin(tester, auth);

    await _requestCode(tester, 'anna@example');

    expect(auth.sentCodesTo, isEmpty);
    expect(
      find.text('Bitte gib eine gültige E-Mail-Adresse ein.'),
      findsOneWidget,
    );
  });

  testWidgets('shows why the email service refused the address', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..sendFailure = AppFailure.emailNotAuthorized;
    await _openLogin(tester, auth);

    await _requestCode(tester, testEmail);

    expect(
      find.text(
        'An diese E-Mail-Adresse können wir derzeit keine E-Mails senden.',
      ),
      findsOneWidget,
    );
    expect(find.text('Code eingeben'), findsNothing);
  });

  testWidgets('a wrong code shows an error and keeps the user signed out', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await _openLogin(tester, auth);
    await _requestCode(tester, testEmail);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Bestätigen'));
    await tester.pumpAndSettle();

    expect(auth.currentUserId, isNull);
    expect(find.textContaining('Der Code ist falsch'), findsOneWidget);
    expect(find.text('Code eingeben'), findsOneWidget);
  });

  testWidgets('the code field only accepts digits', (tester) async {
    await _openLogin(tester, FakeAuthRepository());
    await _requestCode(tester, testEmail);

    await tester.enterText(find.byType(TextField), '12ab34');

    expect(find.text('1234'), findsOneWidget);
  });

  testWidgets('resending a code confirms it was sent', (tester) async {
    final auth = FakeAuthRepository();
    await _openLogin(tester, auth);
    await _requestCode(tester, testEmail);

    await tester.tap(find.text('Code erneut senden'));
    await tester.pumpAndSettle();

    expect(auth.sentCodesTo, [testEmail, testEmail]);
    expect(find.text('Neuer Code ist unterwegs.'), findsOneWidget);
  });

  testWidgets('user can go back from the code step to change the email', (
    tester,
  ) async {
    await _openLogin(tester, FakeAuthRepository());
    await _requestCode(tester, testEmail);

    await tester.tap(find.text('Andere E-Mail-Adresse verwenden'));
    await tester.pumpAndSettle();

    expect(find.text('Anmelden oder registrieren'), findsOneWidget);
    expect(find.text(testEmail), findsOneWidget);
  });
}
