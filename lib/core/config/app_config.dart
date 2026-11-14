/// Build-time configuration, passed with `--dart-define`:
///
/// ```
/// flutter build web \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ... \
///   --dart-define=SITE_URL=https://seu-dominio.com
/// ```
///
/// Without the Supabase values the app falls back to the on-device account
/// (no e-mail features), so it keeps running in development and tests.
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Public address where the PWA is served. Used as the destination of the
  /// password-recovery link. Falls back to the current origin on the web.
  static const siteUrl = String.fromEnvironment('SITE_URL');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
