import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/app.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/booking/data/booking_repository.dart';
import 'package:app/features/booking/domain/booking_draft.dart';
import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/booking/domain/service_suggestion.dart';
import 'package:app/features/catalog/data/catalog_repository.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/catalog/domain/service_price_option.dart';
import 'package:app/features/chat/data/chat_repository.dart';
import 'package:app/features/chat/domain/chat_message.dart';
import 'package:app/features/chat/domain/conversation.dart';
import 'package:app/features/chat/domain/conversation_summary.dart';
import 'package:app/features/jobs/data/incoming_requests_repository.dart';
import 'package:app/features/jobs/data/jobs_repository.dart';
import 'package:app/features/jobs/domain/incoming_request.dart';
import 'package:app/features/jobs/domain/job.dart';
import 'package:app/features/matching/data/matching_repository.dart';
import 'package:app/features/notifications/data/push_service.dart';
import 'package:app/features/notifications/data/push_token_repository.dart';
import 'package:app/features/notifications/domain/push_message.dart';
import 'package:app/features/matching/domain/provider_match.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/features/provider/data/provider_repository.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/domain/provider_service_offering.dart';
import 'package:app/features/requests/data/service_request_repository.dart';
import 'package:app/features/reviews/data/reviews_repository.dart';
import 'package:app/features/reviews/domain/review.dart';
import 'package:app/features/requests/domain/request_contact_status.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/role_repository.dart';
import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/core/media/media_picker.dart';
import 'package:app/features/requests/data/request_photo_repository.dart';
import 'package:app/features/requests/domain/request_photo.dart';
import 'package:app/features/verification/data/verification_repository.dart';
import 'package:app/core/media/picked_media.dart';
import 'package:app/features/verification/domain/provider_document.dart';

const testUserId = 'user-1';
const testEmail = 'anna@example.at';

/// The code [FakeAuthRepository] accepts.
const validCode = '123456';

/// [AuthRepository] without a backend. Any plausible email receives a code;
/// [validCode] signs in as [testUserId].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = false})
    : _userId = signedIn ? testUserId : null,
      _email = signedIn ? testEmail : null;

  final _changes = StreamController<String?>.broadcast();
  String? _userId;
  String? _email;

  final sentCodesTo = <String>[];

  /// When set, [sendEmailCode] throws it.
  AppFailure? sendFailure;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentEmail => _email;

  @override
  Stream<String?> userIdChanges() => _changes.stream;

  @override
  Future<void> sendEmailCode(String email) async {
    if (sendFailure case final failure?) throw failure;
    sentCodesTo.add(email);
  }

  @override
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    if (code != validCode) throw AppFailure.invalidOrExpiredCode;
    _email = email;
    _setUser(testUserId);
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _setUser(null);
  }

  void _setUser(String? userId) {
    _userId = userId;
    _changes.add(userId);
  }
}

/// [RoleRepository] that records roles in memory.
class FakeRoleRepository implements RoleRepository {
  final roles = <AppRole>{};

  /// When set, [addMyRole] throws it.
  AppFailure? failure;

  @override
  Future<void> addMyRole(AppRole role) async {
    if (failure case final failure?) throw failure;
    roles.add(role);
  }
}

/// [ProfileRepository] without a backend.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({String? displayName, String? avatarUrl})
    : profile = UserProfile(displayName: displayName, avatarUrl: avatarUrl);

  /// The stored profile, updated by the writes below so a test can check
  /// what the screen actually saved.
  UserProfile profile;

  /// Every picture that was uploaded, newest last.
  final uploaded = <PickedMedia>[];

  /// When set, every call throws it.
  AppFailure? failure;

  String? get displayName => profile.displayName;

  @override
  Future<String?> myDisplayName() async => profile.displayName;

  @override
  Future<UserProfile> myProfile() async {
    if (failure case final failure?) throw failure;
    return profile;
  }

  @override
  Future<void> saveDisplayName(String? name) async {
    if (failure case final failure?) throw failure;
    final trimmed = (name ?? '').trim();
    profile = UserProfile(
      displayName: trimmed.isEmpty ? null : trimmed,
      avatarUrl: profile.avatarUrl,
    );
  }

  @override
  Future<String> saveAvatar(PickedMedia picture) async {
    if (failure case final failure?) throw failure;
    // The same two checks the backend makes, so a test that uploads
    // something impossible fails here the way it would live.
    if (picture.sizeInBytes > maxAvatarBytes) throw AppFailure.documentTooLarge;
    if (!allowedAvatarExtensions.contains(picture.extension)) {
      throw AppFailure.documentTypeNotAllowed;
    }
    uploaded.add(picture);
    final url = 'https://example.test/avatars/${uploaded.length}.jpg';
    profile = UserProfile(displayName: profile.displayName, avatarUrl: url);
    return url;
  }

  @override
  Future<void> removeAvatar() async {
    if (failure case final failure?) throw failure;
    profile = UserProfile(displayName: profile.displayName);
  }
}

/// A small stand-in catalog: two categories, three services, one of them
/// priced. Enough to exercise browsing without depending on the real data.
const testCleaningCategory = ServiceCategory(
  id: 'cat-cleaning',
  slug: 'cleaning',
  name: 'Reinigung',
  nameEn: 'Cleaning',
  iconKey: 'cleaning',
);

const testHandymanCategory = ServiceCategory(
  id: 'cat-handyman',
  slug: 'handyman',
  name: 'Handwerker',
  nameEn: 'Handyman',
  iconKey: 'handyman',
);

final testFlatCleaning = Service(
  id: 'svc-flat-cleaning',
  categoryId: testCleaningCategory.id,
  slug: 'wohnungsreinigung',
  name: 'Wohnungsreinigung',
  shortDescription: 'Einmalige Reinigung der Wohnung',
  serviceType: ServiceType.fixedPrice,
  priceOptions: const [
    ServicePriceOption(id: 'opt-small', name: 'bis 50 m²', priceCents: 5900),
    ServicePriceOption(id: 'opt-large', name: '51–80 m²', priceCents: 8900),
  ],
);

