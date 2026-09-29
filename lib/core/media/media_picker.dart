import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/core/media/picked_media.dart';

/// Where a picture or a file comes from.
enum MediaSource { camera, gallery, file }

/// Asks the phone for a picture or a file. Kept behind an interface so screens can be
/// tested without a camera, a gallery or a file browser.
///
/// Returns null when the person backed out, which is not an error.
/// Throws [AppFailure] when something actually went wrong.
abstract interface class MediaPicker {
  Future<PickedMedia?> pick(MediaSource source);
}

final mediaPickerProvider = Provider<MediaPicker>(
  (ref) => const PlatformMediaPicker(),
);

class PlatformMediaPicker implements MediaPicker {
  const PlatformMediaPicker();

  @override
  Future<PickedMedia?> pick(MediaSource source) async {
    try {
      return switch (source) {
        MediaSource.camera => await _image(ImageSource.camera),
        MediaSource.gallery => await _image(ImageSource.gallery),
        MediaSource.file => await _file(),
      };
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  Future<PickedMedia?> _image(ImageSource source) async {
    // Scaled down on the way out: a document has to be readable, not
    // printable, and a 12-megapixel photo is a slow upload on mobile data.
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );
    if (file == null) return null;
    // No display name on purpose: scaling the photo down renames it, and
    // the generated name would mean nothing to the person who took it.
    return PickedMedia(fileName: file.name, bytes: await file.readAsBytes());
  }

  Future<PickedMedia?> _file() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
    );
    if (file == null) return null;
    // Read through the picker rather than from a path: on Android a picked
    // file often has no readable path of its own.
    return PickedMedia(
      fileName: file.name,
      // This one the provider picked by name, so it is worth showing back.
      displayName: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}
