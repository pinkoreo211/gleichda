import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Brand slogan shown on the welcome screen.
  ///
  /// In de, this message translates to:
  /// **'Du brauchst wen? Gleich da.'**
  String get appTagline;

  /// Short explanation of the app below the slogan on the welcome screen.
  ///
  /// In de, this message translates to:
  /// **'Geprüfte Dienstleister in deiner Nähe – schnell gefunden, einfach gebucht.'**
  String get welcomeSubtitle;

  /// Primary button on the welcome screen that starts onboarding.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get welcomeGetStarted;

  /// Heading of the role selection screen.
  ///
  /// In de, this message translates to:
  /// **'Wie möchtest du {appName} nutzen?'**
  String roleSelectionTitle(String appName);

  /// Role option for customers on the role selection screen.
  ///
  /// In de, this message translates to:
  /// **'Ich brauche eine Dienstleistung'**
  String get roleCustomerTitle;

  /// Explanation below the customer role option.
  ///
  /// In de, this message translates to:
  /// **'Geprüfte Profis in deiner Nähe finden, buchen und bezahlen.'**
  String get roleCustomerDescription;

  /// Role option for service providers on the role selection screen.
  ///
  /// In de, this message translates to:
  /// **'Ich biete Dienstleistungen an'**
  String get roleProviderTitle;

  /// Explanation below the provider role option.
  ///
  /// In de, this message translates to:
  /// **'Aufträge in deiner Umgebung erhalten, Angebote senden und verdienen.'**
  String get roleProviderDescription;

  /// Hint below the role options that the choice is not final.
  ///
  /// In de, this message translates to:
  /// **'Du kannst den Modus später jederzeit im Profil wechseln.'**
  String get roleSwitchHint;

  /// Button that confirms the selected role.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get roleSelectionContinue;

  /// Name of the customer mode, shown in the profile.
  ///
  /// In de, this message translates to:
  /// **'Kundenmodus'**
  String get roleCustomerModeName;

  /// Name of the provider mode, shown in the profile.
  ///
  /// In de, this message translates to:
  /// **'Anbietermodus'**
  String get roleProviderModeName;

  /// Bottom navigation label: customer home.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get tabHome;

  /// Bottom navigation label: customer bookings.
  ///
  /// In de, this message translates to:
  /// **'Buchungen'**
  String get tabBookings;

  /// Bottom navigation label: chats (customer and provider). Keep short: the provider bar has five tabs.
  ///
  /// In de, this message translates to:
  /// **'Chats'**
  String get tabMessages;

  /// Bottom navigation label: profile (customer and provider).
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// Bottom navigation label: provider jobs.
  ///
  /// In de, this message translates to:
  /// **'Aufträge'**
  String get tabJobs;

  /// Bottom navigation label: provider availability and appointments.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get tabCalendar;

  /// Bottom navigation label: provider earnings, payouts and transactions. Keep short: the provider bar has five tabs.
  ///
  /// In de, this message translates to:
  /// **'Finanzen'**
  String get tabEarnings;

  /// Heading of the customer home screen (placeholder).
  ///
  /// In de, this message translates to:
  /// **'Was brauchst du?'**
  String get customerHomeTitle;

  /// Placeholder text on the customer home screen until search is built.
  ///
  /// In de, this message translates to:
  /// **'Bald beschreibst du hier dein Anliegen oder wählst eine Kategorie – und findest geprüfte Profis in deiner Nähe.'**
  String get customerHomeMessage;

  /// Empty state title on the customer bookings screen.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Buchungen'**
  String get customerBookingsEmptyTitle;

  /// Empty state text on the customer bookings screen.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du bald deine Buchungen und Projekte mit ihrem aktuellen Status.'**
  String get customerBookingsEmptyMessage;

  /// Empty state title on the messages screen.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get conversationsEmptyTitle;

  /// Empty state text on the messages screen.
  ///
  /// In de, this message translates to:
  /// **'Hier findest du bald alle Chats zu deinen Aufträgen.'**
  String get conversationsEmptyMessage;

  /// Empty state title on the provider jobs screen.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aufträge'**
  String get providerJobsEmptyTitle;

  /// Empty state text on the provider jobs screen.
  ///
  /// In de, this message translates to:
  /// **'Sobald dein Profil geprüft ist, erhältst du hier passende Anfragen und Projekte aus deiner Umgebung.'**
  String get providerJobsEmptyMessage;

  /// Heading on the provider calendar screen (placeholder).
  ///
  /// In de, this message translates to:
  /// **'Deine Verfügbarkeit'**
  String get availabilityTitle;

  /// Placeholder text on the provider calendar screen.
  ///
  /// In de, this message translates to:
  /// **'Hier legst du bald fest, wann du arbeitest, und siehst deine Termine.'**
  String get availabilityMessage;

  /// Empty state title on the provider earnings screen.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einnahmen'**
  String get earningsEmptyTitle;

  /// Empty state text on the provider earnings screen.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du bald deine abgeschlossenen Aufträge und Auszahlungen.'**
  String get earningsEmptyMessage;

  /// Label for the active mode in the profile.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Modus'**
  String get profileCurrentMode;

  /// Button in the profile that switches from customer to provider mode.
  ///
  /// In de, this message translates to:
  /// **'Zum Anbietermodus wechseln'**
  String get profileSwitchToProvider;

  /// Button in the profile that switches from provider to customer mode.
  ///
  /// In de, this message translates to:
  /// **'Zum Kundenmodus wechseln'**
  String get profileSwitchToCustomer;

  /// Placeholder note in the profile until accounts exist.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung, persönliche Daten und Einstellungen folgen in Kürze.'**
  String get profileAccountComingSoon;

  /// Debug-only button that resets the role and shows onboarding again.
  ///
  /// In de, this message translates to:
  /// **'Onboarding neu starten (nur Testversion)'**
  String get profileRestartOnboarding;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