final testMoveOutCleaning = Service(
  id: 'svc-move-out',
  categoryId: testCleaningCategory.id,
  slug: 'umzugsreinigung',
  name: 'Umzugsreinigung',
  serviceType: ServiceType.quote,
);

final testFurnitureAssembly = Service(
  id: 'svc-assembly',
  categoryId: testHandymanCategory.id,
  slug: 'moebelmontage',
  name: 'Möbelmontage',
  serviceType: ServiceType.quote,
);

/// [CatalogRepository] without a backend.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    List<ServiceCategory>? categories,
    List<Service>? services,
    this.failure,
  }) : categoryList =
           categories ?? [testCleaningCategory, testHandymanCategory],
       serviceList =
           services ??
           [testFlatCleaning, testMoveOutCleaning, testFurnitureAssembly];

  final List<ServiceCategory> categoryList;
  final List<Service> serviceList;

  /// When set, every read throws it.
  final AppFailure? failure;

  @override
  Future<List<ServiceCategory>> categories() async {
    if (failure case final failure?) throw failure;
    return List.unmodifiable(categoryList);
  }

  @override
  Future<List<Service>> servicesInCategory(String categoryId) async {
    if (failure case final failure?) throw failure;
    return [
      for (final service in serviceList)
        if (service.categoryId == categoryId) service,
    ];
  }

  @override
  Future<List<Service>> allServices() async {
    if (failure case final failure?) throw failure;
    return List.unmodifiable(serviceList);
  }

  @override
  Future<Service?> serviceById(String id) async {
    if (failure case final failure?) throw failure;
    for (final service in serviceList) {
      if (service.id == id) return service;
    }
    return null;
  }
}

/// Stands in for the `request_contacts` table.
///
/// One store shared by every fake that reads or writes it, exactly as one
/// table is shared by the real functions. That is what lets a test follow a
/// request from the customer who sent it to the provider who answers it,
/// and see the answer come back on the customer's side.
class FakeRequestContacts {
  /// request id -> provider id -> status.
  final _rows = <String, Map<String, RequestContactStatus>>{};
  final _byContactId = <String, (String request, String provider)>{};

  Map<String, RequestContactStatus> forRequest(String requestId) =>
      Map.unmodifiable(_rows[requestId] ?? const {});

  /// Which providers each request reached, for assertions.
  Map<String, List<String>> get sent => {
    for (final entry in _rows.entries) entry.key: entry.value.keys.toList(),
  };

  String contactId(String requestId, String providerId) =>
      'contact-$requestId-$providerId';

  /// What was agreed when a contact came from the booking flow, keyed by
  /// contact id. Absent for an open request, which has no price and no
  /// wanted time — the same way the columns are null in the database.
  final bookedPrice = <String, int>{};
  final wantedAt = <String, DateTime>{};

  void send({
    required String requestId,
    required String providerId,
    int? priceCents,
    DateTime? wantedAt,
  }) {
    _rows.putIfAbsent(requestId, () => {})[providerId] =
        RequestContactStatus.sent;
    final id = contactId(requestId, providerId);
    _byContactId[id] = (requestId, providerId);
    if (priceCents != null) bookedPrice[id] = priceCents;
    if (wantedAt != null) this.wantedAt[id] = wantedAt;
  }

  /// Answers once, like the backend: a second answer is refused rather than
  /// quietly overwriting the first.
  void respond(String id, RequestContactStatus status) {
    final row = _byContactId[id];
    if (row == null) throw AppFailure.unknown;
    final current = _rows[row.$1]?[row.$2];
    if (current == null) throw AppFailure.unknown;
    if (!current.isOpen) throw AppFailure.requestAlreadyAnswered;
    _rows[row.$1]![row.$2] = status;
  }

  RequestContactStatus? statusOf(String id) {
    final row = _byContactId[id];
    if (row == null) return null;
    return _rows[row.$1]?[row.$2];
  }

  /// Moves a contact on. Used by the job lifecycle, which has its own rules
  /// about who may do what — those live with the caller, as they do in the
  /// database.
  void setStatus(String id, RequestContactStatus status) {
    final row = _byContactId[id];
    if (row == null) throw AppFailure.unknown;
    _rows[row.$1]![row.$2] = status;
  }

  /// Every contact belonging to [providerId], newest request first.
  Iterable<(String request, RequestContactStatus status)> forProvider(
    String providerId,
  ) sync* {
    for (final entry in _rows.entries) {
      final status = entry.value[providerId];
      if (status != null) yield (entry.key, status);
    }
  }
}

/// [MatchingRepository] without a backend.
///
/// Returns whatever it was given. The real ordering -- verified first, then
/// cheapest -- lives in SQL, so asserting it here would only test the fake.
class FakeMatchingRepository implements MatchingRepository {
  FakeMatchingRepository({
    List<ProviderMatch>? matches,
    this.failure,
    InMemoryServiceRequestRepository? requests,
    FakeRequestContacts? contacts,
  }) : matches = matches ?? const [],
       contacts = contacts ?? requests?.contacts ?? FakeRequestContacts();

  final List<ProviderMatch> matches;
  final AppFailure? failure;

  /// The one contact store. Passing the request repository shares its own,
  /// so what was sent shows up on the customer's request list too.
  final FakeRequestContacts contacts;

  /// The service ids that were asked for, for assertions.
  final askedFor = <String>[];

  /// The request ids that were asked for, for assertions.
  final askedForRequest = <String>[];

  /// Which providers each request was sent to, for assertions.
  Map<String, List<String>> get sent => contacts.sent;

  @override
  Future<List<ProviderMatch>> providersForService(
    String serviceId, {
    String? city,
  }) async {
    if (failure case final failure?) throw failure;
    askedFor.add(serviceId);
    return List.unmodifiable(matches);
  }

  @override
  Future<List<ProviderMatch>> providersForRequest(String requestId) async {
    if (failure case final failure?) throw failure;
    askedForRequest.add(requestId);
    final stored = contacts.forRequest(requestId);
    // Like the real function: what a provider answered is read back from
    // the stored row, never remembered by the screen.
    return [
      for (final match in matches)
        if (stored[match.providerId] ?? match.contactStatus case final status?)
          ProviderMatch(
            providerId: match.providerId,
            displayName: match.displayName,
            description: match.description,
            city: match.city,
            verificationStatus: match.verificationStatus,
            lowestPriceCents: match.lowestPriceCents,
            currency: match.currency,
            contactStatus: status,
            // Carried through: a rating is not something contacting
            // somebody takes away.
            ratingAverage: match.ratingAverage,
            ratingCount: match.ratingCount,
          )
        else
          match,
    ];
  }

