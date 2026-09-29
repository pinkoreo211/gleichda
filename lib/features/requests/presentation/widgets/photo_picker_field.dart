import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/core/media/media_picker.dart';
import 'package:app/core/media/picked_media.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/requests/data/request_photo_repository.dart';
import 'package:app/features/requests/presentation/photo_viewer_screen.dart';
import 'package:app/l10n/app_localizations.dart';

/// Picks the photos that will go with a request, wherever a request is
/// written.
///
/// Holds nothing itself: the caller keeps the list and says what happens
/// when one is added or taken back. Both ways into a request — the
/// fixed-price booking and the open request — hand it the same two
/// callbacks, so they behave identically without either owning the other.
///
/// Everything here stays in memory. Nothing is uploaded until the request
/// exists, so backing out leaves no picture of anybody's flat behind, and
/// taking one off before sending costs nothing at all.
///
/// Says out loud who will be able to see them. That belongs on the screen
/// where somebody decides, not in a policy they will never read.
class PhotoPickerField extends ConsumerStatefulWidget {
  const PhotoPickerField({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<PickedMedia> photos;
  final ValueChanged<PickedMedia> onAdd;
  final ValueChanged<int> onRemove;

  @override
  ConsumerState<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends ConsumerState<PhotoPickerField> {
  static const double _tile = 80;

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);

    final source = await showModalBottomSheet<MediaSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.photosFromCamera),
              onTap: () => Navigator.pop(context, MediaSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photosFromGallery),
              onTap: () => Navigator.pop(context, MediaSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final photo = await ref.read(mediaPickerProvider).pick(source);
      // Null means they backed out of the camera or the gallery, which is
      // not something to tell them about.
      if (photo == null || !mounted) return;

      // Checked here rather than at upload time: that happens after the
      // request was sent, and being told then would be too late to do
      // anything about it.
      if (photo.sizeInBytes > maxRequestPhotoBytes) {
        showFailureSnackBar(context, AppFailure.documentTooLarge);
        return;
      }

      widget.onAdd(photo);
    } catch (error) {
      if (mounted) showFailureSnackBar(context, error);
    }
  }

  void _open(int index) => PhotoViewerScreen.open(
    context,
    images: [for (final photo in widget.photos) MemoryImage(photo.bytes)],
    initialIndex: index,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photos = widget.photos;
    final canAddMore = photos.length < maxRequestPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _tile,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + (canAddMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == photos.length) {
                return _AddTile(
                  size: _tile,
                  label: l10n.photosAdd,
                  onTap: _add,
                );
              }
              return _ChosenPhoto(
                size: _tile,
                photo: photos[index],
                removeLabel: l10n.photosRemove,
                onOpen: () => _open(index),
                onRemove: () => widget.onRemove(index),
              );
            },
          ),
        ),
        // Only worth saying once there is something to be seen.
        if (photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.photosPrivacy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.size,
    required this.label,
    required this.onTap,
  });

  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(AppRadius.sm));

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(
            Icons.add_a_photo_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ChosenPhoto extends StatelessWidget {
  const _ChosenPhoto({
    required this.size,
    required this.photo,
    required this.removeLabel,
    required this.onOpen,
    required this.onRemove,
  });

  final double size;
  final PickedMedia photo;
  final String removeLabel;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(AppRadius.sm));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: onOpen,
              borderRadius: radius,
              child: ClipRRect(
                borderRadius: radius,
                child: Image.memory(
                  photo.bytes,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  // A file the phone handed over but nothing can decode.
                  // Still shown as a tile, so it can be taken back off — an
                  // empty gap with an X floating over it would be worse
                  // than a plain square.
                  errorBuilder: (context, error, stack) => Container(
                    width: size,
                    height: size,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Semantics(
              button: true,
              label: removeLabel,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: AppIconSize.sm,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
