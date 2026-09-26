import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _wardrobe = 'Mein Kleiderschrank muss aufgebaut werden';
const _cleaning = 'Ich brauche jemanden zum Reinigen';

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Home → type → "Weiter", which is where the booking flow starts.
Future<void> _start(WidgetTester tester, {String text = _cleaning}) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter'));
  await tester.pumpAndSettle();
}

/// Suggestion → service → town → provider list.
Future<void> _toProviders(
  WidgetTester tester, {
  String service = 'Wohnungsreinigung',
  String city = 'Wien',
}) async {
  await tester.tap(find.text(service));
  await tester.pumpAndSettle();

  await tester.enterText(find.widgetWithText(TextField, 'Stadt'), city);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Dienstleister suchen'));
  await tester.pumpAndSettle();
}

/// …provider → price → the scheduling screen.
Future<void> _toSchedule(
  WidgetTester tester, {
  String price = 'Bis 50 m²',
}) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Profil ansehen'));
  await tester.pumpAndSettle();
  await scrollTo(tester, find.widgetWithText(FilledButton, 'Auswählen').first);
  await tester.tap(
    find.descendant(
      of: find.ancestor(of: find.text(price), matching: find.byType(Card)),
      matching: find.widgetWithText(FilledButton, 'Auswählen'),
    ),
  );
  await tester.pumpAndSettle();
}

