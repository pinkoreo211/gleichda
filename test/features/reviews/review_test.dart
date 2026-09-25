import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

/// One job, left at [status]. Confirmed by default, which is the only
/// state in which a review exists at all.
Future<InMemoryServiceRequestRepository> _job({
  RequestContactStatus status = RequestContactStatus.customerConfirmed,
}) async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: 'Kasten aufbauen',
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  final contactId = requests.contacts.contactId(stored.id, testProviderId);
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  requests.contacts.respond(contactId, RequestContactStatus.accepted);
  requests.contacts.setStatus(contactId, status);
  return requests;
}

String _contactOf(InMemoryServiceRequestRepository requests) =>
    requests.contacts.contactId(requests.requests.single.id, testProviderId);

Finder _navLabel(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Signs in and lands where the job card is.
Future<FakeReviewsRepository> _pump(
  WidgetTester tester,
  InMemoryServiceRequestRepository requests, {
  bool asProvider = false,
}) async {
  final reviews = FakeReviewsRepository(
    contacts: requests.contacts,
    isProvider: asProvider,
  );
  await pumpSignedInApp(
    tester,
    role: asProvider ? AppRole.provider : AppRole.customer,
    requests: requests,
    incoming: FakeIncomingRequestsRepository(requests: requests),
    jobs: FakeJobsRepository(
      contacts: requests.contacts,
      requests: requests,
      isProvider: asProvider,
      reviews: reviews,
    ),
    reviews: reviews,
  );
  if (!asProvider) {
    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
  }
  return reviews;
}

void main() {
  testWidgets('a confirmed job asks the customer for a rating', (tester) async {
    final requests = await _job();
    await _pump(tester, requests);

    expect(find.text('Auftrag abgeschlossen'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag bewerten'));
    await tester.pumpAndSettle();

    expect(find.text('Wie war dein Auftrag?'), findsOneWidget);
    expect(find.text('Max Montagen'), findsOneWidget);
    expect(find.text('Wohnungsreinigung'), findsOneWidget);
    // Nothing chosen, so nothing to send and no verdict implied.
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bewertung abgeben'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Ausgezeichnet'), findsNothing);
  });

  testWidgets('an unfinished job is not offered for rating', (tester) async {
    final requests = await _job(status: RequestContactStatus.inProgress);
    await _pump(tester, requests);

    expect(find.widgetWithText(FilledButton, 'Auftrag bewerten'), findsNothing);
  });

  testWidgets('picking stars names what they mean', (tester) async {
    final requests = await _job();
    await _pump(tester, requests);
    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag bewerten'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('Sehr schlecht'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Ausgezeichnet'), findsOneWidget);
  });

  testWidgets('a rating and a comment are stored and shown back', (
    tester,
  ) async {
    final requests = await _job();
    final reviews = await _pump(tester, requests);
    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag bewerten'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Alles bestens gelaufen');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Bewertung abgeben'));
    await tester.pumpAndSettle();

    final stored = reviews.byContact[_contactOf(requests)];
    expect(stored?.rating, 5);
    expect(stored?.comment, 'Alles bestens gelaufen');

    expect(find.text('Danke für deine Bewertung!'), findsOneWidget);
    expect(find.text('Alles bestens gelaufen'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Zurück zu meinen Aufträgen'),
      findsOneWidget,
    );
  });

  testWidgets('a comment alone is not a rating', (tester) async {
    final requests = await _job();
    final reviews = await _pump(tester, requests);
    await tester.tap(find.widgetWithText(FilledButton, 'Auftrag bewerten'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Nur Text, keine Sterne');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Bewertung abgeben'),
    );
    expect(button.onPressed, isNull);
    expect(reviews.byContact, isEmpty);
  });

  testWidgets('the same job cannot be rated twice', (tester) async {
    final requests = await _job();
    final reviews = await _pump(tester, requests);
    await reviews.submit(contactId: _contactOf(requests), rating: 4);

    // Pull down: the verdict came from elsewhere, and the screen has to
    // ask again before it can show it.
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Auftrag bewerten'), findsNothing);
    expect(find.text('Gut'), findsOneWidget);

    // And the store refuses a second one, the way the backend does.
    expect(
      () => reviews.submit(contactId: _contactOf(requests), rating: 1),
      throwsA(isA<AppFailure>()),
    );
  });

  testWidgets('a job that was never confirmed cannot be rated', (tester) async {
    final requests = await _job(status: RequestContactStatus.completed);
    final reviews = await _pump(tester, requests);

    expect(
      () => reviews.submit(contactId: _contactOf(requests), rating: 5),
      throwsA(isA<AppFailure>()),
    );
    expect(reviews.byContact, isEmpty);
  });

  testWidgets('the provider sees the verdict but cannot write one', (
    tester,
  ) async {
    final requests = await _job();
    final reviews = FakeReviewsRepository(
      contacts: requests.contacts,
      isProvider: true,
    );
    // Written earlier by the customer.
    reviews.byContact[_contactOf(requests)] = Review(
      id: 'r1',
      contactId: _contactOf(requests),
      customerId: testUserId,
      providerId: testProviderId,
      rating: 5,
      createdAt: DateTime(2026, 1, 1),
    );

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      jobs: FakeJobsRepository(
        contacts: requests.contacts,
        requests: requests,
        isProvider: true,
        reviews: reviews,
      ),
      reviews: reviews,
    );

    expect(find.text('Ausgezeichnet'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Auftrag bewerten'), findsNothing);
    expect(
      () => reviews.submit(contactId: _contactOf(requests), rating: 1),
      throwsA(isA<AppFailure>()),
    );
  });

  testWidgets('an unrated provider is not five stars, but unrated', (
    tester,
  ) async {
    final requests = await _job();
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      reviews: FakeReviewsRepository(contacts: requests.contacts),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
        fields: const {'display_name': 'Max Montagen'},
      ),
    );

    expect(find.text('Noch keine Bewertungen'), findsOneWidget);
    expect(find.text('5,0'), findsNothing);
    expect(find.text('0,0'), findsNothing);
  });

  testWidgets('the provider profile shows the average of real reviews', (
    tester,
  ) async {
    final requests = await _job();
    final reviews = FakeReviewsRepository(contacts: requests.contacts);
    // Four and five make four and a half.
    for (final (index, rating) in [4, 5].indexed) {
      reviews.byContact['contact-$index'] = Review(
        id: 'r$index',
        contactId: 'contact-$index',
        customerId: testUserId,
        providerId: testProviderId,
        rating: rating,
        createdAt: DateTime(2026, 1, 1),
      );
    }

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      reviews: reviews,
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
        fields: const {'display_name': 'Max Montagen'},
      ),
    );

    expect(find.text('4,5'), findsOneWidget);
    expect(find.text('2 Bewertungen'), findsOneWidget);
    expect(find.text('Noch keine Bewertungen'), findsNothing);
  });

  testWidgets('a provider nobody rated shows no stars in the match list', (
    tester,
  ) async {
    final requests = await _job(status: RequestContactStatus.accepted);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: testProviderId,
            displayName: 'Max Montagen',
            verificationStatus: ProviderVerificationStatus.unverified,
            lowestPriceCents: 3999,
          ),
        ],
        requests: requests,
      ),
      reviews: FakeReviewsRepository(contacts: requests.contacts),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();

    expect(find.text('Max Montagen'), findsOneWidget);
    // No invented score next to the name.
    expect(find.textContaining('Bewertung'), findsNothing);
  });

  testWidgets('a rated provider shows the average in the match list', (
    tester,
  ) async {
    final requests = await _job(status: RequestContactStatus.accepted);
    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      matching: FakeMatchingRepository(
        matches: const [
          ProviderMatch(
            providerId: testProviderId,
            displayName: 'Max Montagen',
            verificationStatus: ProviderVerificationStatus.unverified,
            lowestPriceCents: 3999,
            ratingAverage: 4.8,
            ratingCount: 127,
          ),
        ],
        requests: requests,
      ),
      reviews: FakeReviewsRepository(contacts: requests.contacts),
    );

    await tester.tap(_navLabel('Buchungen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Passende Anbieter'));
    await tester.pumpAndSettle();

    expect(find.text('4,8'), findsOneWidget);
    expect(find.text('127 Bewertungen'), findsOneWidget);
  });
}
