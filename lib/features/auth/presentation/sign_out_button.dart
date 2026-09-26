import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/notifications/application/push_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Signs the user out. The router then returns to the welcome screen.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        // Before signing out, while the session is still valid: the
        // backend only lets someone unregister their own device, and in a
        // moment this will not be their session any more. Otherwise the
        // next person on this phone gets the last one's notifications.
        await ref.read(pushProvider.notifier).forgetThisDevice();
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (error) {
          if (context.mounted) showFailureSnackBar(context, error);
        }
      },
      child: Text(AppLocalizations.of(context).signOut),
    );
  }
}
