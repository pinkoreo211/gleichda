// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline => 'Need someone? Right there.';

  @override
  String get welcomeSubtitle =>
      'Verified service providers near you – found fast, booked easily.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String roleSelectionTitle(String appName) {
    return 'How do you want to use $appName?';
  }

  @override
  String get roleCustomerTitle => 'I need a service';

  @override
  String get roleCustomerDescription =>
      'Find, book and pay verified pros near you.';

  @override
  String get roleProviderTitle => 'I offer services';

  @override
  String get roleProviderDescription =>
      'Get jobs in your area, send offers and earn.';

  @override
  String get roleSwitchHint => 'You can switch modes anytime in your profile.';

  @override
  String get roleSelectionContinue => 'Continue';

  @override
  String get roleCustomerModeName => 'Customer mode';

  @override
  String get roleProviderModeName => 'Provider mode';

  @override
  String get tabHome => 'Home';

  @override
  String get tabBookings => 'Bookings';

  @override
  String get tabMessages => 'Chats';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabJobs => 'Jobs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabEarnings => 'Earnings';

  @override
  String get customerHomeTitle => 'What do you need?';

  @override
  String get customerHomeMessage =>
      'Soon you can describe what you need or pick a category – and find verified pros near you.';

  @override
  String get customerBookingsEmptyTitle => 'No bookings yet';

  @override
  String get customerBookingsEmptyMessage =>
      'Your bookings and projects will show up here with their current status.';

  @override
  String get conversationsEmptyTitle => 'No messages yet';

  @override
  String get conversationsEmptyMessage =>
      'All chats about your jobs will show up here.';

  @override
  String get providerJobsEmptyTitle => 'No jobs yet';

  @override
  String get providerJobsEmptyMessage =>
      'Once your profile is verified, matching requests and projects from your area will show up here.';

  @override
  String get availabilityTitle => 'Your availability';

  @override
  String get availabilityMessage =>
      'Soon you can set when you work and see your appointments here.';

  @override
  String get earningsEmptyTitle => 'No earnings yet';

  @override
  String get earningsEmptyMessage =>
      'Your completed jobs and payouts will show up here.';

  @override
  String get profileCurrentMode => 'Current mode';

  @override
  String get profileSwitchToProvider => 'Switch to provider mode';

  @override
  String get profileSwitchToCustomer => 'Switch to customer mode';

  @override
  String get profileAccountComingSoon =>
      'Personal details and settings are coming soon.';

  @override
  String get profileSignedInAs => 'Signed in as';

  @override
  String get signOut => 'Sign out';

  @override
  String get loginTitle => 'Sign in or sign up';

  @override
  String get loginEmailIntro =>
      'Enter your email address. We\'ll send you a code – no password needed.';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginSendCode => 'Send code';

  @override
  String get loginCodeTitle => 'Enter code';

  @override
  String loginCodeIntro(String email) {
    return 'We sent a code to $email. Please also check your spam folder.';
  }

  @override
  String get loginCodeLabel => 'Code from the email';

  @override
  String get loginVerifyCode => 'Confirm';

  @override
  String get loginResendCode => 'Resend code';

  @override
  String get loginCodeResent => 'A new code is on its way.';

  @override
  String get loginChangeEmail => 'Use a different email address';

  @override
  String get errorInvalidEmail => 'Please enter a valid email address.';

  @override
  String get errorInvalidOrExpiredCode =>
      'The code is wrong or has expired. Request a new one if needed.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorEmailNotAuthorized =>
      'We can\'t send emails to this address at the moment.';

  @override
  String get errorUnknown =>
      'That didn\'t work. Please check your internet connection and try again.';
}
