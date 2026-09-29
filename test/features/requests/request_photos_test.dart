import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/request_photo.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/requests/presentation/widgets/request_photo_strip.dart';
import 'package:app/features/session/domain/app_role.dart';

import '../../helpers/pump_app.dart';

const _job = 'Der Wasserhahn tropft';

/// One request from the customer to Max, left at [status].
Future<InMemoryServiceRequestRepository> _requestAt(
  RequestContactStatus status,
) async {
  final requests = InMemoryServiceRequestRepository();
  final stored = await requests.create(
    ServiceRequestDraft(
      description: _job,
      service: testFlatCleaning,
      city: 'Wien',
    ),
  );
  requests.contacts.send(requestId: stored.id, providerId: testProviderId);
  if (status != RequestContactStatus.sent) {
    requests.contacts.respond(
      requests.contacts.contactId(stored.id, testProviderId),
      status,
    );
  }
  return requests;
}

String _idOf(InMemoryServiceRequestRepository requests) =>
    requests.requests.single.id;

/// [count] photos already on [requestId], as if they had been uploaded.
FakeRequestPhotoRepository _withPhotos(String requestId, int count) {
  final photos = FakeRequestPhotoRepository();
  photos.photos[requestId] = [
    for (var index = 0; index < count; index++)
      RequestPhoto(id: 'photo-$index', url: 'https://example.invalid/$index'),
  ];
  return photos;
}

/// How many thumbnails are on screen. One tappable tile per photo.
int _thumbnails(WidgetTester tester) => tester
    .widgetList(
      find.descendant(
        of: find.byType(RequestPhotoStrip),
        matching: find.byType(InkWell),
      ),
    )
    .length;

void main() {
  testWidgets('a provider sees the photos while deciding, not after', (
    tester,
  ) async {
    // The request is still unanswered: this is the screen with Accept and
    // Decline on it. Seeing the photos only after accepting would be too
    // late — there is no way back out of a job.
    final requests = await _requestAt(RequestContactStatus.sent);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
      photos: _withPhotos(_idOf(requests), 2),
    );

    await scrollTo(tester, find.text(_job));
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsOneWidget);
    expect(_thumbnails(tester), 2);
  });

  testWidgets('a request with no photos shows nothing where they would be', (
    tester,
  ) async {
    final requests = await _requestAt(RequestContactStatus.sent);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
    );

    await scrollTo(tester, find.text(_job));
    // Most requests will never carry one, so the strip has to take up no
    // room at all rather than leaving a gap in every card.
    expect(_thumbnails(tester), 0);
    expect(find.byType(RequestPhotoStrip), findsWidgets);
  });

  testWidgets('a customer sees their own photos before anyone has answered', (
    tester,
  ) async {
    // Their own request, still unanswered, so it is not a job yet and does
    // not appear as one. Somebody who attached a picture should still be
    // able to check what they sent.
    final requests = await _requestAt(RequestContactStatus.sent);

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      jobs: FakeJobsRepository(contacts: requests.contacts, requests: requests),
      photos: _withPhotos(_idOf(requests), 2),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Buchungen'),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.textContaining(_job));
    expect(_thumbnails(tester), 2);
  });

  testWidgets('both sides of a job see the same pictures', (tester) async {
    final requests = await _requestAt(RequestContactStatus.accepted);
    final photos = _withPhotos(_idOf(requests), 3);

    await pumpSignedInApp(
      tester,
      role: AppRole.customer,
      requests: requests,
      jobs: FakeJobsRepository(contacts: requests.contacts, requests: requests),
      photos: photos,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Buchungen'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_thumbnails(tester), 3);

    // The same job from the other side. They are about to stand in the
    // same room about the thing in the photos.
    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      jobs: FakeJobsRepository(
        contacts: requests.contacts,
        requests: requests,
        isProvider: true,
      ),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
      photos: photos,
    );
    await tester.pumpAndSettle();
    expect(_thumbnails(tester), 3);
  });

  testWidgets('a picture that will not load leaves the card usable', (
    tester,
  ) async {
    // Nothing loads in a test, which is exactly the case worth checking:
    // an expired link, or a file storage no longer has. The card around it
    // has to go on working.
    final requests = await _requestAt(RequestContactStatus.sent);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
      photos: _withPhotos(_idOf(requests), 1),
    );

    await scrollTo(tester, find.text(_job));
    expect(find.text(_job), findsOneWidget);
    // Still the buttons that matter, and still the whole description.
    expect(find.widgetWithText(FilledButton, 'Annehmen'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ablehnen'), findsOneWidget);
  });

  testWidgets('tapping one opens it large', (tester) async {
    final requests = await _requestAt(RequestContactStatus.sent);

    await pumpSignedInApp(
      tester,
      role: AppRole.provider,
      requests: requests,
      incoming: FakeIncomingRequestsRepository(requests: requests),
      provider: FakeProviderRepository(
        hasProfile: true,
        status: ProviderOnboardingStatus.completed,
      ),
      photos: _withPhotos(_idOf(requests), 2),
    );

    await scrollTo(tester, find.text(_job));
    await tester.tap(
      find
          .descendant(
            of: find.byType(RequestPhotoStrip),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();

    // Says which of the two is open, so nobody swipes wondering whether
    // there is more.
    expect(find.text('1 von 2'), findsOneWidget);
  });
}
