import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Job requests and projects for the provider. Placeholder until jobs exist.
class ProviderJobsScreen extends StatelessWidget {
  const ProviderJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabJobs)),
      body: EmptyState(
        icon: Icons.work_outline,
        title: l10n.providerJobsEmptyTitle,
        message: l10n.providerJobsEmptyMessage,
      ),
    );
  }
}
