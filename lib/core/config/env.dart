abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const mapTileUrlTemplate = String.fromEnvironment('MAP_TILE_URL_TEMPLATE');
  static const mapTileApiKey = String.fromEnvironment('MAP_TILE_API_KEY');

  /// `fake` (default), `whatsapp`, `firebase` or `sms`; see OtpProviderKind.
  static const otpProvider = String.fromEnvironment('OTP_PROVIDER');

  static const _shareBaseUrl = String.fromEnvironment('SHARE_BASE_URL');

  /// Base of shared trip links (`<base>/t/<token>`). Reserved `.example`
  /// placeholder until a domain is chosen (research R10).
  static String get shareBaseUrl => _shareBaseUrl.isEmpty ? 'https://goora.example' : _shareBaseUrl;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// `--dart-define=BACKEND_LIVE=true` asks for the real backend (011 research D1).
  static const backendLiveRequested = bool.fromEnvironment('BACKEND_LIVE');

  /// The real backend only when asked for AND both Supabase settings are set;
  /// otherwise every repository is the on-device fake, as before 011.
  static bool get backendLive => backendLiveRequested && hasSupabase;
}