  @override
  Future<void> sendRequestToProvider({
    required String requestId,
    required String providerId,
  }) async {
    if (failure case final failure?) throw failure;
    contacts.send(requestId: requestId, providerId: providerId);
  }
}

/// [IncomingRequestsRepository] without a backend.
///
/// Given [requests], it derives what this provider received from what was
/// actually sent, so a test can follow a request all the way from the
/// customer to the provider instead of pretending at the halfway mark.
class FakeIncomingRequestsRepository implements IncomingRequestsRepository {
  FakeIncomingRequestsRepository({
    List<IncomingRequest>? seeded,
    this.requests,
    FakeRequestContacts? contacts,
    this.providerId = testProviderId,
    this.customerName,
    this.customerAvatarUrl,
  }) : seeded = seeded ?? const [],
       contacts = contacts ?? requests?.contacts ?? FakeRequestContacts();

  final List<IncomingRequest> seeded;
  final InMemoryServiceRequestRepository? requests;
  final FakeRequestContacts contacts;

  /// Which provider this repository speaks for. The real function works it
  /// out from the signed-in account.
  final String providerId;

  /// Who the requests come from, as the backend hands it over: a name and
  /// a picture, nothing else about them.
  final String? customerName;
  final String? customerAvatarUrl;

  @override
  Future<List<IncomingRequest>> myIncomingRequests() async {
    final store = requests;
    if (store == null) return List.unmodifiable(seeded);
    return [
      ...seeded,
      // Only what was sent to this provider, like the backend's filter.
      for (final (requestId, status) in contacts.forProvider(providerId))
        if (store.byId(requestId) case final request?)
          IncomingRequest(
            contactId: contacts.contactId(requestId, providerId),
            requestId: request.id,
            description: request.originalDescription,
            sentAt: request.createdAt,
            status: status,
            serviceName: request.service?.name,
            city: request.city,
            postalCode: request.postalCode,
            timing: request.timing,
            preferredDate: request.preferredDate,
            customerName: customerName,
            customerAvatarUrl: customerAvatarUrl,
            // Present only for a booking. An open request carries no
            // price, and the card then shows none.
            priceCents:
                contacts.bookedPrice[contacts.contactId(requestId, providerId)],
            requestedAt:
                contacts.wantedAt[contacts.contactId(requestId, providerId)],
          ),
    ];
  }

  @override
  Future<void> respond({
    required String contactId,
    required RequestContactStatus status,
  }) async => contacts.respond(contactId, status);
}

const testProviderId = 'provider-1';

/// [ProviderRepository] without a backend.
///
/// Holds the profile as a row map, like the database does, so applying a
/// step's changes works exactly as the real update would.
class FakeProviderRepository implements ProviderRepository {
  FakeProviderRepository({
    bool hasProfile = false,
    ProviderOnboardingStatus status = ProviderOnboardingStatus.started,
    ProviderVerificationStatus verification =
        ProviderVerificationStatus.unverified,
    Map<String, dynamic>? fields,
    Set<String>? serviceIds,
  }) : serviceIds = {...?serviceIds},
       _row = hasProfile
           ? {
               'id': testProviderId,
               'onboarding_status': status.dbName,
               'verification_status': verification.name,
               ...?fields,
             }
           : null;

  Map<String, dynamic>? _row;

  /// The services the provider offers, updated by [setServices].
  final Set<String> serviceIds;

  /// When set, every call throws it.
  AppFailure? failure;

  /// The stored profile, for assertions.
  ProviderProfile? get profile =>
      _row == null ? null : ProviderProfile.fromJson(_row!);

  @override
  Future<ProviderProfile?> myProfile() async {
    if (failure case final failure?) throw failure;
    return profile;
  }

  @override
  Future<ProviderProfile> startProfile() async {
    if (failure case final failure?) throw failure;
    _row = {
      'id': testProviderId,
      'onboarding_status': ProviderOnboardingStatus.profileIncomplete.dbName,
      'verification_status': ProviderVerificationStatus.unverified.name,
    };
    return profile!;
  }

  @override
  Future<ProviderProfile> updateProfile(
    String providerId,
    Map<String, dynamic> changes,
  ) async {
    if (failure case final failure?) throw failure;
    _row = {...?_row, ...changes};
    return profile!;
  }

  /// Stands in for a person in the team changing the status in the
  /// dashboard. Deliberately not part of [ProviderRepository]: the app has
  /// no way to do this, and a test must not pretend otherwise.
  void teamSetsVerification(ProviderVerificationStatus status) {
    if (_row == null) return;
    _row = {..._row!, 'verification_status': status.name};
  }

  @override
  Future<Set<String>> myServiceIds(String providerId) async {
    if (failure case final failure?) throw failure;
    return {...serviceIds};
  }

  @override
  Future<void> setServices(String providerId, Set<String> ids) async {
    if (failure case final failure?) throw failure;
    serviceIds
      ..clear()
      ..addAll(ids);
  }

  /// The catalog the offerings are built from.
  final List<Service> catalogServices = [
    testFlatCleaning,
    testMoveOutCleaning,
    testFurnitureAssembly,
  ];

  /// Prices per offering id, as the database holds them per
  /// `provider_service_id`.
  final Map<String, List<ProviderServicePrice>> prices = {};

  /// Offerings get a stable id derived from the service, so tests can point
  /// at one without reading it back first.
  static String offeringId(String serviceId) => 'ps-$serviceId';

  @override
  Future<List<ProviderServiceOffering>> myOfferings(String providerId) async {
    if (failure case final failure?) throw failure;
    return [
      for (final service in catalogServices)
        if (serviceIds.contains(service.id))
          ProviderServiceOffering(
            id: offeringId(service.id),
            service: service,
            prices: prices[offeringId(service.id)] ?? const [],
          ),
    ];
  }

