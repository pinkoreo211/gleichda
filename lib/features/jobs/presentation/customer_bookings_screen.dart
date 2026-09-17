import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// The customer's booked jobs and projects. Placeholder until booking exists.
class CustomerBookingsScreen extends StatelessWidget {
  const CustomerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabBookings)),
      body: EmptyState(
        icon: Icons.event_note_outlined,
        title: l10n.customerBookingsEmptyTitle,
        message: l10n.customerBookingsEmptyMessage,
      ),
    );
  }
}
