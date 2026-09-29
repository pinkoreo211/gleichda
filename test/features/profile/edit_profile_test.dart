import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/core/media/picked_media.dart';
import 'package:app/design_system/widgets/avatar.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Profile tab → "Profil bearbeiten".
Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(_navLabel('Profil'));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.widgetWithText(ListTile, 'Profil bearbeiten'));
  await tester.tap(find.widgetWithText(ListTile, 'Profil bearbeiten'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a name can be set and is stored trimmed', (tester) async {
    final profile = FakeProfileRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, profile: profile);
    await _openEditor(tester);

    expect(find.text('Dein Name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Anna Huber  ');
    await tester.pump();
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Speichern'));
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(profile.displayName, 'Anna Huber');
    expect(find.text('Profil gespeichert'), findsOneWidget);
  });

  testWidgets('a name of only spaces clears it rather than storing blanks', (
    tester,
  ) async {
    final profile = FakeProfileRepository(displayName: 'Anna');
    await pumpSignedInApp(tester, role: AppRole.customer, profile: profile);
    await _openEditor(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Speichern'));
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(profile.displayName, isNull);
  });

  testWidgets('the screen says who will see the name and the picture', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _openEditor(tester);

    // Said where the choice is made, not buried in a policy.
    expect(
      find.textContaining('Deine E-Mail-Adresse und deine Telefonnummer'),
      findsOneWidget,
    );
    expect(
      find.textContaining('auch ohne Anmeldung erreichbar'),
      findsOneWidget,
    );
  });

  testWidgets('a picture is uploaded and shown back', (tester) async {
    final profile = FakeProfileRepository(displayName: 'Anna');
    final picker = FakeMediaPicker();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      profile: profile,
      picker: picker,
    );
    await _openEditor(tester);

    await tester.tap(find.text('Foto hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto aus Galerie'));
    await tester.pumpAndSettle();

    expect(profile.uploaded, hasLength(1));
    expect(profile.profile.hasAvatar, isTrue);
    expect(find.text('Foto gespeichert'), findsOneWidget);
    // The button now offers to change it, not to add one.
    expect(find.text('Foto ändern'), findsOneWidget);
  });

  testWidgets('a picture that is too big never leaves the phone', (
    tester,
  ) async {
    final profile = FakeProfileRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      profile: profile,
      picker: FakeMediaPicker(
        next: PickedMedia(
          fileName: 'riesig.jpg',
          bytes: Uint8List(3 * 1024 * 1024),
        ),
      ),
    );
    await _openEditor(tester);

    await tester.tap(find.text('Foto hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto aus Galerie'));
    await tester.pumpAndSettle();

    expect(profile.uploaded, isEmpty);
    expect(find.textContaining('zu groß'), findsOneWidget);
  });

  testWidgets('backing out of the picker changes nothing', (tester) async {
    final profile = FakeProfileRepository();
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      profile: profile,
      picker: FakeMediaPicker()..next = null,
    );
    await _openEditor(tester);

    await tester.tap(find.text('Foto hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto aus Galerie'));
    await tester.pumpAndSettle();

    expect(profile.uploaded, isEmpty);
    expect(profile.profile.hasAvatar, isFalse);
  });

  testWidgets('a picture can be removed again', (tester) async {
    final profile = FakeProfileRepository(
      displayName: 'Anna',
      avatarUrl: 'https://example.test/avatars/1.jpg',
    );
    await pumpSignedInApp(tester, role: AppRole.customer, profile: profile);
    await _openEditor(tester);

    await tester.tap(find.text('Foto ändern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto entfernen'));
    await tester.pumpAndSettle();

    expect(profile.profile.hasAvatar, isFalse);
    // The name survives removing the picture.
    expect(profile.displayName, 'Anna');
  });

  testWidgets('a backend that refuses the save says so and keeps the text', (
    tester,
  ) async {
    final profile = FakeProfileRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, profile: profile);
    await _openEditor(tester);

    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.pump();
    profile.failure = AppFailure.unknown;
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Speichern'));
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('Profil gespeichert'), findsNothing);
    // Still on the editor, with what was typed still there to try again.
    expect(find.text('Dein Name'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
  });

  testWidgets('initials stand in for a missing picture, never a stock face', (
    tester,
  ) async {
    expect(const UserProfile(displayName: 'Anna Huber').initials, 'AH');
    expect(const UserProfile(displayName: 'anna').initials, 'A');
    expect(
      const UserProfile(displayName: '  Max  Peter  Müller ').initials,
      'MM',
    );
    // No name means no letter: a letter that stands for nothing is worse
    // than a silhouette.
    expect(const UserProfile().initials, '');
    expect(const UserProfile(displayName: '   ').initials, '');
  });

  testWidgets('a provider sees who is asking, with a face', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(
        description: 'Kasten aufbauen',
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    requests.contacts.send(requestId: stored.id, providerId: testProviderId);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(
        requests: requests,
        customerName: 'Anna Huber',
      ),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
    );

    await scrollTo(tester, find.text('Kasten aufbauen'));
    expect(find.textContaining('Anna Huber'), findsOneWidget);
    // No picture stored, so the initials carry it.
    expect(find.text('AH'), findsOneWidget);
  });

  testWidgets('a job shows the other person, both ways round', (tester) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(
        description: 'Kasten aufbauen',
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    final contacts = requests.contacts;
    contacts.send(requestId: stored.id, providerId: testProviderId);
    contacts.respond(
      contacts.contactId(stored.id, testProviderId),
      RequestContactStatus.accepted,
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      jobs: FakeJobsRepository(contacts: contacts, requests: requests),
    );
    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();

    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.byType(Avatar), findsWidgets);
  });
}
