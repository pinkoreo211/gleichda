import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/verification/domain/picked_document.dart';
import 'package:app/features/verification/domain/provider_document.dart';

import '../../helpers/pump_app.dart';

const _otherProviderId = 'provider-2';

/// The card a document type lives in, so a tap lands on the right one when
/// four cards offer the same button.
Finder _cardFor(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(Card));

Finder _inCard(String title, Finder finder) =>
    find.descendant(of: _cardFor(title), matching: finder);

/// Signs in as a provider and opens the verification screen.
Future<({FakeProviderRepository provider, FakeVerificationRepository docs})>
_openVerification(
  WidgetTester tester, {
  FakeDocumentStore? store,
  ProviderVerificationStatus verification =
      ProviderVerificationStatus.unverified,
  List<DocumentRequirement>? requirements,
  FakeDocumentPicker? picker,
}) async {
  final provider = FakeProviderRepository(
    hasProfile: true,
    status: ProviderOnboardingStatus.completed,
    verification: verification,
    fields: const {'display_name': 'Max Montagen'},
  );
  final docs = FakeVerificationRepository(
    store: store,
    provider: provider,
    requirements: requirements,
  );

  await pumpSignedInApp(
    tester,
    role: AppRole.provider,
    provider: provider,
    verification: docs,
    picker: picker,
  );

  await scrollTo(tester, find.byType(VerificationCard));
  await tester.tap(find.byType(VerificationCard));
  await tester.pumpAndSettle();

  return (provider: provider, docs: docs);
}

