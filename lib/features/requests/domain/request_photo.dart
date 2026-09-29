/// One photo on a request, ready to put on screen.
///
/// Deliberately not the storage path. The bucket is private, so a path is
/// no use to anybody without permission anyway — and a screen that only
/// ever holds a link it was handed cannot go looking for a photo it was
/// not given.
class RequestPhoto {
  const RequestPhoto({required this.id, required this.url});

  final String id;

  /// A link that stops working after a while.
  ///
  /// Not a permanent address: one of those would be a copy of somebody's
  /// kitchen left lying in the open, for as long as anyone kept the link.
  final String url;
}
