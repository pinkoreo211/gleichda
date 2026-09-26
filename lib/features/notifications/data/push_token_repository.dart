import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';

/// Which devices the signed-in person can be reached on.
///
/// Write-only by design: the backend grants no read at all, because
/// nothing in the app needs to look a token up. Registering files this
/// device under the signed-in account and takes it off any other, so a
/// shared phone stops notifying whoever used it last.
///
/// Throws [AppFailure] on errors.
abstract interface class PushTokenRepository {
  Future<void> register(String token);

  /// On sign-out. Best effort: a device that could not be unregistered is
  /// not worth blocking a sign-out over.
  Future<void> forget(String token);
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => SupabasePushTokenRepository(ref.watch(supabaseClientProvider)),
);

class SupabasePushTokenRepository implements PushTokenRepository {
  SupabasePushTokenRepository(this._client);

  final SupabaseClient _client;

  /// What the backend records alongside the token. Only ever a platform
  /// name — nothing that identifies the device or the person.
  static String? get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  @override
  Future<void> register(String token) async {
    try {
      await _client.rpc<dynamic>(
        'register_push_token',
        params: {'device_token': token, 'device_platform': _platform},
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> forget(String token) async {
    try {
      await _client.rpc<dynamic>(
        'forget_push_token',
        params: {'device_token': token},
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