  @override
  Future<void> addPrice(
    String providerServiceId, {
    required String name,
    required int priceCents,
    String? unit,
    int? durationMinutes,
  }) async {
    if (failure case final failure?) throw failure;
    final list = prices.putIfAbsent(providerServiceId, () => []);
    list.add(
      ProviderServicePrice(
        id: 'price-$providerServiceId-${list.length + 1}',
        name: name.trim(),
        priceCents: priceCents,
        unit: unit,
        durationMinutes: durationMinutes,
      ),
    );
  }

  @override
  Future<void> updatePrice(String priceId, Map<String, dynamic> changes) async {
    if (failure case final failure?) throw failure;
    for (final list in prices.values) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id != priceId) continue;
        final old = list[i];
        list[i] = ProviderServicePrice(
          id: old.id,
          name: changes['name'] as String? ?? old.name,
          priceCents:
              (changes['price_cents'] as num?)?.toInt() ?? old.priceCents,
          unit: changes.containsKey('unit')
              ? changes['unit'] as String?
              : old.unit,
          durationMinutes: changes.containsKey('duration_minutes')
              ? (changes['duration_minutes'] as num?)?.toInt()
              : old.durationMinutes,
          isActive: changes['is_active'] as bool? ?? old.isActive,
        );
        return;
      }
    }
  }

  @override
  Future<void> deletePrice(String priceId) async {
    if (failure case final failure?) throw failure;
    for (final list in prices.values) {
      list.removeWhere((price) => price.id == priceId);
    }
  }
}

/// [ServiceRequestRepository] that keeps requests in memory.
///
/// Stands in for the backend, including the parts the server owns: it
/// assigns the id and the creation time, exactly as the database does.
class InMemoryServiceRequestRepository implements ServiceRequestRepository {
  /// Newest first, like the real repository.
  final requests = <ServiceRequest>[];

  /// When set, [create] throws it.
  AppFailure? failure;

  /// Stands in for `request_contacts`, which the real repository reads back
  /// with every request.
  final contacts = FakeRequestContacts();

  @override
  Future<List<ServiceRequest>> myRequests() async => [
    // The statuses are read from the contact store on every read, exactly
    // as the backend embeds them -- never patched into the list by a screen.
    for (final request in requests)
      request.copyWith(
        contactStatuses: contacts.forRequest(request.id).values.toList(),
      ),
  ];

  @override
  Future<ServiceRequest> create(ServiceRequestDraft draft) async {
    if (failure case final failure?) throw failure;
    final request = ServiceRequest(
      id: 'request-${requests.length + 1}',
      originalDescription: draft.description.trim(),
      // Fixed, increasing times keep test expectations stable.
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: requests.length)),
      category: draft.category,
      service: draft.service,
      timing: draft.timing,
      preferredDate: draft.timing == RequestTiming.onDate
          ? draft.preferredDate
          : null,
      locationLabel: draft.locationLabel,
      city: draft.city.trim().isEmpty ? null : draft.city.trim(),
      postalCode: draft.postalCode.trim().isEmpty
          ? null
          : draft.postalCode.trim(),
    );
    requests.insert(0, request);
    return request;
  }

  ServiceRequest? byId(String id) =>
      requests.where((request) => request.id == id).firstOrNull;
}

/// [ChatRepository] without a backend.
///
/// Mirrors the two rules the database enforces, so a test that breaks them
/// fails here the way it would fail there: a conversation exists only for
/// an accepted job, and only its two people can open it.
class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    required this.contacts,
    this.customerId = testUserId,
    this.myProviderId = testProviderId,
    this.isProvider = false,
    this.requests,
    this.providerName = 'Max Montagen',
    this.customerName = 'Anna Kundin',
    this.listFailure,
  });

  final FakeRequestContacts contacts;

  /// Only used to put a service name on a chat list row.
  final InMemoryServiceRequestRepository? requests;

  /// What each side is called, as the backend function resolves it.
  final String providerName;
  final String customerName;

  /// When set, reading the chat list throws it.
  final AppFailure? listFailure;

  /// Who owns the requests in [contacts].
  final String customerId;

  /// The provider profile the signed-in account belongs to, used when the
  /// provider opens a chat without naming a provider.
  final String myProviderId;

  /// Whether the caller is the provider rather than the customer. Mutable
  /// so one store can play both sides of a conversation in one test, the
  /// way one database serves two accounts.
  bool isProvider;

  final conversations = <String, Conversation>{};

  /// conversation id -> messages, oldest first.
  final messageLog = <String, List<ChatMessage>>{};

  String _key(String requestId, String providerId) => '$requestId/$providerId';

  @override
  Future<Conversation> getOrCreateConversationForRequest({
    required String requestId,
    String? providerId,
  }) async {
    final resolved = providerId ?? myProviderId;
    if (contacts.forRequest(requestId)[resolved] !=
        RequestContactStatus.accepted) {
      throw AppFailure.unknown;
    }
    return conversations.putIfAbsent(
      _key(requestId, resolved),
      () => Conversation(
        id: 'conversation-${conversations.length + 1}',
        requestId: requestId,
        customerId: customerId,
        providerId: resolved,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  }

  @override
  Future<List<ConversationSummary>> myConversations() async {
    if (listFailure case final failure?) throw failure;
    // Derived from the same stores the chat itself uses, so a test cannot
    // have a list that disagrees with the conversations behind it.
    final summaries = [
      for (final conversation in conversations.values)
        ConversationSummary(
          conversationId: conversation.id,
          requestId: conversation.requestId,
          providerId: conversation.providerId,
          viewerIsCustomer: !isProvider,
          otherName: isProvider ? customerName : providerName,
          serviceName: requests?.byId(conversation.requestId)?.service?.name,
          lastMessage: messageLog[conversation.id]?.lastOrNull?.message,
          lastMessageAt: messageLog[conversation.id]?.lastOrNull?.createdAt,
          updatedAt: conversation.updatedAt,
        ),
    ];
    summaries.sort((a, b) => b.sortedAt.compareTo(a.sortedAt));
    return summaries;
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId) async =>
      List.unmodifiable(messageLog[conversationId] ?? const []);

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw AppFailure.messageEmpty;
    final stored = messageLog.putIfAbsent(
      conversationId,
      () => <ChatMessage>[],
    );
    final message = ChatMessage(
      id: 'message-${stored.length + 1}',
      conversationId: conversationId,
      // Always the signed-in account, exactly as the backend sets it.
      senderId: isProvider ? testProviderUserId : customerId,
      message: trimmed,
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: stored.length)),
    );
    stored.add(message);
    return message;
  }
}

