import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app/core/errors/app_failure_message.dart';
import 'package:app/design_system/app_dimensions.dart';
import 'package:app/design_system/widgets/button_progress.dart';
import 'package:app/features/auth/application/email_login_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Passwordless sign-in and sign-up: email address → code from the email.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  EmailLoginController get _controller =>
      ref.read(emailLoginControllerProvider.notifier);

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() => _controller.sendCode(_emailController.text);

  Future<void> _verifyCode() => _controller.verifyCode(_codeController.text);

  Future<void> _resendCode() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final email = ref.read(emailLoginControllerProvider).email;
    if (await _controller.sendCode(email)) {
      _codeController.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.loginCodeResent)));
    }
  }

  void _changeEmail() {
    _codeController.clear();
    _controller.changeEmail();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final login = ref.watch(emailLoginControllerProvider);
    final isCodeStep = login.step == EmailLoginStep.enterCode;
    final errorText = login.failure?.message(l10n);

    return PopScope(
      // In the code step, "back" returns to the email step.
      canPop: !isCodeStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _changeEmail();
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: isCodeStep
                        ? _codeStep(l10n, login, errorText)
                        : _emailStep(l10n, login, errorText),
                  ),
                ),
                FilledButton(
                  onPressed: login.isBusy
                      ? null
                      : (isCodeStep ? _verifyCode : _sendCode),
                  child: login.isBusy
                      ? const ButtonProgress()
                      : Text(
                          isCodeStep
                              ? l10n.loginVerifyCode
                              : l10n.loginSendCode,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _emailStep(
    AppLocalizations l10n,
    EmailLoginState login,
    String? errorText,
  ) {
    return [
      _Heading(title: l10n.loginTitle, intro: l10n.loginEmailIntro),
      TextField(
        key: const ValueKey('email'),
        controller: _emailController,
        enabled: !login.isBusy,
        autofocus: true,
        autocorrect: false,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendCode(),
        decoration: InputDecoration(
          labelText: l10n.loginEmailLabel,
          errorText: errorText,
          errorMaxLines: 3,
        ),
      ),
    ];
  }

  List<Widget> _codeStep(
    AppLocalizations l10n,
    EmailLoginState login,
    String? errorText,
  ) {
    return [
      _Heading(
        title: l10n.loginCodeTitle,
        intro: l10n.loginCodeIntro(login.email),
      ),
      TextField(
        key: const ValueKey('code'),
        controller: _codeController,
        enabled: !login.isBusy,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifyCode(),
        decoration: InputDecoration(
          labelText: l10n.loginCodeLabel,
          errorText: errorText,
          errorMaxLines: 3,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: login.isBusy ? null : _resendCode,
          child: Text(l10n.loginResendCode),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: login.isBusy ? null : _changeEmail,
          child: Text(l10n.loginChangeEmail),
        ),
      ),
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.intro});

  final String title;
  final String intro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            intro,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
