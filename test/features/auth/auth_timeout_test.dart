import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/errors/app_failure.dart';

/// A request that never comes back must not leave a spinner running.
///
/// This is here because it happened: a sign-in on a fresh device hung for
/// minutes with no message and no way out but to kill the app. The client
/// has no limit of its own, so the repository has to impose one — and a
/// timeout has to arrive as something the screen can say out loud, not as
/// a generic failure.
void main() {
  test('a request that never returns becomes a timeout, not a mystery', () {
    final neverFinishes = Completer<void>().future;

    expect(() async {
      try {
        await neverFinishes.timeout(const Duration(milliseconds: 10));
      } catch (error) {
        throw AppFailure.fromError(error);
      }
    }, throwsA(AppFailure.timedOut));
  });

  test('a timeout is not lumped in with everything else', () {
    // `unknown` reads as "something went wrong"; a timeout can be acted on
    // — check the connection and try again — so it says so.
    expect(
      AppFailure.fromError(TimeoutException('too slow')),
      AppFailure.timedOut,
    );
    expect(
      AppFailure.fromError(StateError('something else')),
      AppFailure.unknown,
    );
  });

  test('errors that already have a meaning keep it', () {
    // The timeout check must not swallow the cases above it.
    expect(
      AppFailure.fromError(AppFailure.invalidOrExpiredCode),
      AppFailure.invalidOrExpiredCode,
    );
    expect(
      AppFailure.fromError(const AuthException('expired', code: 'otp_expired')),
      AppFailure.invalidOrExpiredCode,
    );
  });
}
