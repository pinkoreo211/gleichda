/// The kinds of proof a provider can be asked for.
///
/// The names come from the database, which spells them snake_case. The
/// translation lives here and nowhere else.
enum ProviderDocumentType {
  identity('identity'),
  businessRegistration('business_registration'),
  tradeLicense('trade_license'),
  qualification('qualification'),
  insurance('insurance'),
  other('other');

  const ProviderDocumentType(this.dbName);

  final String dbName;

  static ProviderDocumentType? fromDb(String? name) {
    for (final type in ProviderDocumentType.values) {
      if (type.dbName == name) return type;
    }
    // A type a newer backend knows and this app does not: skipped rather
    // than shown as something it is not.
    return null;
  }
}

/// Where one handed-in document stands.
///
/// Only the team moves a document past [uploaded]. The app shows
/// [uploaded] and [inReview] the same way, because from the provider's
/// side both mean "we have it, we are looking".
enum ProviderDocumentStatus {
  uploaded('uploaded'),
  inReview('in_review'),
  accepted('accepted'),
  rejected('rejected');

  const ProviderDocumentStatus(this.dbName);

  final String dbName;

  static ProviderDocumentStatus fromDb(String? name) {
    for (final status in ProviderDocumentStatus.values) {
      if (status.dbName == name) return status;
    }
    // Unknown means "handed in, not decided", which is the cautious read.
    return ProviderDocumentStatus.uploaded;
  }

  bool get isWaiting =>
      this == ProviderDocumentStatus.uploaded ||
      this == ProviderDocumentStatus.inReview;

  bool get isAccepted => this == ProviderDocumentStatus.accepted;

  bool get isRejected => this == ProviderDocumentStatus.rejected;

  /// Whether the provider may hand in a replacement. Not while the team is
  /// looking at it, and not once it has been accepted.
  bool get canBeReplaced => switch (this) {
    ProviderDocumentStatus.uploaded || ProviderDocumentStatus.rejected => true,
    ProviderDocumentStatus.inReview || ProviderDocumentStatus.accepted => false,
  };
}

/// One document the provider handed in.
class ProviderDocument {
  const ProviderDocument({
    required this.id,
    required this.type,
    required this.status,
    required this.uploadedAt,
    this.filePath,
    this.fileName,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String id;
  final ProviderDocumentType type;
  final ProviderDocumentStatus status;
  final DateTime uploadedAt;

  /// Where the file sits in the private bucket. Not a link: reaching it
  /// needs a signed URL, and only the owner can ask for one.
  final String? filePath;

  /// What the file was called on the provider's phone, so they recognise
  /// which one they sent.
  final String? fileName;

  /// Why the team turned it down. Only ever written by the team.
  final String? rejectionReason;

  final DateTime? reviewedAt;

  static ProviderDocument? fromJson(Map<String, dynamic> json) {
    final type = ProviderDocumentType.fromDb(json['document_type'] as String?);
    if (type == null) return null;
    return ProviderDocument(
      id: json['id'] as String,
      type: type,
      status: ProviderDocumentStatus.fromDb(json['status'] as String?),
      uploadedAt:
          DateTime.tryParse(json['uploaded_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      filePath: json['file_path'] as String?,
      fileName: json['file_name'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
    );
  }
}

/// A document type this provider is asked for, and whether it is a must.
///
/// Which types appear depends on the services they offer — the backend
/// works that out, so adding a rule needs no new app release.
class DocumentRequirement {
  const DocumentRequirement({required this.type, required this.isRequired});

  final ProviderDocumentType type;
  final bool isRequired;

  static DocumentRequirement? fromJson(Map<String, dynamic> json) {
    final type = ProviderDocumentType.fromDb(json['document_type'] as String?);
    if (type == null) return null;
    return DocumentRequirement(
      type: type,
      isRequired: json['is_required'] as bool? ?? false,
    );
  }
}

/// One line of the verification list: what is asked for, and what — if
/// anything — has been handed in for it.
class VerificationEntry {
  const VerificationEntry({required this.requirement, this.document});

  final DocumentRequirement requirement;
  final ProviderDocument? document;

  ProviderDocumentType get type => requirement.type;
  bool get isRequired => requirement.isRequired;
  bool get hasDocument => document != null;

  /// Whether tapping this offers an upload. A document being checked, or
  /// already accepted, is not the provider's to swap out.
  bool get canUpload => document?.status.canBeReplaced ?? true;
}

/// The whole picture: every requirement, with whatever was handed in.
class VerificationChecklist {
  const VerificationChecklist(this.entries);

  final List<VerificationEntry> entries;

  /// Builds the list the screen shows. A document whose type is no longer
  /// asked for still appears, so nothing a provider sent quietly vanishes.
  factory VerificationChecklist.from({
    required List<DocumentRequirement> requirements,
    required List<ProviderDocument> documents,
  }) {
    final byType = {for (final document in documents) document.type: document};
    final entries = [
      for (final requirement in requirements)
        VerificationEntry(
          requirement: requirement,
          document: byType[requirement.type],
        ),
    ];
    final asked = {for (final requirement in requirements) requirement.type};
    for (final document in documents) {
      if (asked.contains(document.type)) continue;
      entries.add(
        VerificationEntry(
          requirement: DocumentRequirement(
            type: document.type,
            isRequired: false,
          ),
          document: document,
        ),
      );
    }
    return VerificationChecklist(entries);
  }

  bool get isEmpty => entries.isEmpty;

  /// Everything that has to be there before the team can finish a check.
  bool get allRequiredHandedIn => entries
      .where((entry) => entry.isRequired)
      .every(
        (entry) => entry.hasDocument && !entry.document!.status.isRejected,
      );
}
