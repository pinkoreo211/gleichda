import 'dart:typed_data';

/// A file the provider chose, already read into memory.
///
/// Deliberately not an `XFile` or a platform path: the repository and the
/// tests only ever see bytes and a name, so nothing below this line has to
/// know whether it came from the camera, the gallery or a file browser.
class PickedDocument {
  const PickedDocument({
    required this.fileName,
    required this.bytes,
    this.displayName,
  });

  /// The technical name, used only for the extension and the content type.
  /// Never shown: a photo comes back from the picker called something like
  /// `scaled_53.png`, which tells the provider nothing.
  final String fileName;

  /// What to show the provider, when there is something worth showing.
  ///
  /// A file they chose by name ("Gewerbeschein.pdf") has one. A photo they
  /// just took does not, and the card says the document type and the date
  /// anyway — which is more than a made-up name would.
  final String? displayName;

  final Uint8List bytes;

  int get sizeInBytes => bytes.length;

  /// Lower-case, without the dot. Empty when the name has no extension.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// What to tell storage the file is. Guessed from the extension, because
  /// that is the one thing every source of a file agrees on.
  String get contentType => switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
