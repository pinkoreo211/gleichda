import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/widgets/empty_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// List of chats, shared by customers and providers. Placeholder until chat
/// exists.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabMessages)),
      body: EmptyState(
        icon: Icons.chat_bubble_outline,
        title: l10n.conversationsEmptyTitle,
        message: l10n.conversationsEmptyMessage,
      ),
    );
  }
}
