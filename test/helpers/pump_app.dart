import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/app.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/catalog/data/catalog_repository.dart';
import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart';
import 'package:app/features/catalog/domain/service_price_option.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/provider/data/provider_repository.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/requests/data/service_request_repository.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/data/role_repository.dart';
import 'package:app/features/session/data/session_store.dart';
import 'package:app/features/session/domain/app_role.dart';

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
  FakeProfileRepository({this.displayName});

  final String? displayName;

  @override
  Future<String?> myDisplayName() async => displayName;
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

  @override
  Future<List<ServiceRequest>> myRequests() async =>
      List.unmodifiable(requests);

  @override
  Future<ServiceRequest> create(ServiceRequestDraft draft) async {
    if (failure case final failure?) throw failure;
    final request = ServiceRequest(
      id: 'request-${requests.length + 1}',
      originalDescription: draft.description.trim(),
      // Fixed, increasing times keep test expectations stable.
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: requests.length)),
      category: draft.category,
      timing: draft.timing,
      preferredDate: draft.timing == RequestTiming.onDate
          ? draft.preferredDate
          : null,
      locationLabel: draft.locationLabel,
    );
    requests.insert(0, request);
    return request;
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
