import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/notifications/domain/push_message.dart';

/// The phone's side of push notifications.
///
/// Behind an interface for two reasons. Tests must never reach a real push
/// service, and the app has to keep working on a build with no push
/// provider configured at all — which is exactly what [NoPushService]
/// below is for.
abstract interface class PushService {
  /// Whether this build can receive pushes at all. False for
  /// [NoPushService], and then nothing else here is ever called.
  bool get isAvailable;

  /// Asks the person, if they have not been asked yet. Returns whether
  /// notifications are allowed now.
  ///
  /// Declining is a normal answer: everything else in the app carries on.
  Future<bool> requestPermission();

  /// Whether the person already said yes, without asking again.
  Future<bool> hasPermission();

  /// This device's address at the push service, or null when there is
  /// none — no permission, no network, or no provider configured.
  Future<String?> currentToken();

  /// Fires when the service issues a new address for this device. The old
  /// one stops working, so the app registers the new one and forgets the
  /// old.
  Stream<String> get tokenChanges;

  /// Notifications the person tapped, including the one that started the
  /// app from cold — [initialMessage] covers that case, because a stream
  /// has nobody listening yet while the app is still starting.
  Stream<PushMessage> get opened;

  Future<PushMessage?> initialMessage();

  /// Notifications that arrived while the app was open.
  ///
  /// The operating system shows nothing in that case, on the reasoning
  /// that the app can say it better itself. So it does: the list the
  /// notification was about reloads, and the new request is simply there.
  Stream<PushMessage> get received;
}

/// What the app uses until a push provider is configured, and in tests.
///
/// Says no to everything, quietly. Every caller already has to handle
/// "there is no token" — a person who declined notifications is the same
/// situation — so nothing downstream needs a special case for this.
class NoPushService implements PushService {
  const NoPushService();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenChanges => const Stream.empty();

  @override
  Stream<PushMessage> get opened => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;

  @override
  Stream<PushMessage> get received => const Stream.empty();
}

/// Replaced with the real implementation once a push provider is set up.
/// Everything above this line already works against it.
final pushServiceProvider = Provider<PushService>(
  (ref) => const NoPushService(),
);