/// The auth account behind [testProviderId] when a test needs both sides.
const testProviderUserId = 'user-provider-1';

/// [JobsRepository] without a backend.
///
/// Mirrors the rules the database enforces — who may take which step, and
/// which step may follow which — so a test that breaks them fails here the
/// way it would fail there.
class FakeJobsRepository implements JobsRepository {
  FakeJobsRepository({
    required this.contacts,
    this.requests,
    this.isProvider = false,
    this.providerName = 'Max Montagen',
    this.customerName = 'Anna Kundin',
    this.customerAvatarUrl,
    this.providerAvatarUrl,
    this.myProviderId = testProviderId,
    this.reviews,
  });

  final FakeRequestContacts contacts;
  final InMemoryServiceRequestRepository? requests;

  /// When given, a rated job carries its rating, the way the backend joins
  /// the review onto the job.
  final FakeReviewsRepository? reviews;
  final bool isProvider;
  final String providerName;
  final String customerName;
  final String? customerAvatarUrl;
  final String? providerAvatarUrl;
  final String myProviderId;

  /// contact id -> the agreed time.
  final appointments = <String, DateTime>{};

  @override
  Future<List<Job>> myJobs() async {
    final store = requests;
    if (store == null) return const [];
    return [
      for (final (requestId, status) in contacts.forProvider(myProviderId))
        if (status.isJob)
          if (store.byId(requestId) case final request?)
            Job(
              contactId: contacts.contactId(requestId, myProviderId),
              requestId: requestId,
              providerId: myProviderId,
              viewerIsCustomer: !isProvider,
              status: status,
              description: request.originalDescription,
              otherName: isProvider ? customerName : providerName,
              otherAvatarUrl: isProvider
                  ? customerAvatarUrl
                  : providerAvatarUrl,
              serviceName: request.service?.name,
              city: request.city,
              postalCode: request.postalCode,
              scheduledAt:
                  appointments[contacts.contactId(requestId, myProviderId)],
              priceCents: contacts
                  .bookedPrice[contacts.contactId(requestId, myProviderId)],
              requestedAt: contacts
                  .wantedAt[contacts.contactId(requestId, myProviderId)],
              updatedAt: request.createdAt,
              myRating: reviews
                  ?.byContact[contacts.contactId(requestId, myProviderId)]
                  ?.rating,
              myComment: reviews
                  ?.byContact[contacts.contactId(requestId, myProviderId)]
                  ?.comment,
            ),
    ];
  }

  @override
  Future<void> advance({
    required String contactId,
    required RequestContactStatus status,
    DateTime? appointmentAt,
  }) async {
    final current = contacts.statusOf(contactId);
    if (current == null) throw AppFailure.unknown;

    // The same two questions the backend asks: may this side take this
    // step, and does it follow the one before it?
    final allowed = switch (status) {
      RequestContactStatus.scheduled =>
        current == RequestContactStatus.accepted ||
            current == RequestContactStatus.scheduled,
      RequestContactStatus.onTheWay =>
        isProvider && current == RequestContactStatus.scheduled,
      RequestContactStatus.inProgress =>
        isProvider && current == RequestContactStatus.onTheWay,
      RequestContactStatus.completed =>
        isProvider && current == RequestContactStatus.inProgress,
      RequestContactStatus.customerConfirmed =>
        !isProvider && current == RequestContactStatus.completed,
      _ => false,
    };
    if (!allowed) throw AppFailure.unknown;
    if (status == RequestContactStatus.scheduled) {
      if (appointmentAt == null) throw AppFailure.unknown;
      appointments[contactId] = appointmentAt;
    }
    contacts.setStatus(contactId, status);
  }
}

/// [ReviewsRepository] without a backend.
///
/// Mirrors the rules the database enforces: only the job's customer, only
/// a confirmed job, and only once.
class FakeReviewsRepository implements ReviewsRepository {
  FakeReviewsRepository({
    required this.contacts,
    this.isProvider = false,
    this.myProviderId = testProviderId,
  });

  final FakeRequestContacts contacts;

  /// Whether the caller is the provider rather than the customer.
  final bool isProvider;
  final String myProviderId;

  /// contact id -> the review written for it.
  final byContact = <String, Review>{};

  @override
  Future<void> submit({
    required String contactId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) throw AppFailure.unknown;
    // A provider rating their own job is not a thing the backend allows.
    if (isProvider) throw AppFailure.unknown;
    if (contacts.statusOf(contactId) !=
        RequestContactStatus.customerConfirmed) {
      throw AppFailure.unknown;
    }
    if (byContact.containsKey(contactId)) throw AppFailure.unknown;

    final trimmed = (comment ?? '').trim();
    byContact[contactId] = Review(
      id: 'review-${byContact.length + 1}',
      contactId: contactId,
      customerId: testUserId,
      providerId: myProviderId,
      rating: rating,
      comment: trimmed.isEmpty ? null : trimmed,
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: byContact.length)),
    );
  }

  @override
  Future<List<Review>> reviewsAbout(String providerId) async => [
    for (final review in byContact.values)
      if (review.providerId == providerId) review,
  ];
}

const testBookingProviderId = 'provider-booking';

/// The two suggestions the fake backend returns, keyed by a word that has
/// to appear in what the customer wrote — the same shape as the real
/// keyword match, small enough to reason about.
final testCleaningSuggestion = ServiceSuggestion(
  serviceId: testFlatCleaning.id,
  slug: testFlatCleaning.slug,
  name: testFlatCleaning.name,
  shortDescription: testFlatCleaning.shortDescription,
  serviceType: ServiceType.fixedPrice,
  categorySlug: 'cleaning',
  categoryName: 'Reinigung',
);

