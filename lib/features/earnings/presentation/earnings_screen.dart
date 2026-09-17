import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// The provider's completed jobs and payouts. Placeholder until payments
/// exist.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabEarnings)),
      body: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.earningsEmptyTitle,
        message: l10n.earningsEmptyMessage,
      ),
    );
  }
}