/// Picks a file for [title] through the bottom sheet, the way a provider
/// does it.
Future<void> _upload(
  WidgetTester tester,
  String title, {
  String button = 'Nachweis hochladen',
  String source = 'Foto aufnehmen',
}) async {
  await scrollTo(tester, _inCard(title, find.text(button)));
  await tester.tap(_inCard(title, find.text(button)));
  await tester.pumpAndSettle();

  await tester.tap(find.text(source));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a provider is told what to hand in, and what is optional', (
    tester,
  ) async {
    await _openVerification(tester);

    expect(find.text('Verifiziere dein Profil'), findsOneWidget);
    expect(find.text('Identitätsnachweis'), findsOneWidget);
    expect(find.text('Gewerbeanmeldung'), findsOneWidget);
    // The required ones come first, so these two are above the fold.
    expect(
      _inCard('Identitätsnachweis', find.text('Erforderlich')),
      findsOneWidget,
    );
    expect(find.text('Noch nicht hochgeladen'), findsWidgets);

    await scrollTo(tester, find.text('Versicherung'));
    expect(_inCard('Versicherung', find.text('Optional')), findsOneWidget);
  });

  testWidgets('what a service asks for comes from the backend, not the app', (
    tester,
  ) async {
    // The same screen, told that this provider's work needs a
    // qualification. Nothing in the app decides that.
    await _openVerification(
      tester,
      requirements: const [
        DocumentRequirement(
          type: ProviderDocumentType.qualification,
          isRequired: true,
        ),
        DocumentRequirement(
          type: ProviderDocumentType.insurance,
          isRequired: false,
        ),
      ],
    );

    expect(_inCard('Qualifikation', find.text('Erforderlich')), findsOneWidget);
    expect(find.text('Identitätsnachweis'), findsNothing);
  });

  testWidgets('a handed-in document is shown as waiting, with its name', (
    tester,
  ) async {
    final opened = await _openVerification(tester);
    await _upload(tester, 'Identitätsnachweis');

    expect(find.text('Dokument wurde hochgeladen'), findsOneWidget);
    expect(
      _inCard('Identitätsnachweis', find.text('Prüfung ausstehend')),
      findsOneWidget,
    );
    expect(find.text('ausweis.jpg'), findsOneWidget);
    expect(find.text('Hochgeladen am 26.9.2026'), findsOneWidget);

    final stored = opened.docs.store.documentOf(
      testProviderId,
      ProviderDocumentType.identity,
    );
    expect(stored?.status, ProviderDocumentStatus.uploaded);
  });

  testWidgets('a photo is shown by its date, not by a made-up file name', (
    tester,
  ) async {
    // What the camera and the gallery hand back: scaling the photo down
    // renames it, so there is no name worth repeating to anybody.
    final opened = await _openVerification(
      tester,
      picker: FakeDocumentPicker(
        next: PickedDocument(
          fileName: 'scaled_53.png',
          bytes: Uint8List.fromList(const [1, 2, 3]),
        ),
      ),
    );
    await _upload(tester, 'Identitätsnachweis');

    expect(find.text('scaled_53.png'), findsNothing);
    expect(
      _inCard('Identitätsnachweis', find.text('Prüfung ausstehend')),
      findsOneWidget,
    );
    expect(find.text('Hochgeladen am 26.9.2026'), findsOneWidget);
    // The file itself went up all the same.
    expect(
      opened.docs.store.documentOf(
        testProviderId,
        ProviderDocumentType.identity,
      ),
      isNotNull,
    );
  });

  testWidgets('handing something in starts a check and nothing more', (
    tester,
  ) async {
    final opened = await _openVerification(tester);
    expect(
      opened.provider.profile?.verificationStatus,
      ProviderVerificationStatus.unverified,
    );

    await _upload(tester, 'Identitätsnachweis');

    // Pending, never verified: the app cannot award that to anyone.
    expect(
      opened.provider.profile?.verificationStatus,
      ProviderVerificationStatus.pending,
    );

    // And the screen says so, once it is scrolled back to the top.
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('In Prüfung'), findsWidgets);
    expect(find.text('Verifiziert'), findsNothing);
  });

  testWidgets('backing out of the picker changes nothing', (tester) async {
    final opened = await _openVerification(
      tester,
      picker: FakeDocumentPicker()..next = null,
    );
    await _upload(tester, 'Identitätsnachweis');

    expect(find.text('Dokument wurde hochgeladen'), findsNothing);
    expect(opened.docs.store.documentsOf(testProviderId), isEmpty);
    expect(
      opened.provider.profile?.verificationStatus,
      ProviderVerificationStatus.unverified,
    );
  });

  testWidgets('one provider never reaches another provider\'s documents', (
    tester,
  ) async {
    // Both accounts share a store, the way they share a database.
    final store = FakeDocumentStore();
    store.submit(
      providerId: _otherProviderId,
      type: ProviderDocumentType.identity,
      fileName: 'fremder-ausweis.pdf',
    );

    final opened = await _openVerification(tester, store: store);

    expect(find.text('fremder-ausweis.pdf'), findsNothing);
    expect(await opened.docs.myDocuments(), isEmpty);
    expect(find.text('Noch nicht hochgeladen'), findsWidgets);

    // And a request naming the other profile gets nowhere.
    expect(
      () => opened.docs.submit(
        providerId: _otherProviderId,
        type: ProviderDocumentType.identity,
        file: PickedDocument(
          fileName: 'x.jpg',
          bytes: Uint8List.fromList(const [1]),
        ),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(
      store
          .documentOf(_otherProviderId, ProviderDocumentType.identity)
          ?.fileName,
      'fremder-ausweis.pdf',
    );
  });

  testWidgets('a rejected document says why and asks for a new one', (
    tester,
  ) async {
    final store = FakeDocumentStore();
    store.submit(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      fileName: 'ausweis.jpg',
    );
    store.teamDecides(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      status: ProviderDocumentStatus.rejected,
      reason: 'Das Foto ist unscharf.',
    );

    await _openVerification(
      tester,
      store: store,
      verification: ProviderVerificationStatus.rejected,
    );

    expect(find.text('Nachweis abgelehnt'), findsOneWidget);
    expect(
      find.text('Ablehnungsgrund: Das Foto ist unscharf.'),
      findsOneWidget,
    );
    expect(find.text('Neuen Nachweis hochladen'), findsOneWidget);
  });

  testWidgets('a rejected document can be replaced, an accepted one cannot', (
    tester,
  ) async {
    final store = FakeDocumentStore();
    store.submit(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      fileName: 'alt.jpg',
    );
    store.teamDecides(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      status: ProviderDocumentStatus.rejected,
      reason: 'Unleserlich.',
    );

    final opened = await _openVerification(tester, store: store);
    await _upload(
      tester,
      'Identitätsnachweis',
      button: 'Neuen Nachweis hochladen',
    );

    final replaced = opened.docs.store.documentOf(
      testProviderId,
      ProviderDocumentType.identity,
    );
    expect(replaced?.fileName, 'ausweis.jpg');
    expect(replaced?.status, ProviderDocumentStatus.uploaded);
    // The old rejection is gone with the document it was about.
    expect(replaced?.rejectionReason, isNull);

    // Once the team accepts it, it is no longer the provider's to swap.
    store.teamDecides(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      status: ProviderDocumentStatus.accepted,
    );
    expect(
      () => opened.docs.submit(
        providerId: testProviderId,
        type: ProviderDocumentType.identity,
        file: PickedDocument(
          fileName: 'neu.jpg',
          bytes: Uint8List.fromList(const [1]),
        ),
      ),
      throwsA(AppFailure.documentLocked),
    );
  });

  testWidgets('a document being checked offers no replace button', (
    tester,
  ) async {
    final store = FakeDocumentStore();
    store.submit(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      fileName: 'ausweis.jpg',
    );
    store.teamDecides(
      providerId: testProviderId,
      type: ProviderDocumentType.identity,
      status: ProviderDocumentStatus.inReview,
    );

    await _openVerification(tester, store: store);

    final button = tester.widget<OutlinedButton>(
      _inCard(
        'Identitätsnachweis',
        find.widgetWithText(OutlinedButton, 'Nachweis ersetzen'),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a file that is too big never leaves the phone', (tester) async {
    final opened = await _openVerification(
      tester,
      picker: FakeDocumentPicker(
        next: PickedDocument(
          fileName: 'riesig.jpg',
          bytes: Uint8List(11 * 1024 * 1024),
        ),
      ),
    );
    await _upload(tester, 'Identitätsnachweis');

    expect(
      find.text('Die Datei ist zu groß. Bitte lade höchstens 10 MB hoch.'),
      findsOneWidget,
    );
    expect(opened.docs.store.documentsOf(testProviderId), isEmpty);
  });

  testWidgets('a format the backend does not take is refused here', (
    tester,
  ) async {
    final opened = await _openVerification(
      tester,
      picker: FakeDocumentPicker(
        next: PickedDocument(
          fileName: 'notizen.txt',
          bytes: Uint8List.fromList(const [1, 2, 3]),
        ),
      ),
    );
    await _upload(tester, 'Identitätsnachweis');

    expect(
      find.textContaining('Dieses Dateiformat geht nicht'),
      findsOneWidget,
    );
    expect(opened.docs.store.documentsOf(testProviderId), isEmpty);
  });

  testWidgets('the provider cannot verify themselves', (tester) async {
    final opened = await _openVerification(tester);

    // Every document in, and still nobody is verified: the one thing that
    // changes that is a person in the team.
    await _upload(tester, 'Identitätsnachweis');
    await _upload(tester, 'Gewerbeanmeldung');

    expect(
      opened.provider.profile?.verificationStatus,
      isNot(ProviderVerificationStatus.verified),
    );
    expect(find.text('Verifiziert'), findsNothing);

    await scrollTo(
      tester,
      find.textContaining('Alle erforderlichen Nachweise sind da'),
    );
    expect(
      find.textContaining('Alle erforderlichen Nachweise sind da'),
      findsOneWidget,
    );
  });

  testWidgets('the profile tab reaches verification too', (tester) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.widgetWithText(ListTile, 'Verifizierung'));
    await tester.tap(find.widgetWithText(ListTile, 'Verifizierung'));
    await tester.pumpAndSettle();

    expect(find.text('Verifiziere dein Profil'), findsOneWidget);
    // Opened inside the profile tab, so back lands there and not in jobs.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Angemeldet als'), findsOneWidget);
  });

  testWidgets('a customer is never asked to verify anything', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verifizierung'), findsNothing);
  });

  testWidgets('the verified badge shows once the team said so', (tester) async {
    await _openVerification(
      tester,
      verification: ProviderVerificationStatus.verified,
    );

    expect(find.text('Verifiziert'), findsWidgets);
  });

  testWidgets('a customer sees the badge only on a verified provider', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    await requests.create(
      ServiceRequestDraft(
        description: 'Kasten aufbauen',
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: testProviderId,
            displayName: 'Max Montagen',
            verificationStatus: ProviderVerificationStatus.pending,
          ),
          ProviderMatch(
            providerId: _otherProviderId,
            displayName: 'Clara Clean',
            verificationStatus: ProviderVerificationStatus.verified,
          ),
        ],
        requests: requests,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Buchungen'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();

    // "In Prüfung" is not a half-badge: it shows nothing at all.
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Clara Clean'), findsOneWidget);
    expect(find.text('Verifiziert'), findsOneWidget);
    expect(find.text('In Prüfung'), findsNothing);
  });
}
