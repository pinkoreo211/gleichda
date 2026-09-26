import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/formatting/app_date_format.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/provider/domain/provider_profile.dart';
import 'package:app/features/provider/presentation/widgets/verification_badge.dart';
import 'package:app/features/verification/application/my_verification.dart';
import 'package:app/features/verification/data/document_picker.dart';
import 'package:app/features/verification/domain/provider_document.dart';
import 'package:app/features/verification/presentation/widgets/document_labels.dart';
import 'package:app/l10n/app_localizations.dart';

/// Where a provider hands in their proof.
///
/// It shows what is asked of them, what they have sent, and what the team
/// made of it — and nothing else. Nothing on this screen can make anybody
/// verified: the upload starts a check, a person ends it.
class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providerVerificationTitle)),
      body: switch (ref.watch(myVerificationProvider)) {
        AsyncData(:final value) => _Checklist(checklist: value),
        AsyncError() => ErrorState(
          message: l10n.verificationLoadFailed,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(myVerificationProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Checklist extends ConsumerWidget {
  const _Checklist({required this.checklist});

  final VerificationChecklist checklist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (checklist.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            l10n.verificationNoProfile,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final status = switch (ref.watch(myProviderProfileProvider)) {
      AsyncData(:final value) => value?.verificationStatus,
      _ => null,
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProviderProfileProvider);
        ref.invalidate(myVerificationProvider);
        await ref.read(myVerificationProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.verificationHeadline, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.verificationIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.md),
            _OverallStatus(status: status),
          ],
          const SizedBox(height: AppSpacing.lg),
          for (final entry in checklist.entries) ...[
            _DocumentCard(entry: entry),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            checklist.allRequiredHandedIn
                ? l10n.verificationAllHandedIn
                : l10n.verificationMissing,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.verificationTeamNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Where the profile as a whole stands, straight from the backend.
class _OverallStatus extends StatelessWidget {
  const _OverallStatus({required this.status});

  final ProviderVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final color = status.isVerified
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(status.icon, size: AppIconSize.sm, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          status.label(l10n),
          style: theme.textTheme.labelLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// One kind of proof: what it is, what happened to it, and what the
/// provider can do about it now.
class _DocumentCard extends ConsumerWidget {
  const _DocumentCard({required this.entry});

  final VerificationEntry entry;

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    DocumentSource source,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uploaded = await ref
          .read(documentUploadProvider.notifier)
          .pickAndSubmit(type: entry.type, source: source);
      if (uploaded) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.verificationUploadDone)),
        );
      }
    } catch (error) {
      if (context.mounted) showFailureSnackBar(context, error);
    }
  }

  Future<void> _chooseSource(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<DocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.verificationSourceCamera),
              onTap: () => Navigator.pop(context, DocumentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.verificationSourceGallery),
              onTap: () => Navigator.pop(context, DocumentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.verificationSourceFile),
              onTap: () => Navigator.pop(context, DocumentSource.file),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    await _upload(context, ref, source);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final document = entry.document;
    final uploading = ref.watch(documentUploadProvider);
    final isUploadingThis = uploading == entry.type;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  entry.type.icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.type.label(l10n),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        entry.type.hint(l10n),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  entry.isRequired
                      ? l10n.verificationRequired
                      : l10n.verificationOptional,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (document == null)
              Text(
                l10n.verificationNotUploaded,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              _HandedIn(document: document),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: _UploadButton(
                entry: entry,
                isUploading: isUploadingThis,
                // One upload at a time: the other cards go quiet while one
                // file is on its way.
                onPressed: uploading != null || !entry.canUpload
                    ? null
                    : () => _chooseSource(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the provider sent, and what became of it.
class _HandedIn extends StatelessWidget {
  const _HandedIn({required this.document});

  final ProviderDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = document.status;
    final color = status.color(theme.colorScheme);
    final reason = document.rejectionReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(status.icon, size: AppIconSize.sm, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                status.label(l10n),
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
        if (document.fileName case final name? when name.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.verificationUploadedOn(formatShortDate(document.uploadedAt)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        // Only shown when the team actually wrote one: "Ablehnungsgrund:"
        // with nothing after it would be worse than saying nothing.
        if (status.isRejected && reason != null && reason.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.verificationRejectionReason(reason),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// The one action per card. Its wording says what will happen: a first
/// upload, a replacement, or a second try after a rejection.
class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.entry,
    required this.isUploading,
    required this.onPressed,
  });

  final VerificationEntry entry;
  final bool isUploading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = entry.document?.status;

    final label = switch (status) {
      null => l10n.verificationUpload,
      ProviderDocumentStatus.rejected => l10n.verificationUploadNew,
      _ => l10n.verificationReplace,
    };

    if (isUploading) {
      return const FilledButton(
        onPressed: null,
        child: SizedBox.square(
          dimension: AppIconSize.md,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // A first upload is the thing to do here; replacing one is not, so it
    // does not get the loud button.
    return status == null || status == ProviderDocumentStatus.rejected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}
