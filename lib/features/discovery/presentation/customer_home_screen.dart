import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Customer start screen. Placeholder until search and categories are built.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabHome)),
      body: EmptyState(
        icon: Icons.search,
        title: l10n.customerHomeTitle,
        message: l10n.customerHomeMessage,
      ),
    );
  }
}
