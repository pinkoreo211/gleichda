import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/l10n/app_localizations.dart';

/// Renders the three states every catalog screen has to handle — loading,
/// failed, loaded — so no screen forgets one and they all word it the same.
///
/// [onRetry] usually invalidates the provider the value came from.
class CatalogAsync<T> extends StatelessWidget {
  const CatalogAsync({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return value.when(
      data: builder,
      loading: () => _Loading(label: l10n.catalogLoading),
      // The underlying failure is already logged; the customer only needs a
      // way forward.
      error: (_, _) => ErrorState(
        message: l10n.catalogErrorMessage,
        retryLabel: l10n.catalogRetry,
        onRetry: onRetry,
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
