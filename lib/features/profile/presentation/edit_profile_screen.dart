import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/media/media_picker.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/avatar.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/design_system/widgets/error_state.dart';
import 'package:app/features/profile/application/my_display_name.dart';
import 'package:app/features/profile/data/profile_repository.dart';
import 'package:app/features/profile/domain/user_profile.dart';
import 'package:app/l10n/app_localizations.dart';

/// Where someone says who they are.
///
/// Two things only: a name and a picture. Both are what the person on the
/// other side of a job sees — a provider deciding whether to go to a
/// stranger's flat, a customer deciding whether to let one in. Neither is
/// required, and the screen says plainly what happens if they are left
/// empty rather than nagging.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEdit)),
      body: switch (ref.watch(myProfileProvider)) {
        AsyncData(:final value) => _Form(profile: value),
        AsyncError() => ErrorState(
          message: l10n.profileLoadFailed,
          retryLabel: l10n.actionRetry,
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final TextEditingController _name;
  bool _isSaving = false;
  bool _isChangingPicture = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPicture(MediaSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _isChangingPicture = true);
    try {
      final picture = await ref.read(mediaPickerProvider).pick(source);
      if (picture != null) {
        await ref.read(profileRepositoryProvider).saveAvatar(picture);
        ref.invalidate(myProfileProvider);
        ref.invalidate(myDisplayNameProvider);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.profilePictureSaved)),
        );
      }
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isChangingPicture = false);
  }

  Future<void> _removePicture() async {
    setState(() => _isChangingPicture = true);
    try {
      await ref.read(profileRepositoryProvider).removeAvatar();
      ref.invalidate(myProfileProvider);
      ref.invalidate(myDisplayNameProvider);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
    if (mounted) setState(() => _isChangingPicture = false);
  }

  Future<void> _choosePictureSource() async {
    final l10n = AppLocalizations.of(context);
    final hasPicture = widget.profile.hasAvatar;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.profilePictureCamera),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.profilePictureGallery),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            if (hasPicture)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.profilePictureRemove),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'camera':
        await _pickPicture(MediaSource.camera);
      case 'gallery':
        await _pickPicture(MediaSource.gallery);
      case 'remove':
        await _removePicture();
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).saveDisplayName(_name.text);
      ref.invalidate(myProfileProvider);
      ref.invalidate(myDisplayNameProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        showFailureSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Avatar(
                    imageUrl: profile.avatarUrl,
                    name: _name.text.isEmpty ? profile.displayName : _name.text,
                    size: AppAvatarSize.lg,
                  ),
                  if (_isChangingPicture)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _isChangingPicture ? null : _choosePictureSource,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  profile.hasAvatar
                      ? l10n.profilePictureChange
                      : l10n.profilePictureAdd,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: l10n.profileNameLabel,
            helperText: l10n.profileNameHelp,
            helperMaxLines: 3,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        // Said once, plainly, where the choice is made — not buried in a
        // policy nobody reads.
        Text(
          l10n.profileVisibilityNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const ButtonProgress() : Text(l10n.profileSave),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
