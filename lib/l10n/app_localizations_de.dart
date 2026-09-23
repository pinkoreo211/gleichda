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
      'Nach dem Speichern zeigen wir dir passende Anbieter. Gesendet wird erst, wenn du einen auswählst.';

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

  @override
  String get catalogLoading => 'Services werden geladen …';

  @override
  String get catalogErrorMessage => 'Services konnten nicht geladen werden.';

  @override
  String get catalogRetry => 'Erneut versuchen';

  @override
  String get catalogEmptyTitle => 'Keine Services verfügbar';

  @override
  String get catalogEmptyMessage =>
      'Momentan sind keine Services verfügbar. Schau später noch einmal vorbei.';

  @override
  String get categoryServicesEmptyMessage =>
      'In dieser Kategorie gibt es noch keine Leistungen.';

  @override
  String servicePriceFrom(String price) {
    return 'ab $price';
  }

  @override
  String get serviceQuoteBadge => 'Angebot';

  @override
  String get servicePriceOptionsTitle => 'Preisoptionen';

  @override
  String get serviceQuoteHint =>
      'Für diese Leistung erstellst du eine Anfrage und erhältst passende Angebote.';

  @override
  String get servicePricesExampleHint =>
      'Beispielpreise. Der endgültige Preis wird mit dem Dienstleister vereinbart.';

  @override
  String get serviceContinue => 'Weiter';

  @override
  String get serviceNotFound => 'Diese Leistung ist nicht mehr verfügbar.';

  @override
  String serviceDurationMinutes(int minutes) {
    return 'ca. $minutes Min.';
  }

  @override
  String providerOnboardingStep(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get providerPersonalTitle => 'Erzähl uns kurz etwas über dich.';

  @override
  String get providerFirstNameLabel => 'Vorname';

  @override
  String get providerLastNameLabel => 'Nachname';

  @override
  String get providerPhotoAdd => 'Profilbild hinzufügen';

  @override
  String get providerBusinessTitle =>
      'Arbeitest du selbstständig oder für ein Unternehmen?';

  @override
  String get providerKindSelfEmployed => 'Selbstständig';

  @override
  String get providerKindCompany => 'Unternehmen';

  @override
  String get providerCompanyNameLabel => 'Firmenname';

  @override
  String get providerTradingNameLabel => 'Name deines Betriebs';

  @override
  String get providerServicesTitle => 'Welche Leistungen bietest du an?';

  @override
  String get providerServicesHint =>
      'Wähle alles aus, was du anbietest. Du kannst das später jederzeit ändern.';

  @override
  String get providerAreaTitle => 'Wo möchtest du Aufträge annehmen?';

  @override
  String get providerCityLabel => 'Stadt';

  @override
  String get providerPostalCodeLabel => 'Postleitzahl';

  @override
  String providerRadiusLabel(int km) {
    return 'Umkreis: $km km';
  }

  @override
  String get providerFinishTitle => 'Fast geschafft.';

  @override
  String get providerFinishMessage =>
      'Dein Profil ist angelegt. Sobald es Aufträge in deiner Nähe gibt, siehst du sie in deinem Bereich.';

  @override
  String get providerFinishButton => 'Profil fertigstellen';

  @override
  String get providerBack => 'Zurück';

  @override
  String get providerVerificationTitle => 'Verifizierung';

  @override
  String get providerVerificationUnverified => 'Nicht verifiziert';

  @override
  String get providerVerificationPending => 'In Prüfung';

  @override
  String get providerVerificationVerified => 'Verifiziert';

  @override
  String get providerVerificationRejected => 'Abgelehnt';

  @override
  String get providerVerificationExplanation =>
      'Wir prüfen deine Nachweise, bevor dich Kundinnen und Kunden als geprüft sehen. Welche Nachweise nötig sind, hängt von deinen Leistungen ab. Das Hochladen folgt in Kürze.';

  @override
  String providerHomeGreeting(String name) {
    return 'Hallo, $name';
  }

  @override
  String get providerHomeGreetingPlain => 'Hallo';

  @override
  String get providerHomeSubtitle => 'Bereit für deinen nächsten Auftrag?';

  @override
  String get providerHomeNoJobs => 'Du hast noch keine Aufträge.';

  @override
  String get providerHomeMyServices => 'Meine Leistungen';

  @override
  String get providerHomeAvailability => 'Meine Verfügbarkeit';

  @override
  String providerServicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Leistungen',
      one: '1 Leistung',
      zero: 'Noch keine Leistung ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get errorFirstNameRequired => 'Bitte gib deinen Vornamen ein.';

  @override
  String get errorLastNameRequired => 'Bitte gib deinen Nachnamen ein.';

  @override
  String get errorBusinessNameRequired =>
      'Bitte gib den Namen deines Betriebs ein.';

  @override
  String get errorServicesRequired =>
      'Bitte wähle mindestens eine Leistung aus.';

  @override
  String get errorCityRequired => 'Bitte gib deine Stadt ein.';

  @override
  String get providerAddService => 'Leistung hinzufügen';

  @override
  String get providerEdit => 'Bearbeiten';

  @override
  String get providerNoPriceYet => 'Noch kein Preis hinterlegt';

  @override
  String get providerPricingTitle => 'Preisgestaltung';

  @override
  String get providerAddPrice => 'Preisoption hinzufügen';

  @override
  String get providerPriceNameLabel => 'Bezeichnung';

  @override
  String get providerPriceAmountLabel => 'Preis in Euro';

  @override
  String get providerPriceUnitLabel => 'Einheit';

  @override
  String get providerPriceDurationLabel => 'Dauer in Minuten';

  @override
  String get providerPriceSave => 'Speichern';

  @override
  String get providerPriceDeactivate => 'Deaktivieren';

  @override
  String get providerPriceActivate => 'Aktivieren';

  @override
  String get providerPriceDelete => 'Löschen';

  @override
  String get providerPriceInactive => 'Deaktiviert';

  @override
  String get providerQuoteNoPriceNeeded =>
      'Für diese Leistung brauchst du keinen Fixpreis. Kunden fordern ein Angebot an.';

  @override
  String get providerPricesEmpty =>
      'Du hast für diese Leistung noch keinen Preis hinterlegt.';

  @override
  String get providerServicesEmpty => 'Du bietest noch keine Leistungen an.';

  @override
  String get errorPriceNameRequired => 'Bitte gib eine Bezeichnung ein.';

  @override
  String get errorPriceInvalid => 'Bitte gib einen gültigen Preis ein.';

  @override
  String get providerMatchesTitle => 'Anbieter für diese Leistung';

  @override
  String get providerMatchesShow => 'Anbieter anzeigen';

  @override
  String get providerMatchesEmptyTitle => 'Noch niemand verfügbar';

  @override
  String get providerMatchesEmptyMessage =>
      'Für diese Leistung ist noch kein Dienstleister eingetragen. Deine Anfrage bleibt gespeichert — sobald sich jemand einträgt, findest du ihn hier.';

  @override
  String get providerUnnamed => 'Dienstleister';

  @override
  String get providerNoPriceGiven => 'Preis auf Anfrage';

  @override
  String get requestCityLabel => 'Ort';

  @override
  String get requestCityPlaceholder => 'z. B. Wien';

  @override
  String get requestPostalCodeLabel => 'PLZ';

  @override
  String get requestLocationHint =>
      'Ohne Ort zeigen wir dir Anbieter aus allen Orten.';

  @override
  String get requestMatchesTitle => 'Passende Anbieter';

  @override
  String get requestMatchesNoServiceTitle => 'Noch keine Leistung gewählt';

  @override
  String get requestMatchesNoServiceMessage =>
      'Diese Anfrage nennt noch keine konkrete Leistung. Wähle eine Leistung im Katalog, dann suchen wir passende Anbieter.';

  @override
  String get providerMatchSend => 'Anfrage senden';

  @override
  String get providerMatchSent => 'Anfrage gesendet';

  @override
  String requestSentToProvider(String name) {
    return 'Deine Anfrage ging an $name.';
  }

  @override
  String get customerRequestsShowProviders => 'Passende Anbieter';

  @override
  String customerRequestsSentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'An $count Anbieter gesendet',
      one: 'An 1 Anbieter gesendet',
      zero: 'Noch nicht gesendet',
    );
    return '$_temp0';
  }

  @override
  String get providerIncomingTitle => 'Anfragen an dich';

  @override
  String get providerIncomingEmpty =>
      'Du hast noch keine Anfragen erhalten. Sobald dich jemand anfragt, steht sie hier.';

  @override
  String providerIncomingFrom(String name) {
    return 'von $name';
  }

  @override
  String get providerIncomingCustomerUnknown => 'Kundin oder Kunde';

  @override
  String providerIncomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anfragen',
      one: '1 Anfrage',
      zero: 'Keine Anfragen',
    );
    return '$_temp0';
  }

  @override
  String get providerIncomingAccept => 'Annehmen';

  @override
  String get providerIncomingDecline => 'Ablehnen';

  @override
  String get providerIncomingAccepted => 'Du hast angenommen';

  @override
  String get providerIncomingDeclined => 'Du hast abgelehnt';

  @override
  String get providerIncomingAcceptedToast => 'Anfrage angenommen.';

  @override
  String get providerIncomingDeclinedToast => 'Anfrage abgelehnt.';

  @override
  String get providerIncomingChatHint =>
      'Den Termin stimmst du im Chat direkt mit der Kundin oder dem Kunden ab.';

  @override
  String get requestStatusOpen => 'Noch offen';

  @override
  String get requestStatusAccepted => 'Angenommen';

  @override
  String get requestStatusDeclined => 'Abgelehnt';

  @override
  String customerRequestsAcceptedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anbieter haben angenommen',
      one: '1 Anbieter hat angenommen',
    );
    return '$_temp0';
  }

  @override
  String customerRequestsDeclinedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anbieter haben abgelehnt',
      one: '1 Anbieter hat abgelehnt',
    );
    return '$_temp0';
  }

  @override
  String get errorRequestAlreadyAnswered =>
      'Diese Anfrage wurde bereits beantwortet.';

  @override
  String get errorMessageEmpty => 'Die Nachricht ist leer.';

  @override
  String get chatOtherUnknown => 'Chat';

  @override
  String get chatNoAppointment => 'Termin noch nicht vereinbart';

  @override
  String get chatMessageHint => 'Nachricht schreiben …';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatEmptyTitle => 'Noch keine Nachrichten';

  @override
  String get chatEmptyMessage =>
      'Schreib die erste Nachricht, um den Termin abzustimmen.';

  @override
  String get chatLoadFailed => 'Chat konnte nicht geladen werden.';

  @override
  String get chatWithProvider => 'Dienstleister kontaktieren';

  @override
  String get chatWithCustomer => 'Kunde kontaktieren';
}
