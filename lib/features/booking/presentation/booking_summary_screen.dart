import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/core/formatting/app_money_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/features/requests/presentation/widgets/photo_picker_field.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step six: everything the customer chose, before anything is sent.
///
/// Each line is read back from the draft, not re-derived. If a line here is
/// wrong, the booking would have been wrong — which is the point of showing
/// it.
class BookingSummaryScreen extends ConsumerStatefulWidget {
  const BookingSummaryScreen({super.key});

  @override
  ConsumerState<BookingSummaryScreen> createState() =>
      _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends ConsumerState<BookingSummaryScreen> {
  bool _isSending = false;

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      final result = await ref.read(bookingProvider.notifier).submit();
      if (!mounted) return;
      context.pushReplacement(
        AppRoutes.bookingDone(result.requestId),
        extra: result.photosNotSent,
      );
    } catch (error) {
      if (mounted) {
        setState(() => _isSending = false);
        showFailureSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final draft = ref.watch(bookingProvider);

    final service = draft.service;
    final provider = draft.provider;
    final price = draft.price;
    final wantedAt = draft.wantedAt;

    // Reaching this screen without a complete draft would be a bug in the
    // flow. Showing nothing beats showing half a booking.
    if (service == null ||
        provider == null ||
        price == null ||
        wantedAt == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.bookingSummaryTitle)),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingSummaryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.bookingYourJob, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _Line(
                    label: l10n.bookingLabelService,
                    value: service.nameFor(language),
                  ),
                  _Line(
                    label: l10n.bookingLabelProvider,
                    value: provider.displayName ?? l10n.providerUnnamed,
                  ),
                  _Line(label: l10n.bookingLabelOption, value: price.name),
                  _Line(
                    label: l10n.bookingLabelPlace,
                    value: [
                      if (draft.address.trim().isNotEmpty) draft.address.trim(),
                      if (draft.placeLabel.isNotEmpty) draft.placeLabel,
                    ].join('\n'),
                  ),
                  _Line(
                    label: l10n.bookingLabelWhen,
                    value: formatDateTime(wantedAt),
                  ),
                  _Line(
                    label: l10n.bookingLabelPrice,
                    value: formatCents(
                      price.priceCents,
                      currency: price.currency,
                    ),
                    emphasised: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Last stop before sending, which is where somebody reaches for a
          // photo: they have just read back what they are about to ask for.
          Text(l10n.photosLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.photosHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PhotoPickerField(
            photos: draft.photos,
            onAdd: ref.read(bookingProvider.notifier).addPhoto,
            onRemove: ref.read(bookingProvider.notifier).removePhoto,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.bookingSummaryDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _isSending ? null : _send,
            child: _isSending ? const ButtonProgress() : Text(l10n.bookingSend),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: emphasised
                  ? theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
