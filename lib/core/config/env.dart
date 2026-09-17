/// Build-time configuration, passed in with
/// `flutter run --dart-define-from-file=env/dev.json`.
///
/// Values are never written in code or committed to Git: `env/*.json` is
/// ignored, only `env/*.example.json` is shared. Only public client values
/// belong here (the Supabase publishable key is public by design and protected
/// by row level security). Secret or service_role keys must never be added.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
