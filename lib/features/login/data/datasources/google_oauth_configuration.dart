import '../../../../core/network/api_endpoints.dart';

/// Web OAuth credentials must stay paired with their registered callback.
class GoogleOAuthConfiguration {
  const GoogleOAuthConfiguration({required this.clientId, required this.redirectUri});

  final String clientId;
  final String redirectUri;

  static const production = GoogleOAuthConfiguration(
    clientId: '273718420607-q4dcl17i18nql3s6n7hr31o7m5rvsjkf.apps.googleusercontent.com',
    redirectUri: 'https://app.kaizenteams.ai/auth/google/callback',
  );

  static const development = GoogleOAuthConfiguration(
    clientId: '273718420607-sma08mj14celj9c4dshthl3nbeqttb12.apps.googleusercontent.com',
    redirectUri: 'https://dev.kaizenteams.ai/auth/google/callback',
  );

  static final current = GoogleOAuthConfiguration.forBackend(
    ApiEndPoints.baseUrl,
    clientIdOverride: const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID'),
    redirectUriOverride: const String.fromEnvironment('GOOGLE_OAUTH_REDIRECT_URI'),
  );

  factory GoogleOAuthConfiguration.forBackend(
    String apiBaseUrl, {
    String clientIdOverride = '',
    String redirectUriOverride = '',
  }) {
    final defaults = Uri.parse(apiBaseUrl).host == 'dev-api.kaizenteams.ai'
        ? development
        : production;
    return GoogleOAuthConfiguration(
      clientId: clientIdOverride.trim().isEmpty ? defaults.clientId : clientIdOverride.trim(),
      redirectUri: redirectUriOverride.trim().isEmpty
          ? defaults.redirectUri
          : redirectUriOverride.trim(),
    );
  }

  bool get hasMatchingCallback {
    if (clientId == production.clientId) return redirectUri == production.redirectUri;
    if (clientId == development.clientId) return redirectUri == development.redirectUri;
    return true;
  }
}
