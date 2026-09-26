import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:app/features/notifications/data/push_service.dart';
import 'package:app/features/notifications/domain/push_message.dart';

/// What runs on a phone: Firebase Cloud Messaging.
///
/// Every method here can fail — no network, no Google Play services, a
/// person who said no — and none of those are the app's problem to solve.
/// They all end the same way: no token, so no push. The rest of the app
/// already handles that, because [NoPushService] behaves identically.
class FirebasePushService implements PushService {
  FirebasePushService(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      return _isAllowed(settings.authorizationStatus);
    } catch (error) {
      debugPrint('Asking for notification permission failed: $error');
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return _isAllowed(settings.authorizationStatus);
    } catch (error) {
      return false;
    }
  }

  /// `provisional` is Apple's quiet permission: notifications arrive, but
  /// only in the notification centre. Still a yes.
  static bool _isAllowed(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  @override
  Future<String?> currentToken() async {
    try {
      return await _messaging.getToken();
    } catch (error) {
      // Common and harmless: a device with no Play services, or no network
      // on first launch. The token arrives later through [tokenChanges].
      debugPrint('No push token available: $error');
      return null;
    }
  }

  @override
  Stream<String> get tokenChanges => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(_toMessage);

  @override
  Future<PushMessage?> initialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message == null ? null : _toMessage(message);
    } catch (error) {
      return null;
    }
  }

  @override
  Stream<PushMessage> get received =>
      FirebaseMessaging.onMessage.map(_toMessage);

  static PushMessage _toMessage(RemoteMessage message) =>
      PushMessage.fromData(message.data);
}
