import 'package:material_ui/material_ui.dart';

import 'package:app/l10n/app_localizations.dart';

/// One photo, as large as the screen allows, with the others a swipe away.
///
/// Takes image providers rather than links, so the same screen shows a
/// photo that is still only in this phone's memory and one that came back
/// from storage behind a link. Neither the viewer nor anything below it has
/// to know which is which.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    required this.images,
    this.initialIndex = 0,
    super.key,
  });

  final List<ImageProvider> images;
  final int initialIndex;

  /// Opens the viewer over whatever is on screen.
  static Future<void> open(
    BuildContext context, {
    required List<ImageProvider> images,
    int initialIndex = 0,
  }) {
    if (images.isEmpty) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            PhotoViewerScreen(images: images, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _current = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = widget.images.length;

    // Black rather than the app's cream: a photo is easier to judge
    // against nothing at all, and this screen is only ever the photo.
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        // Only worth saying when there is more than one to be lost among.
        title: total > 1
            ? Text(l10n.photosPosition(_current + 1, total))
            : null,
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: total,
        onPageChanged: (index) => setState(() => _current = index),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image(
              image: widget.images[index],
              fit: BoxFit.contain,
              // A link that has expired, or a photo that will not decode.
              // Says so quietly instead of showing a broken frame.
              errorBuilder: (context, error, stack) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
