import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step two: where the work is.
///
/// The town is what matching uses today, so it is the one required field.
/// The street is for the person who will ring the doorbell, and it reaches
/// the provider only once they have accepted the job.
///
/// There is no "use my current location" yet: nothing in the app reads the
/// device's position, and a button that silently did nothing would be
/// worse than no button. The coordinates the backend keeps room for stay
/// empty until that exists.
class BookingLocationScreen extends ConsumerStatefulWidget {
  const BookingLocationScreen({super.key});

  @override
  ConsumerState<BookingLocationScreen> createState() =>
      _BookingLocationScreenState();
}

class _BookingLocationScreenState extends ConsumerState<BookingLocationScreen> {
  late final TextEditingController _address;
  late final TextEditingController _postalCode;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    // Coming back to this screen shows what was entered before.
    final draft = ref.read(bookingProvider);
    _address = TextEditingController(text: draft.address);
    _postalCode = TextEditingController(text: draft.postalCode);
    _city = TextEditingController(text: draft.city);
  }

  @override
  void dispose() {
    _address.dispose();
    _postalCode.dispose();
    _city.dispose();
    super.dispose();
  }

  void _continue() {
    ref
        .read(bookingProvider.notifier)
        .setPlace(
          address: _address.text.trim(),
          postalCode: _postalCode.text.trim(),
          city: _city.text.trim(),
        );
    context.push(AppRoutes.bookingProviders);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.bookingWhereTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.bookingWhereHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.bookingAddressLabel),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _postalCode,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.bookingPostalCodeLabel,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _city,
                  builder: (context, value, _) => TextField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.bookingCityLabel,
                      // Says why the button below is disabled, rather than
                      // leaving the customer to work it out.
                      helperText: value.text.trim().isEmpty
                          ? l10n.bookingCityRequired
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _city,
            builder: (context, value, _) => FilledButton(
              onPressed: value.text.trim().isEmpty ? null : _continue,
              child: Text(l10n.bookingFindProviders),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
