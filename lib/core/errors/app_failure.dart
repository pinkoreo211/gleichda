import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errors the UI knows how to explain to the user. Repositories translate
/// backend errors into these, so screens never deal with Supabase types.
enum AppFailure implements Exception {
  invalidEmail,
  invalidOrExpiredCode,
  tooManyRequests,

  /// The default Supabase email service only sends to team members' addresses.
  emailNotAuthorized,

  /// Somebody answered this request before this tap arrived — from another
  /// device, or from a screen that had not refreshed yet.
  requestAlreadyAnswered,
  unknown;

  static AppFailure fromError(Object error) {
    if (error is AppFailure) return error;
    if (error is PostgrestException &&
        error.message.contains('already answered')) {
      return requestAlreadyAnswered;
    }
    if (error is AuthException) {
      switch (error.code) {
        case 'otp_expired':
          return invalidOrExpiredCode;
        case 'over_email_send_rate_limit' || 'over_request_rate_limit':
          return tooManyRequests;
        case 'email_address_invalid' || 'validation_failed':
          return invalidEmail;
        case 'email_address_not_authorized':
          return emailNotAuthorized;
      }
      if (error.statusCode == '429') return tooManyRequests;
    }
    debugPrint('Unexpected backend error: $error');
    return unknown;
  }
}
