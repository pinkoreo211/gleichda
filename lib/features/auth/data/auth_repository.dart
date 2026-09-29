import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';

/// Passwordless sign-in with a one-time code sent by email.
///
/// All methods throw [AppFailure] on errors.
abstract interface class AuthRepository {
  String? get currentUserId;

  String? get currentEmail;

  /// Emits the signed-in user's id, or `null` after sign-out.
  Stream<String?> userIdChanges();

  /// Sends a one-time code. Creates the account if it does not exist yet.
  Future<void> sendEmailCode(String email);

  Future<void> verifyEmailCode({required String email, required String code});

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(ref.watch(supabaseClientProvider).auth),
);

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  /// How long to wait before calling it a failure.
  ///
  /// The client has no limit of its own: a request that never comes back
  /// leaves the person watching a spinner with no message and no way out
  /// but to kill the app. Thirty seconds is longer than a slow connection
  /// needs and short enough that nobody sits there wondering.
  static const _timeout = Duration(seconds: 30);

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Stream<String?> userIdChanges() =>
      _auth.onAuthStateChange.map((state) => state.session?.user.id);

  @override
  Future<void> sendEmailCode(String email) async {
    try {
      await _auth
          .signInWithOtp(email: email, shouldCreateUser: true)
          .timeout(_timeout);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      await _auth
          .verifyOTP(email: email, token: code, type: OtpType.email)
          .timeout(_timeout);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut().timeout(_timeout);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
