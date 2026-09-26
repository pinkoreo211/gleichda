import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/booking/application/booking_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Step five: when the customer would like it.
///
/// This is a wish, not a booking slot. Nothing in the system knows yet
/// whether the provider is free then, so the screen says so plainly rather
/// than showing "available" times it cannot stand behind. The provider
/// answers, and the appointment they agree on is recorded separately.
class BookingScheduleScreen extends ConsumerStatefulWidget {
  const BookingScheduleScreen({super.key});

  @override
  ConsumerState<BookingScheduleScreen> createState() =>
      _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends ConsumerState<BookingScheduleScreen> {
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    final wanted = ref.read(bookingProvider).wantedAt;
    if (wanted != null) {
      _date = DateTime(wanted.year, wanted.month, wanted.day);
      _time = TimeOfDay(hour: wanted.hour, minute: wanted.minute);
    }
  }

  DateTime? get _wantedAt {
    final date = _date;
    final time = _time;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      // Nothing in the past, and no bookings a year out: neither is a job
      // anybody is actually planning.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _continue() {
    ref.read(bookingProvider.notifier).chooseTime(_wantedAt!);
    context.push(AppRoutes.bookingSummary);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = _date;
    final time = _time;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.bookingWhenTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.bookingWhenHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.bookingDateLabel),
                  subtitle: Text(
                    date == null ? l10n.bookingNotChosen : formatLongDate(date),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(l10n.bookingTimeLabel),
                  subtitle: Text(
                    time == null
                        ? l10n.bookingNotChosen
                        : formatShortTime(
                            DateTime(2026, 1, 1, time.hour, time.minute),
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.bookingWhenDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _wantedAt == null ? null : _continue,
            child: Text(l10n.bookingToSummary),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
