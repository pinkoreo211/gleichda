import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/features/notifications/application/push_controller.dart';

/// Asks for permission to send notifications, once, when this is on
/// screen. Renders nothing.
///
/// Placed on the screens where the reason is obvious — a provider's job
/// list, and the moment a customer has just sent a booking — rather than
/// on the first launch. Asked before there is anything to be notified
/// about, most people say no, and the operating system never asks again.
///
/// A "no" changes nothing else: no token is registered, no push arrives,
/// and the app is otherwise the same.
class AskForNotifications extends ConsumerStatefulWidget {
  const AskForNotifications({super.key});

  @override
  ConsumerState<AskForNotifications> createState() =>
      _AskForNotificationsState();
}

class _AskForNotificationsState extends ConsumerState<AskForNotifications> {
  @override
  void initState() {
    super.initState();
    // After the first frame: the dialog belongs on a screen the person can
    // already see, not on one still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushProvider.notifier).askIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
