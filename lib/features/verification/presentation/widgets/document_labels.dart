import 'package:material_ui/material_ui.dart';

import 'package:app/features/verification/domain/provider_document.dart';
import 'package:app/l10n/app_localizations.dart';

/// What each kind of proof is called, and what counts as one.
///
/// The hint matters: "Identitätsnachweis" alone leaves a provider guessing
/// whether a driving licence will do.
extension ProviderDocumentTypeDisplay on ProviderDocumentType {
  String label(AppLocalizations l10n) => switch (this) {
    ProviderDocumentType.identity => l10n.documentTypeIdentity,
    ProviderDocumentType.businessRegistration =>
      l10n.documentTypeBusinessRegistration,
    ProviderDocumentType.tradeLicense => l10n.documentTypeTradeLicense,
    ProviderDocumentType.qualification => l10n.documentTypeQualification,
    ProviderDocumentType.insurance => l10n.documentTypeInsurance,
    ProviderDocumentType.other => l10n.documentTypeOther,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    ProviderDocumentType.identity => l10n.documentTypeIdentityHint,
    ProviderDocumentType.businessRegistration =>
      l10n.documentTypeBusinessRegistrationHint,
    ProviderDocumentType.tradeLicense => l10n.documentTypeTradeLicenseHint,
    ProviderDocumentType.qualification => l10n.documentTypeQualificationHint,
    ProviderDocumentType.insurance => l10n.documentTypeInsuranceHint,
    ProviderDocumentType.other => l10n.documentTypeOtherHint,
  };

  IconData get icon => switch (this) {
    ProviderDocumentType.identity => Icons.badge_outlined,
    ProviderDocumentType.businessRegistration => Icons.storefront_outlined,
    ProviderDocumentType.tradeLicense => Icons.gavel_outlined,
    ProviderDocumentType.qualification => Icons.workspace_premium_outlined,
    ProviderDocumentType.insurance => Icons.health_and_safety_outlined,
    ProviderDocumentType.other => Icons.description_outlined,
  };
}

/// Where a handed-in document stands, in the provider's words.
///
/// `uploaded` and `in_review` read the same: from this side both mean "we
/// have it, nobody has decided yet", and pretending to know more would be
/// inventing progress.
extension ProviderDocumentStatusDisplay on ProviderDocumentStatus {
  String label(AppLocalizations l10n) => switch (this) {
    ProviderDocumentStatus.uploaded ||
    ProviderDocumentStatus.inReview => l10n.verificationStatusWaiting,
    ProviderDocumentStatus.accepted => l10n.verificationStatusAccepted,
    ProviderDocumentStatus.rejected => l10n.verificationStatusRejected,
  };

  IconData get icon => switch (this) {
    ProviderDocumentStatus.uploaded ||
    ProviderDocumentStatus.inReview => Icons.hourglass_empty,
    ProviderDocumentStatus.accepted => Icons.check_circle_outline,
    ProviderDocumentStatus.rejected => Icons.error_outline,
  };

  Color color(ColorScheme colors) => switch (this) {
    ProviderDocumentStatus.uploaded ||
    ProviderDocumentStatus.inReview => colors.onSurfaceVariant,
    ProviderDocumentStatus.accepted => colors.primary,
    ProviderDocumentStatus.rejected => colors.error,
  };
}
