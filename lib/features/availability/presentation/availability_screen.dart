import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// The provider's working hours and appointments. Placeholder until
/// availability exists.
class AvailabilityScreen extends StatelessWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabCalendar)),
      body: EmptyState(
        icon: Icons.calendar_month_outlined,
        title: l10n.availabilityTitle,
        message: l10n.availabilityMessage,
      ),
    );
  }
}
