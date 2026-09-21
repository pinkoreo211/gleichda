/// Whether someone works on their own or for a company.
enum ProviderKind {
  selfEmployed,
  company;

  /// The database spells these snake_case; the Dart names are camelCase, so
  /// this is the only place that translates between them.
  String get dbName =>
      this == ProviderKind.selfEmployed ? 'self_employed' : 'company';

  static ProviderKind? fromDb(String? name) => switch (name) {
    'self_employed' => ProviderKind.selfEmployed,
    'company' => ProviderKind.company,
    _ => null,
  };
}

/// How far through onboarding a provider is, so closing the app and coming
/// back resumes at the right place instead of starting over.
enum ProviderOnboardingStatus {
  started,
  profileIncomplete,
  servicesSelected,
  verificationPending,
  completed;

  String get dbName => switch (this) {
    ProviderOnboardingStatus.started => 'started',
    ProviderOnboardingStatus.profileIncomplete => 'profile_incomplete',
    ProviderOnboardingStatus.servicesSelected => 'services_selected',
    ProviderOnboardingStatus.verificationPending => 'verification_pending',
    ProviderOnboardingStatus.completed => 'completed',
  };

  static ProviderOnboardingStatus fromDb(String? name) => switch (name) {
    'profile_incomplete' => ProviderOnboardingStatus.profileIncomplete,
    'services_selected' => ProviderOnboardingStatus.servicesSelected,
    'verification_pending' => ProviderOnboardingStatus.verificationPending,
    'completed' => ProviderOnboardingStatus.completed,
    // An unknown value from a newer app version counts as "just started",
    // which is the safe end of the scale.
    _ => ProviderOnboardingStatus.started,
  };

  bool get isCompleted => this == ProviderOnboardingStatus.completed;
}

/// Whether the team has checked this provider's documents.
///
/// Only the backend can change this. The app must never show "verified"
/// unless the server actually says so — claiming a check that never happened
/// would mislead customers about who they are letting into their home.
enum ProviderVerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  static ProviderVerificationStatus fromDb(String? name) => switch (name) {
    'pending' => ProviderVerificationStatus.pending,
    'verified' => ProviderVerificationStatus.verified,
    'rejected' => ProviderVerificationStatus.rejected,
    _ => ProviderVerificationStatus.unverified,
  };

  bool get isVerified => this == ProviderVerificationStatus.verified;
}

/// A provider's own profile. Everything except [verificationStatus] is
/// theirs to edit.
class ProviderProfile {
  const ProviderProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.displayName,
    this.kind,
    this.businessName,
    this.phone,
    this.profileImageUrl,
    this.description,
    this.city,
    this.postalCode,
    this.address,
    this.serviceRadiusKm,
    this.onboardingStatus = ProviderOnboardingStatus.started,
    this.verificationStatus = ProviderVerificationStatus.unverified,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final ProviderKind? kind;
  final String? businessName;
  final String? phone;
  final String? profileImageUrl;
  final String? description;
  final String? city;
  final String? postalCode;
  final String? address;
  final int? serviceRadiusKm;
  final ProviderOnboardingStatus onboardingStatus;
  final ProviderVerificationStatus verificationStatus;

  /// What to greet them with. Falls back through the names that exist.
  String? get greetingName {
    for (final candidate in [displayName, firstName, businessName]) {
      if (candidate != null && candidate.trim().isNotEmpty) return candidate;
    }
    return null;
  }

  bool get hasPersonalDetails =>
      (firstName?.trim().isNotEmpty ?? false) &&
      (lastName?.trim().isNotEmpty ?? false);

  bool get hasBusinessDetails => kind != null;

  bool get hasServiceArea =>
      (city?.trim().isNotEmpty ?? false) && serviceRadiusKm != null;

  static ProviderProfile fromJson(Map<String, dynamic> json) => ProviderProfile(
    id: json['id'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    displayName: json['display_name'] as String?,
    kind: ProviderKind.fromDb(json['provider_kind'] as String?),
    businessName: json['business_name'] as String?,
    phone: json['phone'] as String?,
    profileImageUrl: json['profile_image_url'] as String?,
    description: json['description'] as String?,
    city: json['city'] as String?,
    postalCode: json['postal_code'] as String?,
    address: json['address'] as String?,
    serviceRadiusKm: (json['service_radius_km'] as num?)?.toInt(),
    onboardingStatus: ProviderOnboardingStatus.fromDb(
      json['onboarding_status'] as String?,
    ),
    verificationStatus: ProviderVerificationStatus.fromDb(
      json['verification_status'] as String?,
    ),
  );
}