final testAssemblySuggestion = ServiceSuggestion(
  serviceId: testFurnitureAssembly.id,
  slug: testFurnitureAssembly.slug,
  name: testFurnitureAssembly.name,
  serviceType: ServiceType.fixedPrice,
  categorySlug: 'handyman',
  categoryName: 'Handwerker',
);

/// [BookingRepository] without a backend.
///
/// Models the rules that matter rather than only the happy path: the price
/// has to belong to the provider and the service being booked, and only a
/// verified provider is offered at all. A test that books something it
/// should not be able to book fails here the way it would fail live.
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository({
    Map<String, List<ServiceSuggestion>>? suggestions,
    List<ProviderMatch>? providers,
    Map<String, ProviderOffer>? offers,
  }) : suggestions =
           suggestions ??
           {
             'reinig': [testCleaningSuggestion],
             'putz': [testCleaningSuggestion],
             'kasten': [testAssemblySuggestion],
             'schrank': [testAssemblySuggestion],
             'möbel': [testAssemblySuggestion],
           },
       providers = providers ?? [testBookableMatch],
       offers = offers ?? {testBookingProviderId: testBookableOffer};

  /// Lower-case word → what the backend answers when it appears.
  final Map<String, List<ServiceSuggestion>> suggestions;
  final List<ProviderMatch> providers;
  final Map<String, ProviderOffer> offers;

  /// When set, every call throws it.
  AppFailure? failure;

  /// Which service the last provider list was asked for.
  String? lastServiceId;
  String? lastCity;

  /// Every booking that was written, newest last.
  final bookings = <Map<String, Object?>>[];

  @override
  Future<List<ServiceSuggestion>> suggestServices(String text) async {
    if (failure case final failure?) throw failure;
    final needle = text.toLowerCase();
    for (final entry in suggestions.entries) {
      if (needle.contains(entry.key)) return entry.value;
    }
    // Nothing convincing. The real backend says so too rather than
    // returning its best bad guess.
    return const [];
  }

  @override
  Future<List<ProviderMatch>> bookableProviders({
    required String serviceId,
    String? city,
  }) async {
    if (failure case final failure?) throw failure;
    lastServiceId = serviceId;
    lastCity = city;
    return List.unmodifiable(providers);
  }

  @override
  Future<ProviderOffer?> offerOf({
    required String providerId,
    required String serviceId,
  }) async {
    if (failure case final failure?) throw failure;
    return offers[providerId];
  }

  @override
  Future<BookingResult> createBooking({
    required String description,
    required String serviceId,
    required String providerId,
    required String priceId,
    required DateTime wantedAt,
    String? address,
    String? postalCode,
    String? city,
  }) async {
    if (failure case final failure?) throw failure;

    // The three checks the backend function makes. A price belonging to
    // somebody else, or to another service, is not on offer.
    final offer = offers[providerId];
    if (offer == null) throw AppFailure.unknown;
    if (!offer.verificationStatus.isVerified) throw AppFailure.unknown;
    final price = offer.prices.where((p) => p.id == priceId).firstOrNull;
    if (price == null) throw AppFailure.unknown;

    bookings.add({
      'description': description,
      'service_id': serviceId,
      'provider_id': providerId,
      'price_id': priceId,
      // Taken from the stored option, never from the caller.
      'price_cents': price.priceCents,
      'wanted_at': wantedAt,
      'address': address,
      'postal_code': postalCode,
      'city': city,
    });
    return BookingResult(
      requestId: 'request-${bookings.length}',
      contactId: 'contact-${bookings.length}',
    );
  }
}

const testBookableMatch = ProviderMatch(
  providerId: testBookingProviderId,
  displayName: 'Clara Clean',
  description: 'Gründlich und pünktlich.',
  city: 'Wien',
  verificationStatus: ProviderVerificationStatus.verified,
  lowestPriceCents: 5900,
  ratingAverage: 4.8,
  ratingCount: 12,
);

const testBookableOffer = ProviderOffer(
  providerId: testBookingProviderId,
  displayName: 'Clara Clean',
  description: 'Gründlich und pünktlich.',
  city: 'Wien',
  verificationStatus: ProviderVerificationStatus.verified,
  ratingAverage: 4.8,
  ratingCount: 12,
  prices: [
    ProviderPrice(
      id: 'price-small',
      name: 'Bis 50 m²',
      priceCents: 5900,
      unit: 'pro Auftrag',
      durationMinutes: 120,
    ),
    ProviderPrice(id: 'price-large', name: '51–80 m²', priceCents: 8900),
  ],
);

/// Stands in for the `provider_documents` table and the private bucket
/// together: one store, shared by every fake, keyed by provider.
///
/// Two providers in a test share this the way they share a database, which
/// is what makes "provider B cannot see provider A's document" a real
/// assertion rather than a fake one.
class FakeDocumentStore {
  /// provider id -> document type -> the current document.
  final byProvider = <String, Map<ProviderDocumentType, ProviderDocument>>{};

  int _counter = 0;

  List<ProviderDocument> documentsOf(String providerId) =>
      byProvider[providerId]?.values.toList() ?? const [];

  ProviderDocument? documentOf(String providerId, ProviderDocumentType type) =>
      byProvider[providerId]?[type];

  /// What `submit_provider_document()` does: refuses a replacement the team
  /// has taken in hand, and otherwise records the file as waiting.
  ProviderDocument submit({
    required String providerId,
    required ProviderDocumentType type,
    String? fileName,
  }) {
    final existing = documentOf(providerId, type);
    if (existing != null && !existing.status.canBeReplaced) {
      throw AppFailure.documentLocked;
    }
    final document = ProviderDocument(
      id: 'document-${++_counter}',
      type: type,
      status: ProviderDocumentStatus.uploaded,
      uploadedAt: DateTime(2026, 9, 26).add(Duration(minutes: _counter)),
      filePath: '$providerId/${type.dbName}/$_counter',
      fileName: fileName,
    );
    (byProvider[providerId] ??= {})[type] = document;
    return document;
  }

