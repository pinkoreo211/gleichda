import 'dart:async' show TimeoutException;

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

  /// A message with nothing in it. Caught in the app so the round trip is
  /// not spent to be told the obvious.
  messageEmpty,

  /// Somebody answered this request before this tap arrived — from another
  /// device, or from a screen that had not refreshed yet.
  requestAlreadyAnswered,

  /// The team has taken this document in hand, so the provider can no
  /// longer swap it out.
  documentLocked,

  /// The request never came back. Shown rather than left as a spinner:
  /// a person watching one forever has no way to tell a slow connection
  /// from a broken app.
  timedOut,

  /// Caught in the app: uploading it would only waste the provider's data
  /// to be told the same thing.
  documentTooLarge,
  documentTypeNotAllowed,

  /// The request already carries as many photos as it may. The app stops
  /// offering the button at that point, so this is the backend holding the
  /// same line against a second device, or a very fast thumb.
  tooManyPhotos,
  unknown;

  static AppFailure fromError(Object error) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) return timedOut;
    if (error is PostgrestException &&
        error.message.contains('already answered')) {
      return requestAlreadyAnswered;
    }
    if (error is PostgrestException &&
        error.message.contains('already being checked')) {
      return documentLocked;
    }
    if (error is PostgrestException &&
        error.message.contains('at most six photos')) {
      return tooManyPhotos;
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
