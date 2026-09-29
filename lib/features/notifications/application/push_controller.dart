import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/routing/app_router.dart';
import 'package:app/core/routing/app_routes.dart';
import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/jobs/application/incoming_requests.dart';
import 'package:app/features/jobs/application/my_jobs.dart';
import 'package:app/features/notifications/data/push_service.dart';
import 'package:app/features/session/application/active_role_controller.dart';
import 'package:app/features/session/domain/app_role.dart';
import 'package:app/features/notifications/data/push_token_repository.dart';
import 'package:app/features/notifications/domain/push_message.dart';
import 'package:app/features/requests/application/my_requests.dart';

/// The job a notification asked the app to open.
///
/// Set when a push is tapped and cleared once the list has shown it, so
/// coming back to that screen later does not highlight an old job again.
final highlightedJobProvider = NotifierProvider<HighlightedJob, String?>(
  HighlightedJob.new,
);

class HighlightedJob extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String contactId) => state = contactId;

  void clear() => state = null;
}

/// Keeps this device registered for notifications, and reacts when one is
/// tapped.
///
/// Deliberately quiet about failures. A person who declined notifications,
/// a build with no push provider, a token the backend refused — all of
/// them mean the same thing to the rest of the app: no push arrives, and
/// everything else works exactly as before.
class PushController extends Notifier<PushState> {
  StreamSubscription<String>? _tokens;
  StreamSubscription<PushMessage>? _opened;
  StreamSubscription<PushMessage>? _received;
  String? _registered;

  @override
  PushState build() {
    final service = ref.watch(pushServiceProvider);
    if (!service.isAvailable) return const PushState();

    _opened = service.opened.listen(_handle);
    _tokens = service.tokenChanges.listen(_register);
    // Arriving while the app is open shows nothing by itself, so the app
    // says it the better way: the list it was about reloads, and the new
    // request is simply there.
    _received = service.received.listen((_) => _refreshLists());
    ref.onDispose(() {
      _tokens?.cancel();
      _opened?.cancel();
      _received?.cancel();
    });

    // A notification that started the app from cold has no stream to
    // arrive on: nobody was listening yet when it was tapped.
    unawaited(
      service.initialMessage().then((message) {
        if (message != null) _handle(message);
      }),
    );

    // Someone who already said yes should not be asked again, and their
    // device should be registered as soon as they are signed in.
    unawaited(_registerIfAllowed());

    return const PushState(isSupported: true);
  }

  Future<void> _registerIfAllowed() async {
    final service = ref.read(pushServiceProvider);
    if (!await service.hasPermission()) return;
    final token = await service.currentToken();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    // Nothing to register a device to while signed out.
    if (ref.read(currentUserIdProvider) == null) return;
    if (_registered == token) return;
    try {
      await ref.read(pushTokenRepositoryProvider).register(token);
      _registered = token;
      state = state.copyWith(isRegistered: true);
    } catch (error) {
      // Not the person's problem: they did nothing wrong and there is
      // nothing for them to do about it.
      debugPrint('Could not register for notifications: $error');
    }
  }

  void _handle(PushMessage message) {
    // Whatever the notification was about has changed on the server, so
    // both lists are re-read rather than guessed at from its text.
    _refreshLists();
    if (!message.opensAJob) return;

    ref.read(highlightedJobProvider.notifier).show(message.contactId!);
    _openJobList();
  }

  /// Goes to wherever this person's jobs are.
  ///
  /// A provider's jobs are the screen their app opens on anyway, but a
  /// customer's are a tab away — without this, tapping "your request was
  /// accepted" would drop them on the home screen to go looking for it.
  void _openJobList() {
    final role = ref.read(activeRoleProvider);
    if (role == null) return;
    try {
      ref.read(appRouterProvider).go(switch (role) {
        AppRole.customer => AppRoutes.customerBookings,
        AppRole.provider => AppRoutes.providerJobs,
      });
    } catch (error) {
      // The router is not ready, or the person is signed out. The
      // highlight is set either way, so the job is marked once they get
      // there themselves.
      debugPrint('Could not open the job a notification was about: $error');
    }
  }

  void _refreshLists() {
    ref.invalidate(myIncomingRequestsProvider);
    ref.invalidate(myJobsProvider);
    // The customer's own request list too: "one provider accepted" is
    // written there, and on that screen it is the list the jobs sit
    // inside. Leaving it stale would show yesterday's answer above
    // today's job.
    ref.invalidate(myRequestsProvider);
  }

  /// Asks for permission, at a moment where the reason is obvious.
  ///
  /// Called when someone reaches a screen where a notification would
  /// actually matter — a provider's job list, or right after a customer
  /// sent a booking — rather than on the first launch, where there is
  /// nothing yet to be notified about and "no" is the easy answer.
  ///
  /// Asking twice does nothing: the operating system only shows its
  /// dialog once, and after that this just reads the answer.
  Future<void> askIfNeeded() async {
    final service = ref.read(pushServiceProvider);
    if (!service.isAvailable || state.hasAsked) return;
    state = state.copyWith(hasAsked: true);

    try {
      final allowed = await service.requestPermission();
      state = state.copyWith(isAllowed: allowed);
      if (!allowed) return;
      final token = await service.currentToken();
      if (token != null) await _register(token);
    } catch (error) {
      debugPrint('Could not ask about notifications: $error');
    }
  }

  /// Called before signing out, so the next person on this phone does not
  /// get the last one's notifications.
  Future<void> forgetThisDevice() async {
    final token =
        _registered ?? await ref.read(pushServiceProvider).currentToken();
    _registered = null;
    state = state.copyWith(isRegistered: false);
    if (token == null) return;
    try {
      await ref.read(pushTokenRepositoryProvider).forget(token);
    } catch (error) {
      debugPrint('Could not unregister this device: $error');
    }
  }
}

/// What the app knows about notifications on this device.
class PushState {
  const PushState({
    this.isSupported = false,
    this.hasAsked = false,
    this.isAllowed = false,
    this.isRegistered = false,
  });

  /// False on a build with no push provider configured.
  final bool isSupported;
  final bool hasAsked;
  final bool isAllowed;
  final bool isRegistered;

  PushState copyWith({
    bool? isSupported,
    bool? hasAsked,
    bool? isAllowed,
    bool? isRegistered,
  }) => PushState(
    isSupported: isSupported ?? this.isSupported,
    hasAsked: hasAsked ?? this.hasAsked,
    isAllowed: isAllowed ?? this.isAllowed,
    isRegistered: isRegistered ?? this.isRegistered,
  );
}

final pushProvider = NotifierProvider<PushController, PushState>(
  PushController.new,
);