  /// What a person in the team does in the dashboard. No app path reaches
  /// this, which is the point of having it separate.
  void teamDecides({
    required String providerId,
    required ProviderDocumentType type,
    required ProviderDocumentStatus status,
    String? reason,
  }) {
    final existing = documentOf(providerId, type);
    if (existing == null) return;
    byProvider[providerId]![type] = ProviderDocument(
      id: existing.id,
      type: existing.type,
      status: status,
      uploadedAt: existing.uploadedAt,
      filePath: existing.filePath,
      fileName: existing.fileName,
      rejectionReason: status == ProviderDocumentStatus.rejected
          ? reason
          : null,
      reviewedAt: DateTime(2026, 9, 27),
    );
  }
}

/// [VerificationRepository] for one signed-in provider.
///
/// Reads and writes only [myProviderId]'s documents, the way the backend
/// functions do: whatever else is in the store is unreachable from here.
class FakeVerificationRepository implements VerificationRepository {
  FakeVerificationRepository({
    FakeDocumentStore? store,
    this.myProviderId = testProviderId,
    this.provider,
    List<DocumentRequirement>? requirements,
  }) : store = store ?? FakeDocumentStore(),
       requirements = requirements ?? defaultRequirements;

  /// The baseline the backend returns when no service asks for more.
  static const defaultRequirements = [
    DocumentRequirement(type: ProviderDocumentType.identity, isRequired: true),
    DocumentRequirement(
      type: ProviderDocumentType.businessRegistration,
      isRequired: true,
    ),
    DocumentRequirement(
      type: ProviderDocumentType.qualification,
      isRequired: false,
    ),
    DocumentRequirement(
      type: ProviderDocumentType.insurance,
      isRequired: false,
    ),
  ];

  final FakeDocumentStore store;
  final String myProviderId;
  final List<DocumentRequirement> requirements;

  /// Kept in step so the status badge moves with the uploads, the way the
  /// backend function moves it.
  final FakeProviderRepository? provider;

  @override
  Future<List<DocumentRequirement>> myRequirements() async => requirements;

  @override
  Future<List<ProviderDocument>> myDocuments() async =>
      store.documentsOf(myProviderId);

  @override
  Future<void> submit({
    required String providerId,
    required ProviderDocumentType type,
    required PickedMedia file,
  }) async {
    if (file.sizeInBytes > maxDocumentBytes) throw AppFailure.documentTooLarge;
    if (!allowedDocumentExtensions.contains(file.extension)) {
      throw AppFailure.documentTypeNotAllowed;
    }
    // The backend takes the provider from the signed-in account, so a
    // request naming somebody else's profile gets nowhere.
    if (providerId != myProviderId) throw AppFailure.unknown;

    store.submit(
      providerId: myProviderId,
      type: type,
      fileName: file.displayName,
    );

    // Handing something in starts a check. Never sets 'verified'.
    final current = provider?.profile?.verificationStatus;
    if (current == ProviderVerificationStatus.unverified ||
        current == ProviderVerificationStatus.rejected) {
      provider!.teamSetsVerification(ProviderVerificationStatus.pending);
    }
  }
}

/// [MediaPicker] that hands back [next] instead of opening a camera.
class FakeMediaPicker implements MediaPicker {
  FakeMediaPicker({PickedMedia? next})
    : next =
          next ??
          PickedMedia(
            fileName: 'ausweis.jpg',
            displayName: 'ausweis.jpg',
            bytes: Uint8List.fromList(const [1, 2, 3]),
          );

  /// Null stands for backing out of the picker, which is not an error.
  PickedMedia? next;

  /// Which sources the screen asked for, in order.
  final asked = <MediaSource>[];

  @override
  Future<PickedMedia?> pick(MediaSource source) async {
    asked.add(source);
    return next;
  }
}

/// Photos on requests, kept in a map instead of a private bucket.
///
/// Says nothing about who may look: the real one does not either. That
/// question is the backend's, and a fake that answered it would be testing
/// a rule the app does not hold.
class FakeRequestPhotoRepository implements RequestPhotoRepository {
  FakeRequestPhotoRepository({this.failsToAttach = false});

  /// What each request carries, in the order it was added.
  final photos = <String, List<RequestPhoto>>{};

  /// Every file that reached this repository, across all requests. Lets a
  /// test say "exactly these, in this order" rather than "some number".
  final attached = <String>[];

  /// Makes every upload fail, for the case where a booking goes through
  /// and a picture does not.
  bool failsToAttach;

  int _next = 0;

  @override
  Future<List<RequestPhoto>> photosOf(String requestId) async =>
      List.unmodifiable(photos[requestId] ?? const <RequestPhoto>[]);

  @override
  Future<void> attach({
    required String requestId,
    required PickedMedia photo,
  }) async {
    if (failsToAttach) throw AppFailure.unknown;
    attached.add(photo.fileName);
    (photos[requestId] ??= []).add(
      RequestPhoto(
        id: 'photo-${_next++}',
        // Never loads in a test, which is the point: the strip has to cope
        // with a picture that does not arrive.
        url: 'https://example.invalid/${photo.fileName}',
      ),
    );
  }

  @override
  Future<void> remove(String photoId) async {
    for (final list in photos.values) {
      list.removeWhere((photo) => photo.id == photoId);
    }
  }
}

/// [PushService] without a push provider.
///
/// Nothing here reaches a network. It records what the app asked for, so a
/// test can check that permission was requested at the right moment and
/// that a tapped notification opened the right job.
class FakePushService implements PushService {
  FakePushService({
    this.isAvailable = true,
    this.grantsPermission = true,
    this.token = 'device-token-1',
    this.startedFrom,
  });

  @override
  final bool isAvailable;

  /// What the operating system answers. False stands for a person who
  /// declined, which must leave the app working.
  final bool grantsPermission;

  String? token;

  /// A notification that started the app from cold.
  PushMessage? startedFrom;

  /// How often the app asked. The operating system shows its dialog once,
  /// so anything above one would be the app nagging.
  int permissionRequests = 0;

  final _opened = StreamController<PushMessage>.broadcast();
  final _received = StreamController<PushMessage>.broadcast();
  final _tokens = StreamController<String>.broadcast();

  /// Stands in for the person tapping a notification.
  void tap(PushMessage message) => _opened.add(message);

  /// Stands in for one arriving while the app is open, which the
  /// operating system does not show.
  void arrive(PushMessage message) => _received.add(message);

