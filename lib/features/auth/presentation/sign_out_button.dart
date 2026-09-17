import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/l10n/app_localizations.dart';

/// Signs the user out. The router then returns to the welcome screen.
class SignOutButton extends ConsumerWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
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
