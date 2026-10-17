abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const mapTileUrlTemplate = String.fromEnvironment('MAP_TILE_URL_TEMPLATE');
  static const mapTileApiKey = String.fromEnvironment('MAP_TILE_API_KEY');

  static const _shareBaseUrl = String.fromEnvironment('SHARE_BASE_URL');

  /// Base of shared trip links (`<base>/t/<token>`). Reserved `.example`
  /// placeholder until a domain is chosen (research R10).
  static String get shareBaseUrl => _shareBaseUrl.isEmpty ? 'https://goora.example' : _shareBaseUrl;

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