  void rotateToken(String next) {
    token = next;
    _tokens.add(next);
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantsPermission;
  }

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<String?> currentToken() async => grantsPermission ? token : null;

  @override
  Stream<String> get tokenChanges => _tokens.stream;

  @override
  Stream<PushMessage> get opened => _opened.stream;

  @override
  Stream<PushMessage> get received => _received.stream;

  @override
  Future<PushMessage?> initialMessage() async => startedFrom;
}

/// [PushTokenRepository] that records what was registered.
class FakePushTokenRepository implements PushTokenRepository {
  /// Every token currently filed under this account.
  final registered = <String>{};
  final forgotten = <String>[];

  /// When set, every call throws it.
  AppFailure? failure;

  @override
  Future<void> register(String token) async {
    if (failure case final failure?) throw failure;
    registered.add(token);
  }

  @override
  Future<void> forget(String token) async {
    if (failure case final failure?) throw failure;
    registered.remove(token);
    forgotten.add(token);
  }
}

/// [SessionStore] that keeps everything in memory.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([Map<String, AppRole>? activeRoles])
    : activeRoles = {...?activeRoles};

  final Map<String, AppRole> activeRoles;

  @override
  AppRole? readActiveRole(String userId) => activeRoles[userId];

  @override
  Future<void> writeActiveRole(String userId, AppRole role) async =>
      activeRoles[userId] = role;
}

/// Starts the whole app with fake backend services on a device with [locale]
/// (default: Austrian German).
Future<void> pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? auth,
  FakeRoleRepository? roles,
  InMemorySessionStore? store,
  InMemoryServiceRequestRepository? requests,
  FakeCatalogRepository? catalog,
  FakeProfileRepository? profile,
  FakeProviderRepository? provider,
  FakeMatchingRepository? matching,
  FakeIncomingRequestsRepository? incoming,
  FakeChatRepository? chat,
  FakeJobsRepository? jobs,
  FakeReviewsRepository? reviews,
  FakeVerificationRepository? verification,
  FakeBookingRepository? booking,
  FakePushService? push,
  FakePushTokenRepository? pushTokens,
  FakeMediaPicker? picker,
  FakeRequestPhotoRepository? photos,
  Locale locale = const Locale('de', 'AT'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  // Mirrors main(): dates are formatted for the market's locale, which needs
  // its date names loaded first.
  await initializeDateFormatting();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        roleRepositoryProvider.overrideWithValue(roles ?? FakeRoleRepository()),
        sessionStoreProvider.overrideWithValue(store ?? InMemorySessionStore()),
        serviceRequestRepositoryProvider.overrideWithValue(
          requests ?? InMemoryServiceRequestRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          profile ?? FakeProfileRepository(),
        ),
        catalogRepositoryProvider.overrideWithValue(
          catalog ?? FakeCatalogRepository(),
        ),
        providerRepositoryProvider.overrideWithValue(
          provider ?? FakeProviderRepository(),
        ),
        matchingRepositoryProvider.overrideWithValue(
          matching ?? FakeMatchingRepository(),
        ),
        incomingRequestsRepositoryProvider.overrideWithValue(
          incoming ?? FakeIncomingRequestsRepository(),
        ),
        if (chat != null) chatRepositoryProvider.overrideWithValue(chat),
        jobsRepositoryProvider.overrideWithValue(
          jobs ?? FakeJobsRepository(contacts: FakeRequestContacts()),
        ),
        reviewsRepositoryProvider.overrideWithValue(
          reviews ?? FakeReviewsRepository(contacts: FakeRequestContacts()),
        ),
        pushServiceProvider.overrideWithValue(push ?? FakePushService()),
        pushTokenRepositoryProvider.overrideWithValue(
          pushTokens ?? FakePushTokenRepository(),
        ),
        bookingRepositoryProvider.overrideWithValue(
          booking ?? FakeBookingRepository(),
        ),
        verificationRepositoryProvider.overrideWithValue(
          verification ?? FakeVerificationRepository(),
        ),
        mediaPickerProvider.overrideWithValue(picker ?? FakeMediaPicker()),
        requestPhotoRepositoryProvider.overrideWithValue(
          photos ?? FakeRequestPhotoRepository(),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls the current screen until [finder] is on screen.
///
/// Screens grow over time, and a test should not fail only because a button
/// moved below the fold on the small default test screen.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

/// A signed-in user whose last used mode was [role].
Future<void> pumpSignedInApp(
  WidgetTester tester, {
  required AppRole? role,
  FakeAuthRepository? auth,
  FakeRoleRepository? roles,
  InMemorySessionStore? store,
  InMemoryServiceRequestRepository? requests,
  FakeCatalogRepository? catalog,
  FakeProfileRepository? profile,
  FakeProviderRepository? provider,
  FakeMatchingRepository? matching,
  FakeIncomingRequestsRepository? incoming,
  FakeChatRepository? chat,
  FakeJobsRepository? jobs,
  FakeReviewsRepository? reviews,
  FakeVerificationRepository? verification,
  FakeBookingRepository? booking,
  FakePushService? push,
  FakePushTokenRepository? pushTokens,
  FakeMediaPicker? picker,
  FakeRequestPhotoRepository? photos,
}) {
  return pumpApp(
    tester,
    auth: auth ?? FakeAuthRepository(signedIn: true),
    roles: roles ?? (FakeRoleRepository()..roles.addAll([?role])),
    store: store ?? InMemorySessionStore({testUserId: ?role}),
    requests: requests,
    profile: profile,
    catalog: catalog,
    // A signed-in provider is an established one unless a test says
    // otherwise, so the guard does not send every provider test into
    // onboarding.
    matching: matching,
    incoming: incoming,
    chat: chat,
    jobs: jobs,
    reviews: reviews,
    verification: verification,
    booking: booking,
    push: push,
    pushTokens: pushTokens,
    picker: picker,
    photos: photos,
    provider:
        provider ??
        (role == AppRole.provider
            ? FakeProviderRepository(
                hasProfile: true,
                status: ProviderOnboardingStatus.completed,
              )
            : null),
  );
}

/// The Riverpod container behind the running app, for reading state a test
/// cannot see on screen.
ProviderContainer providerContainerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));