/// Picks tomorrow at 10:00 through the two pickers and lands on the summary.
Future<void> _toSummary(WidgetTester tester) async {
  await tester.tap(find.text('Noch nicht gewählt').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Noch nicht gewählt'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await scrollTo(
    tester,
    find.widgetWithText(FilledButton, 'Weiter zur Übersicht'),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Weiter zur Übersicht'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('what the customer wrote is matched against the catalog', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester, text: _wardrobe);

    expect(find.text('Passt das?'), findsOneWidget);
    // Their own sentence, quoted back, so it is clear what was read.
    expect(find.textContaining('Kleiderschrank'), findsWidgets);
    expect(find.text('Möbelmontage'), findsOneWidget);
  });

  testWidgets('a text nothing matches asks instead of guessing', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester, text: 'Irgendwas völlig Unbekanntes');

    expect(find.text('Welchen Service suchst du?'), findsOneWidget);
    expect(
      find.textContaining('konnten deinen Text keiner Leistung zuordnen'),
      findsOneWidget,
    );
    // No service card at all — better than the closest wrong one.
    expect(find.text('Wohnungsreinigung'), findsNothing);
    expect(find.text('Möbelmontage'), findsNothing);
  });

  testWidgets('the town is required before anyone is looked up', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester);
    await tester.tap(find.text('Wohnungsreinigung'));
    await tester.pumpAndSettle();

    expect(find.text('Wo soll der Auftrag stattfinden?'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Dienstleister suchen'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the search asks the backend for the chosen service and town', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, booking: booking);
    await _start(tester);
    await _toProviders(tester, city: 'Graz');

    expect(booking.lastServiceId, testFlatCleaning.id);
    expect(booking.lastCity, 'Graz');
    expect(find.text('Clara Clean'), findsOneWidget);
    expect(find.text('Verifiziert'), findsOneWidget);
  });

  testWidgets('nobody bookable is said plainly, not filled with others', (
    tester,
  ) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      booking: FakeBookingRepository(providers: const []),
    );
    await _start(tester);
    await _toProviders(tester);

    expect(find.text('Noch niemand verfügbar'), findsOneWidget);
    expect(
      find.textContaining('kein verifizierter Dienstleister'),
      findsOneWidget,
    );
    // And the older route out is offered rather than a watered-down list.
    expect(find.text('Stattdessen Anfrage schreiben'), findsOneWidget);
  });

  testWidgets('a provider shows the prices they set themselves', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester);
    await _toProviders(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Profil ansehen'));
    await tester.pumpAndSettle();

    expect(find.text('Clara Clean'), findsOneWidget);
    expect(find.text('4,8'), findsOneWidget);
    expect(find.text('12 Bewertungen'), findsOneWidget);
    expect(find.text('Bis 50 m²'), findsOneWidget);
    expect(find.textContaining('59,00'), findsOneWidget);
    expect(find.textContaining('89,00'), findsOneWidget);
    expect(find.textContaining('pro Auftrag'), findsOneWidget);
    expect(find.textContaining('ca. 120 Min.'), findsOneWidget);
  });

  testWidgets('an unrated provider shows no invented stars', (tester) async {
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      booking: FakeBookingRepository(
        providers: const [
          ProviderMatch(
            providerId: testBookingProviderId,
            displayName: 'Neu Dabei',
            verificationStatus: ProviderVerificationStatus.verified,
            lowestPriceCents: 4900,
          ),
        ],
        offers: const {
          testBookingProviderId: ProviderOffer(
            providerId: testBookingProviderId,
            displayName: 'Neu Dabei',
            verificationStatus: ProviderVerificationStatus.verified,
            prices: [
              ProviderPrice(id: 'p1', name: 'Standard', priceCents: 4900),
            ],
          ),
        },
      ),
    );
    await _start(tester);
    await _toProviders(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Profil ansehen'));
    await tester.pumpAndSettle();

    expect(find.text('Neu Dabei'), findsOneWidget);
    expect(find.text('5,0'), findsNothing);
    expect(find.text('0,0'), findsNothing);
    expect(find.textContaining('Bewertung'), findsNothing);
  });

  testWidgets('the time is asked for as a wish, not promised as a slot', (
    tester,
  ) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester);
    await _toProviders(tester);
    await _toSchedule(tester);

    expect(find.text('Wann passt es dir?'), findsOneWidget);
    expect(find.textContaining('Das ist ein Wunschtermin'), findsOneWidget);
    // Nothing to continue with until both halves are chosen.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Weiter zur Übersicht'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the summary shows what was actually chosen', (tester) async {
    await pumpSignedInApp(tester, role: AppRole.customer);
    await _start(tester);
    await _toProviders(tester);
    await _toSchedule(tester);
    await _toSummary(tester);

    expect(find.text('Dein Auftrag'), findsOneWidget);
    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    expect(find.text('Clara Clean'), findsOneWidget);
    expect(find.text('Bis 50 m²'), findsOneWidget);
    expect(find.textContaining('Wien'), findsOneWidget);
    expect(find.textContaining('59,00'), findsOneWidget);
    // Says plainly that sending costs nothing: there are no payments yet.
    expect(find.textContaining('Bezahlt wird noch nichts'), findsOneWidget);
  });

  testWidgets('sending writes the booking with the price from the option', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, booking: booking);
    await _start(tester);
    await _toProviders(tester);
    await _toSchedule(tester);
    await _toSummary(tester);

    await scrollTo(tester, find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.pumpAndSettle();

    final written = booking.bookings.single;
    expect(written['service_id'], testFlatCleaning.id);
    expect(written['provider_id'], testBookingProviderId);
    expect(written['price_id'], 'price-small');
    // The amount came from the stored option, not from the screen.
    expect(written['price_cents'], 5900);
    expect(written['city'], 'Wien');
    expect(written['description'], _cleaning);
    expect(written['wanted_at'], isA<DateTime>());

    expect(find.text('Anfrage gesendet'), findsOneWidget);
    expect(find.textContaining('Clara Clean'), findsOneWidget);
    // Sent, not accepted. The wording must not promise the second.
    expect(find.textContaining('Sobald sie angenommen wird'), findsOneWidget);
  });

  testWidgets('a booking the backend refuses is not reported as sent', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await pumpSignedInApp(tester, role: AppRole.customer, booking: booking);
    await _start(tester);
    await _toProviders(tester);
    await _toSchedule(tester);
    await _toSummary(tester);

    booking.failure = AppFailure.unknown;
    await scrollTo(tester, find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.tap(find.widgetWithText(FilledButton, 'Anfrage senden'));
    await tester.pumpAndSettle();

    expect(booking.bookings, isEmpty);
    expect(find.text('Anfrage gesendet'), findsNothing);
    // Still on the summary — its title is in the bar, whatever the list is
    // scrolled to — with the button usable again.
    expect(find.text('Übersicht'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Anfrage senden'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a price belonging to somebody else cannot be booked', (
    tester,
  ) async {
    final booking = FakeBookingRepository();

    // What a tampered app would try: the right provider, a price id that is
    // not one of theirs.
    expect(
      () => booking.createBooking(
        description: _cleaning,
        serviceId: testFlatCleaning.id,
        providerId: testBookingProviderId,
        priceId: 'price-of-someone-else',
        wantedAt: DateTime(2026, 10, 3, 14),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(booking.bookings, isEmpty);
  });

  testWidgets('an unverified provider cannot be booked', (tester) async {
    final booking = FakeBookingRepository(
      offers: const {
        testBookingProviderId: ProviderOffer(
          providerId: testBookingProviderId,
          displayName: 'Ungeprüft',
          // The team never checked them.
          verificationStatus: ProviderVerificationStatus.pending,
          prices: [ProviderPrice(id: 'p1', name: 'Standard', priceCents: 4900)],
        ),
      },
    );

    expect(
      () => booking.createBooking(
        description: _cleaning,
        serviceId: testFlatCleaning.id,
        providerId: testBookingProviderId,
        priceId: 'p1',
        wantedAt: DateTime(2026, 10, 3, 14),
      ),
      throwsA(isA<AppFailure>()),
    );
    expect(booking.bookings, isEmpty);
  });

  testWidgets('a booked job shows its price and the wanted time', (
    tester,
  ) async {
    final requests = InMemoryServiceRequestRepository();
    final stored = await requests.create(
      ServiceRequestDraft(
        description: _cleaning,
        service: testFlatCleaning,
        city: 'Wien',
      ),
    );
    final contacts = requests.contacts;
    // A contact that came from the booking flow: it carries a price and
    // the hour the customer asked for.
    contacts.send(
      requestId: stored.id,
      providerId: testProviderId,
      priceCents: 5900,
      wantedAt: DateTime(2026, 10, 3, 14),
    );
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

    expect(find.textContaining('Festpreis:'), findsOneWidget);
    expect(find.text('Wunschtermin: 3.10.2026, 14:00'), findsOneWidget);
  });
}
