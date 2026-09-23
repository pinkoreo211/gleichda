import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/l10n/app_localizations.dart';

/// Shows [error] as a short message at the bottom of the screen.
void showFailureSnackBar(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppFailure.fromError(error).message(l10n))),
  );
}

extension AppFailureMessage on AppFailure {
  String message(AppLocalizations l10n) => switch (this) {
    AppFailure.invalidEmail => l10n.errorInvalidEmail,
    AppFailure.invalidOrExpiredCode => l10n.errorInvalidOrExpiredCode,
    AppFailure.tooManyRequests => l10n.errorTooManyRequests,
    AppFailure.emailNotAuthorized => l10n.errorEmailNotAuthorized,
    AppFailure.messageEmpty => l10n.errorMessageEmpty,
    AppFailure.requestAlreadyAnswered => l10n.errorRequestAlreadyAnswered,
    AppFailure.unknown => l10n.errorUnknown,
  };
}
