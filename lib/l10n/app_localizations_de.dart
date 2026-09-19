// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTagline => 'Du brauchst wen? Gleich da.';

  @override
  String get welcomeSubtitle =>
      'Geprüfte Dienstleister in deiner Nähe – schnell gefunden, einfach gebucht.';

  @override
  String get welcomeGetStarted => 'Los geht\'s';

  @override
  String roleSelectionTitle(String appName) {
    return 'Wie möchtest du $appName nutzen?';
  }

  @override
  String get roleCustomerTitle => 'Ich brauche eine Dienstleistung';

  @override
  String get roleCustomerDescription =>
      'Geprüfte Profis in deiner Nähe finden, buchen und bezahlen.';

  @override
  String get roleProviderTitle => 'Ich biete Dienstleistungen an';

  @override
  String get roleProviderDescription =>
      'Aufträge in deiner Umgebung erhalten, Angebote senden und verdienen.';

  @override
  String get roleSwitchHint =>
      'Du kannst den Modus später jederzeit im Profil wechseln.';

  @override
  String get roleSelectionContinue => 'Weiter';

  @override
  String get roleCustomerModeName => 'Kundenmodus';

  @override
  String get roleProviderModeName => 'Anbietermodus';

  @override
  String get tabHome => 'Start';

  @override
  String get tabBookings => 'Buchungen';

  @override
  String get tabMessages => 'Chats';

  @override
  String get tabProfile => 'Profil';

  @override
  String get tabJobs => 'Aufträge';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabEarnings => 'Finanzen';

  @override
  String get customerHomeTitle => 'Was brauchst du?';

  @override
  String get customerHomeMessage =>
      'Bald beschreibst du hier dein Anliegen oder wählst eine Kategorie – und findest geprüfte Profis in deiner Nähe.';

  @override
  String get customerBookingsEmptyTitle => 'Noch keine Buchungen';

  @override
  String get customerBookingsEmptyMessage =>
      'Hier siehst du bald deine Buchungen und Projekte mit ihrem aktuellen Status.';

  @override
  String get conversationsEmptyTitle => 'Noch keine Nachrichten';

  @override
  String get conversationsEmptyMessage =>
      'Hier findest du bald alle Chats zu deinen Aufträgen.';

  @override
  String get providerJobsEmptyTitle => 'Noch keine Aufträge';

  @override
  String get providerJobsEmptyMessage =>
      'Sobald dein Profil geprüft ist, erhältst du hier passende Anfragen und Projekte aus deiner Umgebung.';

  @override
  String get availabilityTitle => 'Deine Verfügbarkeit';

  @override
  String get availabilityMessage =>
      'Hier legst du bald fest, wann du arbeitest, und siehst deine Termine.';

  @override
  String get earningsEmptyTitle => 'Noch keine Einnahmen';

  @override
  String get earningsEmptyMessage =>
      'Hier siehst du bald deine abgeschlossenen Aufträge und Auszahlungen.';

  @override
  String get profileCurrentMode => 'Aktueller Modus';

  @override
  String get profileSwitchToProvider => 'Zum Anbietermodus wechseln';

  @override
  String get profileSwitchToCustomer => 'Zum Kundenmodus wechseln';

  @override
  String get profileAccountComingSoon =>
      'Persönliche Daten und Einstellungen folgen in Kürze.';

  @override
  String get profileSignedInAs => 'Angemeldet als';

  @override
  String get signOut => 'Abmelden';

  @override
  String get loginTitle => 'Anmelden oder registrieren';

  @override
  String get loginEmailIntro =>
      'Gib deine E-Mail-Adresse ein. Wir schicken dir einen Code – ganz ohne Passwort.';

  @override
  String get loginEmailLabel => 'E-Mail-Adresse';

  @override
  String get loginSendCode => 'Code senden';

  @override
  String get loginCodeTitle => 'Code eingeben';

  @override
  String loginCodeIntro(String email) {
    return 'Wir haben dir einen Code an $email geschickt. Schau auch im Spam-Ordner nach.';
  }

  @override
  String get loginCodeLabel => 'Code aus der E-Mail';

  @override
  String get loginVerifyCode => 'Bestätigen';

  @override
  String get loginResendCode => 'Code erneut senden';

  @override
  String get loginCodeResent => 'Neuer Code ist unterwegs.';

  @override
  String get loginChangeEmail => 'Andere E-Mail-Adresse verwenden';

  @override
  String get errorInvalidEmail => 'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get errorInvalidOrExpiredCode =>
      'Der Code ist falsch oder abgelaufen. Fordere bei Bedarf einen neuen an.';

  @override
  String get errorTooManyRequests =>
      'Zu viele Versuche. Bitte warte kurz und versuche es dann erneut.';

  @override
  String get errorEmailNotAuthorized =>
      'An diese E-Mail-Adresse können wir derzeit keine E-Mails senden.';

  @override
  String get errorUnknown =>
      'Das hat nicht geklappt. Bitte prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get customerHomeInputHint => 'Beschreibe, was du brauchst …';

  @override
  String get customerHomeExamplesLabel => 'Beispiele';

  @override
  String get customerHomeExampleWashingMachine =>
      'Meine Waschmaschine verliert Wasser.';

  @override
  String get customerHomeExampleCleaning =>
      'Ich brauche morgen jemanden zum Putzen.';

  @override
  String get customerHomeExampleTv => 'Jemand soll meinen Fernseher montieren.';

  @override
  String get customerHomeExampleGarden =>
      'Mein Garten muss geschnitten werden.';

  @override
  String get customerHomeContinue => 'Weiter';

  @override
  String get customerHomePopularServices => 'Beliebte Services';

  @override
  String get customerHomeUpcomingBookings => 'Deine nächsten Buchungen';

  @override
  String customerHomeNoBookingsMessage(String appName) {
    return 'Buche deinen ersten Service über $appName.';
  }

  @override
  String get categoryHandyman => 'Handwerker';

  @override
  String get categoryCleaning => 'Reinigung';

  @override
  String get categoryMoving => 'Umzug & Transport';

  @override
  String get categoryCar => 'Auto';

  @override
  String get categoryPets => 'Haustiere';

  @override
  String get categoryBeauty => 'Beauty';

  @override
  String get categoryRenovation => 'Renovierung';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get requestTitle => 'Erzähl uns kurz, was du brauchst';

  @override
  String get requestDescriptionLabel => 'Deine Anfrage';

  @override
  String get requestDescriptionRequired =>
      'Bitte beschreibe kurz, was du brauchst.';

  @override
  String get requestCategoryLabel => 'Kategorie';

  @override
  String get requestCategoryHint =>
      'Optional – die passende Leistung erkennen wir später automatisch.';

  @override
  String get requestLocationLabel => 'Wo wird die Dienstleistung benötigt?';

  @override
  String get requestLocationChoose => 'Standort auswählen';

  @override
  String get requestTimingLabel => 'Wann brauchst du Hilfe?';

  @override
  String get requestTimingAsap => 'So schnell wie möglich';

  @override
  String get requestTimingToday => 'Heute';

  @override
  String get requestTimingTomorrow => 'Morgen';

  @override
  String get requestTimingPickDate => 'Datum auswählen';

  @override
  String get requestPhotosLabel => 'Fotos';

  @override
  String get requestAddPhoto => 'Foto hinzufügen';

  @override
  String get requestSubmit => 'Anfrage erstellen';

  @override
  String get requestSaved => 'Anfrage gespeichert.';

  @override
  String get requestNotSentYet =>
      'Deine Anfrage wird noch nicht an Dienstleister gesendet – das kommt im nächsten Schritt.';

  @override
  String get customerRequestsTitle => 'Deine Anfragen';

  @override
  String get customerRequestsNotSent => 'Noch nicht gesendet';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameMissing => 'Noch nicht hinterlegt';

  @override
  String get profileEdit => 'Profil bearbeiten';

  @override
  String get profileSettings => 'Einstellungen';

  @override
  String get comingSoon => 'Diese Funktion folgt in Kürze.';
}
