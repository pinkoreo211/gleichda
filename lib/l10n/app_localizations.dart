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
  /// **'Noch keine Chats'**
  String get conversationsEmptyTitle;

  /// Empty state text on the messages screen, for a customer.
  ///
  /// In de, this message translates to:
  /// **'Sobald ein Dienstleister deine Anfrage annimmt, könnt ihr hier miteinander schreiben.'**
  String get conversationsEmptyCustomer;

  /// Empty state text on the messages screen, for a provider.
  ///
  /// In de, this message translates to:
  /// **'Sobald du eine Anfrage angenommen hast, kannst du hier mit der Kundin oder dem Kunden schreiben.'**
  String get conversationsEmptyProvider;

  /// Shown when the chat list could not be read.
  ///
  /// In de, this message translates to:
  /// **'Chats konnten nicht geladen werden.'**
  String get conversationsLoadFailed;

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

  /// Placeholder note in the profile until profile editing exists.
  ///
  /// In de, this message translates to:
  /// **'Persönliche Daten und Einstellungen folgen in Kürze.'**
  String get profileAccountComingSoon;

  /// Label above the signed-in email address in the profile.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet als'**
  String get profileSignedInAs;

  /// Button that signs the user out.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// Heading of the email step on the login screen. Works for new and existing users.
  ///
  /// In de, this message translates to:
  /// **'Anmelden oder registrieren'**
  String get loginTitle;

  /// Explanation on the email step of the login screen.
  ///
  /// In de, this message translates to:
  /// **'Gib deine E-Mail-Adresse ein. Wir schicken dir einen Code – ganz ohne Passwort.'**
  String get loginEmailIntro;

  /// Label of the email input field.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get loginEmailLabel;

  /// Button that sends the one-time code by email.
  ///
  /// In de, this message translates to:
  /// **'Code senden'**
  String get loginSendCode;

  /// Heading of the code step on the login screen.
  ///
  /// In de, this message translates to:
  /// **'Code eingeben'**
  String get loginCodeTitle;

  /// Explanation on the code step of the login screen.
  ///
  /// In de, this message translates to:
  /// **'Wir haben dir einen Code an {email} geschickt. Schau auch im Spam-Ordner nach.'**
  String loginCodeIntro(String email);

  /// Label of the one-time code input field.
  ///
  /// In de, this message translates to:
  /// **'Code aus der E-Mail'**
  String get loginCodeLabel;

  /// Button that checks the entered code and signs in.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get loginVerifyCode;

  /// Button that sends a new one-time code.
  ///
  /// In de, this message translates to:
  /// **'Code erneut senden'**
  String get loginResendCode;

  /// Confirmation after a new code was sent.
  ///
  /// In de, this message translates to:
  /// **'Neuer Code ist unterwegs.'**
  String get loginCodeResent;

  /// Button that returns from the code step to the email step.
  ///
  /// In de, this message translates to:
  /// **'Andere E-Mail-Adresse verwenden'**
  String get loginChangeEmail;

  /// Error when the email address is not valid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine gültige E-Mail-Adresse ein.'**
  String get errorInvalidEmail;

  /// Error when the one-time code is wrong or expired.
  ///
  /// In de, this message translates to:
  /// **'Der Code ist falsch oder abgelaufen. Fordere bei Bedarf einen neuen an.'**
  String get errorInvalidOrExpiredCode;

  /// Error when the backend rate limit was hit.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Bitte warte kurz und versuche es dann erneut.'**
  String get errorTooManyRequests;

  /// Error when the email service refuses the address (e.g. test email service limited to team members).
  ///
  /// In de, this message translates to:
  /// **'An diese E-Mail-Adresse können wir derzeit keine E-Mails senden.'**
  String get errorEmailNotAuthorized;

  /// Generic error message for unexpected problems.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Bitte prüfe deine Internetverbindung und versuche es erneut.'**
  String get errorUnknown;

  /// Hint inside the large request field on the customer home screen.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe, was du brauchst …'**
  String get customerHomeInputHint;

  /// Label above the tappable example requests on the customer home screen.
  ///
  /// In de, this message translates to:
  /// **'Beispiele'**
  String get customerHomeExamplesLabel;

  /// Example request a customer can tap to fill the input field.
  ///
  /// In de, this message translates to:
  /// **'Meine Waschmaschine verliert Wasser.'**
  String get customerHomeExampleWashingMachine;

  /// Example request a customer can tap to fill the input field.
  ///
  /// In de, this message translates to:
  /// **'Ich brauche morgen jemanden zum Putzen.'**
  String get customerHomeExampleCleaning;

  /// Example request a customer can tap to fill the input field.
  ///
  /// In de, this message translates to:
  /// **'Jemand soll meinen Fernseher montieren.'**
  String get customerHomeExampleTv;

  /// Example request a customer can tap to fill the input field.
  ///
  /// In de, this message translates to:
  /// **'Mein Garten muss geschnitten werden.'**
  String get customerHomeExampleGarden;

  /// Button that opens the request screen with the typed text.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get customerHomeContinue;

  /// Section heading above the category cards on the customer home screen.
  ///
  /// In de, this message translates to:
  /// **'Beliebte Services'**
  String get customerHomePopularServices;

  /// Section heading above the customer's upcoming bookings.
  ///
  /// In de, this message translates to:
  /// **'Deine nächsten Buchungen'**
  String get customerHomeUpcomingBookings;

  /// Shown when the customer has no bookings yet.
  ///
  /// In de, this message translates to:
  /// **'Buche deinen ersten Service über {appName}.'**
  String customerHomeNoBookingsMessage(String appName);

  /// Service category: repairs and handyman work.
  ///
  /// In de, this message translates to:
  /// **'Handwerker'**
  String get categoryHandyman;

  /// Service category: cleaning.
  ///
  /// In de, this message translates to:
  /// **'Reinigung'**
  String get categoryCleaning;

  /// Service category: moving and transport.
  ///
  /// In de, this message translates to:
  /// **'Umzug & Transport'**
  String get categoryMoving;

  /// Service category: car services.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get categoryCar;

  /// Service category: pet services.
  ///
  /// In de, this message translates to:
  /// **'Haustiere'**
  String get categoryPets;

  /// Service category: beauty and personal care.
  ///
  /// In de, this message translates to:
  /// **'Beauty'**
  String get categoryBeauty;

  /// Service category: renovation.
  ///
  /// In de, this message translates to:
  /// **'Renovierung'**
  String get categoryRenovation;

  /// Service category: anything not covered by the others.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get categoryOther;

  /// Heading of the service request screen.
  ///
  /// In de, this message translates to:
  /// **'Erzähl uns kurz, was du brauchst'**
  String get requestTitle;

  /// Label above the editable request text.
  ///
  /// In de, this message translates to:
  /// **'Deine Anfrage'**
  String get requestDescriptionLabel;

  /// Error shown when the request text is empty.
  ///
  /// In de, this message translates to:
  /// **'Bitte beschreibe kurz, was du brauchst.'**
  String get requestDescriptionRequired;

  /// Label above the optional category choice.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get requestCategoryLabel;

  /// Explains that picking a category is not required.
  ///
  /// In de, this message translates to:
  /// **'Optional – die passende Leistung erkennen wir später automatisch.'**
  String get requestCategoryHint;

  /// Label above the location choice on the request screen.
  ///
  /// In de, this message translates to:
  /// **'Wo wird die Dienstleistung benötigt?'**
  String get requestLocationLabel;

  /// Button that will open the location picker once maps are integrated.
  ///
  /// In de, this message translates to:
  /// **'Standort auswählen'**
  String get requestLocationChoose;

  /// Label above the timing options on the request screen.
  ///
  /// In de, this message translates to:
  /// **'Wann brauchst du Hilfe?'**
  String get requestTimingLabel;

  /// Timing option: as soon as possible.
  ///
  /// In de, this message translates to:
  /// **'So schnell wie möglich'**
  String get requestTimingAsap;

  /// Timing option: today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get requestTimingToday;

  /// Timing option: tomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get requestTimingTomorrow;

  /// Timing option that opens a date picker.
  ///
  /// In de, this message translates to:
  /// **'Datum auswählen'**
  String get requestTimingPickDate;

  /// Label above the photo section on the request screen.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get requestPhotosLabel;

  /// Button that will attach a photo once file storage exists.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get requestAddPhoto;

  /// Button that saves the request.
  ///
  /// In de, this message translates to:
  /// **'Anfrage erstellen'**
  String get requestSubmit;

  /// Confirmation after a request was saved.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gespeichert.'**
  String get requestSaved;

  /// Says that saving a request does not send it: the customer picks the provider.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Speichern zeigen wir dir passende Anbieter. Gesendet wird erst, wenn du einen auswählst.'**
  String get requestNotSentYet;

  /// Section heading above the customer's saved requests.
  ///
  /// In de, this message translates to:
  /// **'Deine Anfragen'**
  String get customerRequestsTitle;

  /// Badge on a saved request that has not reached any provider yet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gesendet'**
  String get customerRequestsNotSent;

  /// Label of the display name in the profile.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get profileName;

  /// Shown instead of the name when the account has none yet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht hinterlegt'**
  String get profileNameMissing;

  /// Label of the name field in the profile editor.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get profileNameLabel;

  /// Explains who sees the name and that a first name is enough.
  ///
  /// In de, this message translates to:
  /// **'So sehen dich die Menschen, mit denen du einen Auftrag hast. Ein Vorname genügt.'**
  String get profileNameHelp;

  /// Adds a profile picture when there is none.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get profilePictureAdd;

  /// Replaces an existing profile picture.
  ///
  /// In de, this message translates to:
  /// **'Foto ändern'**
  String get profilePictureChange;

  /// Take a new profile picture with the camera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get profilePictureCamera;

  /// Pick an existing photo as the profile picture.
  ///
  /// In de, this message translates to:
  /// **'Foto aus Galerie'**
  String get profilePictureGallery;

  /// Deletes the profile picture.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get profilePictureRemove;

  /// Confirmation after a picture was uploaded.
  ///
  /// In de, this message translates to:
  /// **'Foto gespeichert'**
  String get profilePictureSaved;

  /// Saves the profile.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get profileSave;

  /// Confirmation after the profile was saved.
  ///
  /// In de, this message translates to:
  /// **'Profil gespeichert'**
  String get profileSaved;

  /// Shown when the profile could not be read.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil konnte nicht geladen werden.'**
  String get profileLoadFailed;

  /// Says plainly who sees the name and picture, and that an uploaded picture is reachable by its address.
  ///
  /// In de, this message translates to:
  /// **'Name und Foto sehen die Menschen, mit denen du einen Auftrag hast, und Kundinnen und Kunden, die dein Profil ansehen. Deine E-Mail-Adresse und deine Telefonnummer bleiben verborgen. Ein einmal hochgeladenes Foto ist über seine Adresse auch ohne Anmeldung erreichbar.'**
  String get profileVisibilityNote;

  /// Profile entry that will open profile editing.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get profileEdit;

  /// Profile entry that will open the app settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get profileSettings;

  /// Shown when a prepared button has no function yet.
  ///
  /// In de, this message translates to:
  /// **'Diese Funktion folgt in Kürze.'**
  String get comingSoon;

  /// Shown while the service catalog is being fetched.
  ///
  /// In de, this message translates to:
  /// **'Services werden geladen …'**
  String get catalogLoading;

  /// Shown when the catalog could not be fetched.
  ///
  /// In de, this message translates to:
  /// **'Services konnten nicht geladen werden.'**
  String get catalogErrorMessage;

  /// Button that retries loading after an error.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get catalogRetry;

  /// Empty state title when the catalog has no entries.
  ///
  /// In de, this message translates to:
  /// **'Keine Services verfügbar'**
  String get catalogEmptyTitle;

  /// Empty state text when the catalog has no entries.
  ///
  /// In de, this message translates to:
  /// **'Momentan sind keine Services verfügbar. Schau später noch einmal vorbei.'**
  String get catalogEmptyMessage;

  /// Empty state text on a category screen without services.
  ///
  /// In de, this message translates to:
  /// **'In dieser Kategorie gibt es noch keine Leistungen.'**
  String get categoryServicesEmptyMessage;

  /// Lowest price of a service, e.g. 'ab € 59,00'.
  ///
  /// In de, this message translates to:
  /// **'ab {price}'**
  String servicePriceFrom(String price);

  /// Shown instead of a price when a service is quoted individually.
  ///
  /// In de, this message translates to:
  /// **'Angebot'**
  String get serviceQuoteBadge;

  /// Heading above the price options of a service.
  ///
  /// In de, this message translates to:
  /// **'Preisoptionen'**
  String get servicePriceOptionsTitle;

  /// Explains that a quote service has no fixed price.
  ///
  /// In de, this message translates to:
  /// **'Für diese Leistung erstellst du eine Anfrage und erhältst passende Angebote.'**
  String get serviceQuoteHint;

  /// Makes clear that catalog prices are not binding.
  ///
  /// In de, this message translates to:
  /// **'Beispielpreise. Der endgültige Preis wird mit dem Dienstleister vereinbart.'**
  String get servicePricesExampleHint;

  /// Button that carries the chosen service into the request form.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get serviceContinue;

  /// Shown when a service was removed or deactivated.
  ///
  /// In de, this message translates to:
  /// **'Diese Leistung ist nicht mehr verfügbar.'**
  String get serviceNotFound;

  /// Rough duration of a price option.
  ///
  /// In de, this message translates to:
  /// **'ca. {minutes} Min.'**
  String serviceDurationMinutes(int minutes);

  /// Progress line above each onboarding step.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String providerOnboardingStep(int current, int total);

  /// Heading of onboarding step 1.
  ///
  /// In de, this message translates to:
  /// **'Erzähl uns kurz etwas über dich.'**
  String get providerPersonalTitle;

  /// Label of the first name field.
  ///
  /// In de, this message translates to:
  /// **'Vorname'**
  String get providerFirstNameLabel;

  /// Label of the last name field.
  ///
  /// In de, this message translates to:
  /// **'Nachname'**
  String get providerLastNameLabel;

  /// Button that will add a profile photo once file upload exists.
  ///
  /// In de, this message translates to:
  /// **'Profilbild hinzufügen'**
  String get providerPhotoAdd;

  /// Heading of onboarding step 2.
  ///
  /// In de, this message translates to:
  /// **'Arbeitest du selbstständig oder für ein Unternehmen?'**
  String get providerBusinessTitle;

  /// Option for sole traders.
  ///
  /// In de, this message translates to:
  /// **'Selbstständig'**
  String get providerKindSelfEmployed;

  /// Option for companies.
  ///
  /// In de, this message translates to:
  /// **'Unternehmen'**
  String get providerKindCompany;

  /// Label of the company name field.
  ///
  /// In de, this message translates to:
  /// **'Firmenname'**
  String get providerCompanyNameLabel;

  /// Label of the trading name for sole traders.
  ///
  /// In de, this message translates to:
  /// **'Name deines Betriebs'**
  String get providerTradingNameLabel;

  /// Heading of onboarding step 3.
  ///
  /// In de, this message translates to:
  /// **'Welche Leistungen bietest du an?'**
  String get providerServicesTitle;

  /// Explains that the choice is not final.
  ///
  /// In de, this message translates to:
  /// **'Wähle alles aus, was du anbietest. Du kannst das später jederzeit ändern.'**
  String get providerServicesHint;

  /// Heading of onboarding step 4.
  ///
  /// In de, this message translates to:
  /// **'Wo möchtest du Aufträge annehmen?'**
  String get providerAreaTitle;

  /// Label of the city field.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get providerCityLabel;

  /// Label of the postal code field.
  ///
  /// In de, this message translates to:
  /// **'Postleitzahl'**
  String get providerPostalCodeLabel;

  /// Current service radius.
  ///
  /// In de, this message translates to:
  /// **'Umkreis: {km} km'**
  String providerRadiusLabel(int km);

  /// Heading of the last onboarding step.
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft.'**
  String get providerFinishTitle;

  /// Explains what happens after onboarding.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil ist angelegt. Sobald es Aufträge in deiner Nähe gibt, siehst du sie in deinem Bereich.'**
  String get providerFinishMessage;

  /// Button that completes onboarding.
  ///
  /// In de, this message translates to:
  /// **'Profil fertigstellen'**
  String get providerFinishButton;

  /// Button that returns to the previous onboarding step.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get providerBack;

  /// Heading of the verification section.
  ///
  /// In de, this message translates to:
  /// **'Verifizierung'**
  String get providerVerificationTitle;

  /// Verification status: nothing checked yet.
  ///
  /// In de, this message translates to:
  /// **'Nicht verifiziert'**
  String get providerVerificationUnverified;

  /// Verification status: documents are being reviewed.
  ///
  /// In de, this message translates to:
  /// **'In Prüfung'**
  String get providerVerificationPending;

  /// Verification status: checked and approved.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get providerVerificationVerified;

  /// Verification status: rejected.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get providerVerificationRejected;

  /// Honest explanation that nothing has been checked yet and requirements differ per service.
  ///
  /// In de, this message translates to:
  /// **'Wir prüfen deine Nachweise, bevor dich Kundinnen und Kunden als geprüft sehen. Welche Nachweise nötig sind, hängt von deinen Leistungen ab.'**
  String get providerVerificationExplanation;

  /// Greeting on the provider home screen.
  ///
  /// In de, this message translates to:
  /// **'Hallo, {name}'**
  String providerHomeGreeting(String name);

  /// Greeting when no name is stored yet.
  ///
  /// In de, this message translates to:
  /// **'Hallo'**
  String get providerHomeGreetingPlain;

  /// Line below the greeting on the provider home screen.
  ///
  /// In de, this message translates to:
  /// **'Bereit für deinen nächsten Auftrag?'**
  String get providerHomeSubtitle;

  /// Empty state for the provider's jobs.
  ///
  /// In de, this message translates to:
  /// **'Du hast noch keine Aufträge.'**
  String get providerHomeNoJobs;

  /// Entry that opens the provider's own services.
  ///
  /// In de, this message translates to:
  /// **'Meine Leistungen'**
  String get providerHomeMyServices;

  /// Entry that opens the provider's availability.
  ///
  /// In de, this message translates to:
  /// **'Meine Verfügbarkeit'**
  String get providerHomeAvailability;

  /// How many services the provider offers.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Leistung ausgewählt} =1{1 Leistung} other{{count} Leistungen}}'**
  String providerServicesCount(int count);

  /// Validation error for the first name.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Vornamen ein.'**
  String get errorFirstNameRequired;

  /// Validation error for the last name.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Nachnamen ein.'**
  String get errorLastNameRequired;

  /// Validation error for the business name.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib den Namen deines Betriebs ein.'**
  String get errorBusinessNameRequired;

  /// Validation error when no service was picked.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle mindestens eine Leistung aus.'**
  String get errorServicesRequired;

  /// Validation error for the city.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deine Stadt ein.'**
  String get errorCityRequired;

  /// Button that opens the service picker.
  ///
  /// In de, this message translates to:
  /// **'Leistung hinzufügen'**
  String get providerAddService;

  /// Opens the prices of one offering.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get providerEdit;

  /// Shown for a fixed-price service the provider has not priced yet.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Preis hinterlegt'**
  String get providerNoPriceYet;

  /// Heading of the price screen for one service.
  ///
  /// In de, this message translates to:
  /// **'Preisgestaltung'**
  String get providerPricingTitle;

  /// Button that adds a price option.
  ///
  /// In de, this message translates to:
  /// **'Preisoption hinzufügen'**
  String get providerAddPrice;

  /// Label of the price option name, e.g. 'bis 50 m²'.
  ///
  /// In de, this message translates to:
  /// **'Bezeichnung'**
  String get providerPriceNameLabel;

  /// Label of the price amount field.
  ///
  /// In de, this message translates to:
  /// **'Preis in Euro'**
  String get providerPriceAmountLabel;

  /// Label of the unit field, e.g. 'pro Auftrag'.
  ///
  /// In de, this message translates to:
  /// **'Einheit'**
  String get providerPriceUnitLabel;

  /// Label of the duration field.
  ///
  /// In de, this message translates to:
  /// **'Dauer in Minuten'**
  String get providerPriceDurationLabel;

  /// Saves a price option.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get providerPriceSave;

  /// Hides a price option without deleting it.
  ///
  /// In de, this message translates to:
  /// **'Deaktivieren'**
  String get providerPriceDeactivate;

  /// Offers a deactivated price option again.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren'**
  String get providerPriceActivate;

  /// Removes a price option for good.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get providerPriceDelete;

  /// Badge on a deactivated price option.
  ///
  /// In de, this message translates to:
  /// **'Deaktiviert'**
  String get providerPriceInactive;

  /// Explains that a quoted service needs no fixed price.
  ///
  /// In de, this message translates to:
  /// **'Für diese Leistung brauchst du keinen Fixpreis. Kunden fordern ein Angebot an.'**
  String get providerQuoteNoPriceNeeded;

  /// Empty state on the price screen.
  ///
  /// In de, this message translates to:
  /// **'Du hast für diese Leistung noch keinen Preis hinterlegt.'**
  String get providerPricesEmpty;

  /// Empty state when the provider offers nothing yet.
  ///
  /// In de, this message translates to:
  /// **'Du bietest noch keine Leistungen an.'**
  String get providerServicesEmpty;

  /// Validation error for the price option name.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine Bezeichnung ein.'**
  String get errorPriceNameRequired;

  /// Validation error for the price amount.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen gültigen Preis ein.'**
  String get errorPriceInvalid;

  /// Heading of the provider results list.
  ///
  /// In de, this message translates to:
  /// **'Anbieter für diese Leistung'**
  String get providerMatchesTitle;

  /// Button that opens the provider results for a service.
  ///
  /// In de, this message translates to:
  /// **'Anbieter anzeigen'**
  String get providerMatchesShow;

  /// Empty state title when no provider offers the service.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand verfügbar'**
  String get providerMatchesEmptyTitle;

  /// Honest empty state: the marketplace has no providers for this service yet.
  ///
  /// In de, this message translates to:
  /// **'Für diese Leistung ist noch kein Dienstleister eingetragen. Deine Anfrage bleibt gespeichert — sobald sich jemand einträgt, findest du ihn hier.'**
  String get providerMatchesEmptyMessage;

  /// Fallback when a provider stored no name.
  ///
  /// In de, this message translates to:
  /// **'Dienstleister'**
  String get providerUnnamed;

  /// Shown when a provider has not set a price for this service.
  ///
  /// In de, this message translates to:
  /// **'Preis auf Anfrage'**
  String get providerNoPriceGiven;

  /// Label of the city field on the request screen.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get requestCityLabel;

  /// Example city inside the request form.
  ///
  /// In de, this message translates to:
  /// **'z. B. Wien'**
  String get requestCityPlaceholder;

  /// Label of the postal code field on the request screen.
  ///
  /// In de, this message translates to:
  /// **'PLZ'**
  String get requestPostalCodeLabel;

  /// Explains that leaving the city empty widens the search instead of narrowing it.
  ///
  /// In de, this message translates to:
  /// **'Ohne Ort zeigen wir dir Anbieter aus allen Orten.'**
  String get requestLocationHint;

  /// Heading of the provider list belonging to one saved request.
  ///
  /// In de, this message translates to:
  /// **'Passende Anbieter'**
  String get requestMatchesTitle;

  /// Empty state when a saved request names no catalog service.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Leistung gewählt'**
  String get requestMatchesNoServiceTitle;

  /// Explains why matching cannot run for a free-text request yet.
  ///
  /// In de, this message translates to:
  /// **'Diese Anfrage nennt noch keine konkrete Leistung. Wähle eine Leistung im Katalog, dann suchen wir passende Anbieter.'**
  String get requestMatchesNoServiceMessage;

  /// Button that sends the saved request to one provider.
  ///
  /// In de, this message translates to:
  /// **'Anfrage senden'**
  String get providerMatchSend;

  /// Shown on a provider the request has already reached.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet'**
  String get providerMatchSent;

  /// Confirmation after the request was sent to one provider.
  ///
  /// In de, this message translates to:
  /// **'Deine Anfrage ging an {name}.'**
  String requestSentToProvider(String name);

  /// Opens the provider list for a saved request.
  ///
  /// In de, this message translates to:
  /// **'Passende Anbieter'**
  String get customerRequestsShowProviders;

  /// How many providers a saved request has been sent to.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch nicht gesendet} =1{An 1 Anbieter gesendet} other{An {count} Anbieter gesendet}}'**
  String customerRequestsSentCount(int count);

  /// Heading of the requests a provider has received.
  ///
  /// In de, this message translates to:
  /// **'Anfragen an dich'**
  String get providerIncomingTitle;

  /// Honest empty state for a provider without incoming requests.
  ///
  /// In de, this message translates to:
  /// **'Du hast noch keine Anfragen erhalten. Sobald dich jemand anfragt, steht sie hier.'**
  String get providerIncomingEmpty;

  /// Who sent an incoming request.
  ///
  /// In de, this message translates to:
  /// **'von {name}'**
  String providerIncomingFrom(String name);

  /// Fallback when the customer stored no name.
  ///
  /// In de, this message translates to:
  /// **'Kundin oder Kunde'**
  String get providerIncomingCustomerUnknown;

  /// Number of requests a provider has received.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Anfragen} =1{1 Anfrage} other{{count} Anfragen}}'**
  String providerIncomingCount(int count);

  /// Button a provider uses to accept a received request.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get providerIncomingAccept;

  /// Button a provider uses to decline a received request.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get providerIncomingDecline;

  /// Shown on a request this provider accepted.
  ///
  /// In de, this message translates to:
  /// **'Du hast angenommen'**
  String get providerIncomingAccepted;

  /// Shown on a request this provider declined.
  ///
  /// In de, this message translates to:
  /// **'Du hast abgelehnt'**
  String get providerIncomingDeclined;

  /// Confirmation after accepting a request.
  ///
  /// In de, this message translates to:
  /// **'Anfrage angenommen.'**
  String get providerIncomingAcceptedToast;

  /// Confirmation after declining a request.
  ///
  /// In de, this message translates to:
  /// **'Anfrage abgelehnt.'**
  String get providerIncomingDeclinedToast;

  /// A request that reached a provider who has not answered.
  ///
  /// In de, this message translates to:
  /// **'Noch offen'**
  String get requestStatusOpen;

  /// A request a provider accepted.
  ///
  /// In de, this message translates to:
  /// **'Angenommen'**
  String get requestStatusAccepted;

  /// A request a provider declined.
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get requestStatusDeclined;

  /// Job status: a time has been agreed.
  ///
  /// In de, this message translates to:
  /// **'Termin vereinbart'**
  String get jobStatusScheduled;

  /// Job status: the provider is on their way.
  ///
  /// In de, this message translates to:
  /// **'Unterwegs'**
  String get jobStatusOnTheWay;

  /// Job status: the work is happening.
  ///
  /// In de, this message translates to:
  /// **'In Arbeit'**
  String get jobStatusInProgress;

  /// Job status: the provider reported the work done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get jobStatusCompleted;

  /// Job status: the customer confirmed the work.
  ///
  /// In de, this message translates to:
  /// **'Vom Kunden bestätigt'**
  String get jobStatusConfirmed;

  /// Job status: the job was called off.
  ///
  /// In de, this message translates to:
  /// **'Storniert'**
  String get jobStatusCancelled;

  /// Heading above the list of running jobs.
  ///
  /// In de, this message translates to:
  /// **'Deine Aufträge'**
  String get jobsTitle;

  /// The agreed appointment on a job card.
  ///
  /// In de, this message translates to:
  /// **'Termin: {when}'**
  String jobAppointment(String when);

  /// Says plainly that no time has been agreed.
  ///
  /// In de, this message translates to:
  /// **'Termin noch nicht vereinbart'**
  String get jobNoAppointment;

  /// Headline while the provider is travelling.
  ///
  /// In de, this message translates to:
  /// **'{name} ist unterwegs'**
  String jobOnTheWayNamed(String name);

  /// Headline on the provider own screen while they are travelling.
  ///
  /// In de, this message translates to:
  /// **'Du bist unterwegs'**
  String get jobOnTheWaySelf;

  /// Asks the customer to confirm the finished work.
  ///
  /// In de, this message translates to:
  /// **'Bitte bestätige, dass die Arbeit abgeschlossen ist.'**
  String get jobCompletedAsk;

  /// Shown to the provider after reporting the work done.
  ///
  /// In de, this message translates to:
  /// **'Warte auf die Bestätigung durch die Kundin oder den Kunden.'**
  String get jobCompletedWaiting;

  /// Shown once the customer confirmed.
  ///
  /// In de, this message translates to:
  /// **'Auftrag abgeschlossen'**
  String get jobFinished;

  /// Button that records the agreed time.
  ///
  /// In de, this message translates to:
  /// **'Termin vereinbaren'**
  String get jobSetAppointment;

  /// Button the provider taps when setting off.
  ///
  /// In de, this message translates to:
  /// **'Ich bin unterwegs'**
  String get jobOnMyWay;

  /// Button the provider taps when starting.
  ///
  /// In de, this message translates to:
  /// **'Arbeit beginnen'**
  String get jobStartWork;

  /// Button the provider taps when finished.
  ///
  /// In de, this message translates to:
  /// **'Auftrag fertig'**
  String get jobReportDone;

  /// Button the customer taps to confirm the work.
  ///
  /// In de, this message translates to:
  /// **'Auftrag bestätigen'**
  String get jobConfirm;

  /// Shown to the customer while it is the provider's turn.
  ///
  /// In de, this message translates to:
  /// **'Der Dienstleister meldet sich, sobald es losgeht.'**
  String get jobWaitingForProvider;

  /// Opens the chat from a job card.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben'**
  String get jobOpenChat;

  /// Confirmation after a status change.
  ///
  /// In de, this message translates to:
  /// **'Auftrag aktualisiert.'**
  String get jobChanged;

  /// Second step of picking an appointment.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit wählen'**
  String get jobAppointmentPickTime;

  /// Heading of the review screen.
  ///
  /// In de, this message translates to:
  /// **'Wie war dein Auftrag?'**
  String get reviewTitle;

  /// Label above the optional comment field.
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du über den Auftrag sagen?'**
  String get reviewCommentLabel;

  /// Placeholder of the optional comment field.
  ///
  /// In de, this message translates to:
  /// **'Deine Erfahrung (optional)'**
  String get reviewCommentHint;

  /// Button that sends the review.
  ///
  /// In de, this message translates to:
  /// **'Bewertung abgeben'**
  String get reviewSubmit;

  /// Button on a finished job that opens the review screen.
  ///
  /// In de, this message translates to:
  /// **'Auftrag bewerten'**
  String get reviewRate;

  /// Shown after a review was saved.
  ///
  /// In de, this message translates to:
  /// **'Danke für deine Bewertung!'**
  String get reviewThanks;

  /// Label above the rating the customer gave.
  ///
  /// In de, this message translates to:
  /// **'Deine Bewertung'**
  String get reviewYours;

  /// Button that leaves the review screen.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu meinen Aufträgen'**
  String get reviewBackToJobs;

  /// Shown instead of the form when a job was already reviewed.
  ///
  /// In de, this message translates to:
  /// **'Du hast diesen Auftrag bereits bewertet.'**
  String get reviewAlready;

  /// Word for a one-star rating.
  ///
  /// In de, this message translates to:
  /// **'Sehr schlecht'**
  String get reviewStars1;

  /// Word for a two-star rating.
  ///
  /// In de, this message translates to:
  /// **'Nicht gut'**
  String get reviewStars2;

  /// Word for a three-star rating.
  ///
  /// In de, this message translates to:
  /// **'Okay'**
  String get reviewStars3;

  /// Word for a four-star rating.
  ///
  /// In de, this message translates to:
  /// **'Gut'**
  String get reviewStars4;

  /// Word for a five-star rating.
  ///
  /// In de, this message translates to:
  /// **'Ausgezeichnet'**
  String get reviewStars5;

  /// How many reviews a provider has.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Bewertung} other{{count} Bewertungen}}'**
  String reviewCount(int count);

  /// Shown for a provider nobody has rated; never a made-up score.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bewertungen'**
  String get reviewNone;

  /// Heading of the rating card on the provider's home.
  ///
  /// In de, this message translates to:
  /// **'Deine Bewertung'**
  String get reviewYourRatingTitle;

  /// How many providers accepted a saved request.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Anbieter hat angenommen} other{{count} Anbieter haben angenommen}}'**
  String customerRequestsAcceptedCount(int count);

  /// How many providers declined a saved request, when none accepted.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Anbieter hat abgelehnt} other{{count} Anbieter haben abgelehnt}}'**
  String customerRequestsDeclinedCount(int count);

  /// Shown when a request was answered elsewhere before this tap arrived.
  ///
  /// In de, this message translates to:
  /// **'Diese Anfrage wurde bereits beantwortet.'**
  String get errorRequestAlreadyAnswered;

  /// Shown when sending is attempted with no text.
  ///
  /// In de, this message translates to:
  /// **'Die Nachricht ist leer.'**
  String get errorMessageEmpty;

  /// Header fallback when the other person's name was not passed in.
  ///
  /// In de, this message translates to:
  /// **'Chat'**
  String get chatOtherUnknown;

  /// Says plainly that no appointment exists yet; the app must not present the customer's wish as one.
  ///
  /// In de, this message translates to:
  /// **'Termin noch nicht vereinbart'**
  String get chatNoAppointment;

  /// Placeholder of the message field.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben …'**
  String get chatMessageHint;

  /// Label of the send button.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get chatSend;

  /// Empty state of a conversation nobody has written in yet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten'**
  String get chatEmptyTitle;

  /// Says what the chat is for.
  ///
  /// In de, this message translates to:
  /// **'Schreib die erste Nachricht, um den Termin abzustimmen.'**
  String get chatEmptyMessage;

  /// Shown when the conversation or its messages could not be read.
  ///
  /// In de, this message translates to:
  /// **'Chat konnte nicht geladen werden.'**
  String get chatLoadFailed;

  /// Opens the chat from the customer's side.
  ///
  /// In de, this message translates to:
  /// **'Dienstleister kontaktieren'**
  String get chatWithProvider;

  /// Opens the chat from the provider's side.
  ///
  /// In de, this message translates to:
  /// **'Kunde kontaktieren'**
  String get chatWithCustomer;

  /// Title of the booking flow.
  ///
  /// In de, this message translates to:
  /// **'Auftrag anlegen'**
  String get bookingTitle;

  /// Shown above the suggested services.
  ///
  /// In de, this message translates to:
  /// **'Passt das?'**
  String get bookingSuggestTitle;

  /// Shown when nothing in the catalog matched the text.
  ///
  /// In de, this message translates to:
  /// **'Welchen Service suchst du?'**
  String get bookingSuggestNoneTitle;

  /// While the backend matches the text against the catalog.
  ///
  /// In de, this message translates to:
  /// **'Wir suchen passende Leistungen …'**
  String get bookingSuggestLoading;

  /// Shown when the suggestion call failed.
  ///
  /// In de, this message translates to:
  /// **'Die Leistungen konnten nicht geladen werden.'**
  String get bookingSuggestFailed;

  /// Offer to browse the catalog when the suggestions are wrong.
  ///
  /// In de, this message translates to:
  /// **'Nichts davon? Such dir die Leistung selbst aus.'**
  String get bookingSuggestOtherHint;

  /// Says plainly that nothing matched, instead of guessing.
  ///
  /// In de, this message translates to:
  /// **'Wir konnten deinen Text keiner Leistung zuordnen. Such sie dir bitte selbst aus.'**
  String get bookingSuggestNoneHint;

  /// Opens the catalog.
  ///
  /// In de, this message translates to:
  /// **'Leistungen durchsuchen'**
  String get bookingSuggestBrowse;

  /// Headline of the location step.
  ///
  /// In de, this message translates to:
  /// **'Wo soll der Auftrag stattfinden?'**
  String get bookingWhereTitle;

  /// Explains why each field is asked for and who sees the address.
  ///
  /// In de, this message translates to:
  /// **'Die Stadt brauchen wir, um passende Dienstleister zu finden. Die genaue Adresse sieht nur, wer den Auftrag annimmt.'**
  String get bookingWhereHint;

  /// Street address field.
  ///
  /// In de, this message translates to:
  /// **'Straße und Hausnummer'**
  String get bookingAddressLabel;

  /// Postal code field.
  ///
  /// In de, this message translates to:
  /// **'PLZ'**
  String get bookingPostalCodeLabel;

  /// City field.
  ///
  /// In de, this message translates to:
  /// **'Stadt'**
  String get bookingCityLabel;

  /// Says the city is the one required field.
  ///
  /// In de, this message translates to:
  /// **'Wird benötigt'**
  String get bookingCityRequired;

  /// Continues from the location step.
  ///
  /// In de, this message translates to:
  /// **'Dienstleister suchen'**
  String get bookingFindProviders;

  /// Title of the provider list in the booking flow.
  ///
  /// In de, this message translates to:
  /// **'Wer kann das machen?'**
  String get bookingProvidersTitle;

  /// Shown when the provider list could not be read.
  ///
  /// In de, this message translates to:
  /// **'Die Dienstleister konnten nicht geladen werden.'**
  String get bookingProvidersFailed;

  /// Title of the empty provider list.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand verfügbar'**
  String get bookingNoProvidersTitle;

  /// Says plainly that nobody qualifies, instead of showing unverified providers.
  ///
  /// In de, this message translates to:
  /// **'Derzeit ist für diesen Service in deiner Nähe kein verifizierter Dienstleister mit Festpreis verfügbar. Du kannst stattdessen eine Anfrage schreiben.'**
  String get bookingNoProviders;

  /// Leads to the older flow: describe the job and ask providers, with no fixed price.
  ///
  /// In de, this message translates to:
  /// **'Stattdessen Anfrage schreiben'**
  String get bookingWriteRequestInstead;

  /// Opens one provider's profile.
  ///
  /// In de, this message translates to:
  /// **'Profil ansehen'**
  String get bookingViewProfile;

  /// Title of the provider detail screen.
  ///
  /// In de, this message translates to:
  /// **'Dienstleister'**
  String get bookingProviderTitle;

  /// Shown when the provider detail could not be read.
  ///
  /// In de, this message translates to:
  /// **'Das Profil konnte nicht geladen werden.'**
  String get bookingProviderFailed;

  /// Title when the provider no longer offers this service.
  ///
  /// In de, this message translates to:
  /// **'Nicht mehr verfügbar'**
  String get bookingProviderGoneTitle;

  /// Shown when the provider dropped out between the list and the tap.
  ///
  /// In de, this message translates to:
  /// **'Dieser Dienstleister bietet die Leistung gerade nicht mehr an. Geh zurück und wähle jemand anderen.'**
  String get bookingProviderGone;

  /// Heading above the provider's price options.
  ///
  /// In de, this message translates to:
  /// **'Preise'**
  String get bookingPricesTitle;

  /// Says where the prices come from — the app invents none.
  ///
  /// In de, this message translates to:
  /// **'Diese Preise hat der Dienstleister selbst festgelegt.'**
  String get bookingPricesHint;

  /// Roughly how long the provider expects to need.
  ///
  /// In de, this message translates to:
  /// **'ca. {minutes} Min.'**
  String bookingApproxMinutes(int minutes);

  /// Picks one price option.
  ///
  /// In de, this message translates to:
  /// **'Auswählen'**
  String get bookingChoosePrice;

  /// Headline of the scheduling step.
  ///
  /// In de, this message translates to:
  /// **'Wann passt es dir?'**
  String get bookingWhenTitle;

  /// Introduces the date and time pickers.
  ///
  /// In de, this message translates to:
  /// **'Sag uns deinen Wunschtermin.'**
  String get bookingWhenHint;

  /// Date row.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get bookingDateLabel;

  /// Time row.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit'**
  String get bookingTimeLabel;

  /// Placeholder before a date or time is picked.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gewählt'**
  String get bookingNotChosen;

  /// Says plainly that availability has not been checked.
  ///
  /// In de, this message translates to:
  /// **'Das ist ein Wunschtermin. Ob der Dienstleister dann Zeit hat, klärt ihr gemeinsam – erst danach steht der Termin fest.'**
  String get bookingWhenDisclaimer;

  /// Continues to the summary.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Übersicht'**
  String get bookingToSummary;

  /// Title of the summary screen.
  ///
  /// In de, this message translates to:
  /// **'Übersicht'**
  String get bookingSummaryTitle;

  /// Headline of the summary.
  ///
  /// In de, this message translates to:
  /// **'Dein Auftrag'**
  String get bookingYourJob;

  /// Summary row label.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get bookingLabelService;

  /// Summary row label.
  ///
  /// In de, this message translates to:
  /// **'Dienstleister'**
  String get bookingLabelProvider;

  /// Summary row label for the chosen price option.
  ///
  /// In de, this message translates to:
  /// **'Auswahl'**
  String get bookingLabelOption;

  /// Summary row label.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get bookingLabelPlace;

  /// Summary row label.
  ///
  /// In de, this message translates to:
  /// **'Wunschtermin'**
  String get bookingLabelWhen;

  /// Summary row label.
  ///
  /// In de, this message translates to:
  /// **'Preis'**
  String get bookingLabelPrice;

  /// Says that sending costs nothing yet — there are no payments.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Senden geht deine Anfrage an den Dienstleister. Bezahlt wird noch nichts.'**
  String get bookingSummaryDisclaimer;

  /// Sends the booking.
  ///
  /// In de, this message translates to:
  /// **'Anfrage senden'**
  String get bookingSend;

  /// Confirmation headline.
  ///
  /// In de, this message translates to:
  /// **'Anfrage gesendet'**
  String get bookingDoneTitle;

  /// Names the provider the request went to.
  ///
  /// In de, this message translates to:
  /// **'Deine Anfrage wurde an {name} gesendet.'**
  String bookingDoneMessage(String name);

  /// Used when the provider stored no name.
  ///
  /// In de, this message translates to:
  /// **'Deine Anfrage wurde an den Dienstleister gesendet.'**
  String get bookingDoneMessagePlain;

  /// Says what happens next, without promising acceptance.
  ///
  /// In de, this message translates to:
  /// **'Sobald sie angenommen wird, findest du den Auftrag unter Buchungen.'**
  String get bookingDoneNext;

  /// Opens the bookings tab.
  ///
  /// In de, this message translates to:
  /// **'Auftrag ansehen'**
  String get bookingDoneViewJob;

  /// Opens the chat for this job.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben'**
  String get bookingDoneMessageProvider;

  /// Returns to the customer home.
  ///
  /// In de, this message translates to:
  /// **'Zur Startseite'**
  String get bookingDoneHome;

  /// Section title for the pictures on a request.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get photosLabel;

  /// Says photos are voluntary, and why they are worth adding.
  ///
  /// In de, this message translates to:
  /// **'Optional. Ein Foto zeigt oft schneller als Worte, worum es geht.'**
  String get photosHint;

  /// Says plainly who can see the photos, right where they are chosen.
  ///
  /// In de, this message translates to:
  /// **'Nur du und die Dienstleister, die du anfragst, sehen sie.'**
  String get photosPrivacy;

  /// Adds another picture to the request.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get photosAdd;

  /// Takes a chosen picture back off again, before anything is sent.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get photosRemove;

  /// Takes a new picture of the job with the camera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get photosFromCamera;

  /// Picks an existing picture of the job.
  ///
  /// In de, this message translates to:
  /// **'Foto aus Galerie'**
  String get photosFromGallery;

  /// Spoken label for a thumbnail, read out by a screen reader.
  ///
  /// In de, this message translates to:
  /// **'Foto ansehen'**
  String get photosOpen;

  /// How many pictures are on a request.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Foto} other{{count} Fotos}}'**
  String photosCount(int count);

  /// Which picture of how many is open in the viewer.
  ///
  /// In de, this message translates to:
  /// **'{index} von {total}'**
  String photosPosition(int index, int total);

  /// Shown after booking when pictures failed to upload. Says the booking itself went through, so nobody books a second time.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Ein Foto konnte nicht gesendet werden. Deine Anfrage ist trotzdem angekommen.} other{{count} Fotos konnten nicht gesendet werden. Deine Anfrage ist trotzdem angekommen.}}'**
  String photosNotSent(int count);

  /// The time the customer asked for, before anything is agreed.
  ///
  /// In de, this message translates to:
  /// **'Wunschtermin: {when}'**
  String jobWantedAt(String when);

  /// The price agreed at booking time.
  ///
  /// In de, this message translates to:
  /// **'Festpreis: {price}'**
  String jobAgreedPrice(String price);

  /// Generic retry button, used wherever a screen failed to load.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// Headline of the verification screen.
  ///
  /// In de, this message translates to:
  /// **'Verifiziere dein Profil'**
  String get verificationHeadline;

  /// Explains what the documents are for.
  ///
  /// In de, this message translates to:
  /// **'Mit deinen Nachweisen können wir bestätigen, dass du die angegebenen Dienstleistungen professionell anbietest.'**
  String get verificationIntro;

  /// Says plainly that a person reviews the documents and nothing is automatic.
  ///
  /// In de, this message translates to:
  /// **'Wir schauen uns jeden Nachweis von Hand an. Solange wir nicht fertig sind, siehst du kein Verifiziert-Abzeichen – und deine Kundinnen und Kunden auch nicht.'**
  String get verificationTeamNote;

  /// Marks a document the provider must hand in.
  ///
  /// In de, this message translates to:
  /// **'Erforderlich'**
  String get verificationRequired;

  /// Marks a document that is welcome but not required.
  ///
  /// In de, this message translates to:
  /// **'Optional'**
  String get verificationOptional;

  /// Status of a document nobody has handed in yet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht hochgeladen'**
  String get verificationNotUploaded;

  /// Status of a document that was handed in and not yet decided.
  ///
  /// In de, this message translates to:
  /// **'Prüfung ausstehend'**
  String get verificationStatusWaiting;

  /// Status of a document the team accepted.
  ///
  /// In de, this message translates to:
  /// **'Geprüft'**
  String get verificationStatusAccepted;

  /// Status of a document the team turned down.
  ///
  /// In de, this message translates to:
  /// **'Nachweis abgelehnt'**
  String get verificationStatusRejected;

  /// Why the team turned a document down.
  ///
  /// In de, this message translates to:
  /// **'Ablehnungsgrund: {reason}'**
  String verificationRejectionReason(String reason);

  /// When a document was handed in.
  ///
  /// In de, this message translates to:
  /// **'Hochgeladen am {date}'**
  String verificationUploadedOn(String date);

  /// Button that starts an upload.
  ///
  /// In de, this message translates to:
  /// **'Nachweis hochladen'**
  String get verificationUpload;

  /// Button shown after a document was rejected.
  ///
  /// In de, this message translates to:
  /// **'Neuen Nachweis hochladen'**
  String get verificationUploadNew;

  /// Button that swaps a handed-in document for a different file.
  ///
  /// In de, this message translates to:
  /// **'Nachweis ersetzen'**
  String get verificationReplace;

  /// Confirmation after a successful upload.
  ///
  /// In de, this message translates to:
  /// **'Dokument wurde hochgeladen'**
  String get verificationUploadDone;

  /// Take a photo of the document with the camera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get verificationSourceCamera;

  /// Pick an existing photo.
  ///
  /// In de, this message translates to:
  /// **'Foto aus Galerie'**
  String get verificationSourceGallery;

  /// Pick a file, usually a PDF.
  ///
  /// In de, this message translates to:
  /// **'PDF auswählen'**
  String get verificationSourceFile;

  /// Shown when the document list could not be read.
  ///
  /// In de, this message translates to:
  /// **'Nachweise konnten nicht geladen werden.'**
  String get verificationLoadFailed;

  /// Shown when nothing required is missing.
  ///
  /// In de, this message translates to:
  /// **'Alle erforderlichen Nachweise sind da. Wir melden uns, sobald wir sie geprüft haben.'**
  String get verificationAllHandedIn;

  /// Shown while at least one required document is missing.
  ///
  /// In de, this message translates to:
  /// **'Es fehlen noch erforderliche Nachweise.'**
  String get verificationMissing;

  /// Shown when there is no provider profile to verify.
  ///
  /// In de, this message translates to:
  /// **'Lege zuerst dein Dienstleisterprofil an.'**
  String get verificationNoProfile;

  /// Name of the identity document type.
  ///
  /// In de, this message translates to:
  /// **'Identitätsnachweis'**
  String get documentTypeIdentity;

  /// Examples of an accepted identity document.
  ///
  /// In de, this message translates to:
  /// **'Reisepass, Personalausweis oder Führerschein'**
  String get documentTypeIdentityHint;

  /// Name of the business registration document type.
  ///
  /// In de, this message translates to:
  /// **'Gewerbeanmeldung'**
  String get documentTypeBusinessRegistration;

  /// Examples of an accepted business registration.
  ///
  /// In de, this message translates to:
  /// **'Gewerbeschein oder Auszug aus dem Gewerberegister'**
  String get documentTypeBusinessRegistrationHint;

  /// Name of the trade licence document type.
  ///
  /// In de, this message translates to:
  /// **'Gewerbeberechtigung'**
  String get documentTypeTradeLicense;

  /// Explains what a trade licence is.
  ///
  /// In de, this message translates to:
  /// **'Befähigungsnachweis für ein reglementiertes Gewerbe'**
  String get documentTypeTradeLicenseHint;

  /// Name of the qualification document type.
  ///
  /// In de, this message translates to:
  /// **'Qualifikation'**
  String get documentTypeQualification;

  /// Examples of an accepted qualification.
  ///
  /// In de, this message translates to:
  /// **'Meisterbrief, Zeugnis oder Zertifikat'**
  String get documentTypeQualificationHint;

  /// Name of the insurance document type.
  ///
  /// In de, this message translates to:
  /// **'Versicherung'**
  String get documentTypeInsurance;

  /// Explains which insurance is meant.
  ///
  /// In de, this message translates to:
  /// **'Haftpflichtversicherung für deine Tätigkeit'**
  String get documentTypeInsuranceHint;

  /// Name of the catch-all document type.
  ///
  /// In de, this message translates to:
  /// **'Sonstiger Nachweis'**
  String get documentTypeOther;

  /// Explains the catch-all document type.
  ///
  /// In de, this message translates to:
  /// **'Ein Nachweis, der in keine andere Kategorie passt'**
  String get documentTypeOtherHint;

  /// Shown when a request never came back, instead of leaving a spinner running.
  ///
  /// In de, this message translates to:
  /// **'Das hat zu lange gedauert. Bitte prüf deine Verbindung und versuch es noch einmal.'**
  String get errorTimedOut;

  /// The team has taken the document in hand.
  ///
  /// In de, this message translates to:
  /// **'Dieser Nachweis wird gerade geprüft und kann nicht ersetzt werden.'**
  String get errorDocumentLocked;

  /// The chosen file is over the size limit.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist zu groß. Bitte lade höchstens 10 MB hoch.'**
  String get errorDocumentTooLarge;

  /// The chosen file is not a document format the backend accepts.
  ///
  /// In de, this message translates to:
  /// **'Dieses Dateiformat geht nicht. Erlaubt sind PDF, JPG, PNG, HEIC und WEBP.'**
  String get errorDocumentTypeNotAllowed;

  /// The request already carries the most photos it may.
  ///
  /// In de, this message translates to:
  /// **'Mehr als sechs Fotos gehen nicht.'**
  String get errorTooManyPhotos;
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
