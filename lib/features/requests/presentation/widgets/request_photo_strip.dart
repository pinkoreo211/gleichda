import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';
import 'package:app/features/requests/application/request_photos.dart';
import 'package:app/features/requests/presentation/photo_viewer_screen.dart';
import 'package:app/l10n/app_localizations.dart';

/// The photos on a request, as a row of thumbnails.
///
/// Takes up no room at all when there are none, which is most requests. It
/// also stays out of the way while loading and after a failure: these sit
/// inside cards in a scrolling list, and a card that grows a moment after
/// you started reading it is worse than a photo that appears quietly.
///
/// Safe on either side of a job. The backend decides who may see what, so
/// this never has to know whether it is the customer or the provider
/// looking.
class RequestPhotoStrip extends ConsumerWidget {
  const RequestPhotoStrip({required this.requestId, super.key});

  final String requestId;

  static const double _thumbnail = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(requestPhotosProvider(requestId)).value;
    if (photos == null || photos.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final images = [for (final photo in photos) NetworkImage(photo.url)];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SizedBox(
        height: _thumbnail,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) => _Thumbnail(
            image: images[index],
            label: l10n.photosOpen,
            onTap: () => PhotoViewerScreen.open(
              context,
              images: images,
              initialIndex: index,
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.image,
    required this.label,
    required this.onTap,
  });

  final ImageProvider image;
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
        child: ClipRRect(
          borderRadius: radius,
          child: Image(
            image: image,
            width: RequestPhotoStrip._thumbnail,
            height: RequestPhotoStrip._thumbnail,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              width: RequestPhotoStrip._thumbnail,
              height: RequestPhotoStrip._thumbnail,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
