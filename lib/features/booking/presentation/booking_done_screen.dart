import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/notifications/presentation/ask_for_notifications.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step seven: it is sent.
///
/// Careful with the wording: the request reached the provider, and that is
/// all that has happened. It is not confirmed, and the time is not agreed —
/// the provider answers next.
class BookingDoneScreen extends ConsumerWidget {
  const BookingDoneScreen({super.key, required this.requestId});

  /// The request the booking created, so "write a message" opens the
  /// conversation for this job rather than starting a new one.
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = ref.watch(bookingProvider);
    final providerName = draft.provider?.displayName;
    final providerId = draft.provider?.providerId;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Someone who just sent a booking is waiting for an answer,
              // which is the one moment where a notification sells itself.
              const AskForNotifications(),
              const Spacer(),
              Icon(
                Icons.check_circle_outline,
                size: AppIconSize.xl,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.bookingDoneTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                providerName == null
                    ? l10n.bookingDoneMessagePlain
                    : l10n.bookingDoneMessage(providerName),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.bookingDoneNext,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(AppRoutes.customerBookings),
                child: Text(l10n.bookingDoneViewJob),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (providerId != null)
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.customerMessagesChat(requestId, providerId),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.bookingDoneMessageProvider),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(AppRoutes.customerHome),
                child: Text(l10n.bookingDoneHome),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
