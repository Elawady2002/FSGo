/// Environment configuration for sensitive credentials.
/// Values are injected at compile-time via --dart-define-from-file=.env
class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isValid =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get validationError {
    if (supabaseUrl.isEmpty) return 'SUPABASE_URL is not configured';
    if (supabaseAnonKey.isEmpty) return 'SUPABASE_ANON_KEY is not configured';
    return '';
  }
}
