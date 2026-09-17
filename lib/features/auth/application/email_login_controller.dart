import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/domain/email_address.dart';

enum EmailLoginStep { enterEmail, enterCode }

class EmailLoginState {
  const EmailLoginState({
    this.step = EmailLoginStep.enterEmail,
    this.email = '',
    this.isBusy = false,
    this.failure,
  });

  final EmailLoginStep step;
  final String email;
  final bool isBusy;
  final AppFailure? failure;
}

/// Drives the two login steps: enter email → enter the code from the email.
/// After a successful verification the router leaves the login screen.
final emailLoginControllerProvider =
    NotifierProvider.autoDispose<EmailLoginController, EmailLoginState>(
      EmailLoginController.new,
    );

class EmailLoginController extends Notifier<EmailLoginState> {
  @override
  EmailLoginState build() => const EmailLoginState();

  /// Returns `true` if a code was sent.
  Future<bool> sendCode(String email) async {
    final address = email.trim();
    if (!isPlausibleEmailAddress(address)) {
      state = EmailLoginState(
        step: state.step,
        email: address,
        failure: AppFailure.invalidEmail,
      );
      return false;
    }

    state = EmailLoginState(step: state.step, email: address, isBusy: true);
    try {
      await ref.read(authRepositoryProvider).sendEmailCode(address);
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = EmailLoginState(
          step: state.step,
          email: address,
          failure: failure,
        );
      }
      return false;
    }
    if (ref.mounted) {
      state = EmailLoginState(step: EmailLoginStep.enterCode, email: address);
    }
    return true;
  }

  Future<void> verifyCode(String code) async {
    final email = state.email;
    state = EmailLoginState(
      step: EmailLoginStep.enterCode,
      email: email,
      isBusy: true,
    );
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmailCode(email: email, code: code.trim());
    } on AppFailure catch (failure) {
      if (ref.mounted) {
        state = EmailLoginState(
          step: EmailLoginStep.enterCode,
          email: email,
          failure: failure,
        );
      }
    }
  }

  /// Back from the code step to the email step, keeping the typed address.
  void changeEmail() => state = EmailLoginState(email: state.email);
}
