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
      'Anmeldung, persönliche Daten und Einstellungen folgen in Kürze.';

  @override
  String get profileRestartOnboarding =>
      'Onboarding neu starten (nur Testversion)';
}
