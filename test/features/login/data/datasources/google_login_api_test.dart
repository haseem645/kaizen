import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/network/api_endpoints.dart';
import 'package:sparrowkaizen/core/network/api_error.dart';
import 'package:sparrowkaizen/core/network/api_processor.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:sparrowkaizen/features/login/data/datasources/google_authorization_data_source.dart';
import 'package:sparrowkaizen/features/login/data/datasources/google_oauth_configuration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final backend in ['https://api.kaizenteams.ai', 'https://dev-api.kaizenteams.ai']) {
    test('authorization and backend exchange preserve the same callback for $backend', () async {
      final config = GoogleOAuthConfiguration.forBackend(backend);
      final callbacks = StreamController<Uri>.broadcast(sync: true);
      addTearDown(callbacks.close);
      Uri? request;
      final source = GoogleAuthorizationDataSource(
        clientId: config.clientId,
        redirectUri: config.redirectUri,
        isSupported: true,
        callbackUris: callbacks.stream,
        launchBrowser: (uri) async {
          request = uri;
          callbacks.add(
            Uri.parse(config.redirectUri).replace(
              queryParameters: {'code': 'fresh-code', 'state': uri.queryParameters['state']!},
            ),
          );
          return true;
        },
      );
      final authorization = await source.authorize();
      final api = _LoginApi({'access': 'app-access', 'refresh': 'app-refresh'});
      await AuthRemoteDataSource(
        apiCallExecutor: api,
      ).loginWithGoogle(code: authorization!.code, redirectUri: authorization.redirectUri);
      expect(request!.queryParameters['client_id'], config.clientId);
      expect(api.parameters, {
        'code': 'fresh-code',
        'redirect_uri': request!.queryParameters['redirect_uri'],
      });
    });
  }

  test('Google code exchange uses the public endpoint and decodes both app tokens', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    await AppPreference.setUseParentApiEndpoints(true);
    addTearDown(() => AppPreference.setUseParentApiEndpoints(false));
    final api = _LoginApi({'access': 'app-access', 'refresh': 'app-refresh'});
    final response = await AuthRemoteDataSource(apiCallExecutor: api).loginWithGoogle(
      code: 'one-time-code',
      redirectUri: 'https://app.kaizenteams.ai/auth/google/callback',
    );
    expect(api.endpoint, 'accounts/google/login/');
    expect(ApiEndPoints.resolveEndpoint(api.endpoint!), 'accounts/google/login/');
    expect(api.parameters, {
      'code': 'one-time-code',
      'redirect_uri': 'https://app.kaizenteams.ai/auth/google/callback',
    });
    expect(api.authToken, '');
    expect(api.autoRefresh, isFalse);
    expect(api.conflictRetry, isFalse);
    expect(response.access, 'app-access');
    expect(response.refresh, 'app-refresh');
  });

  test('a callback override is preserved exactly during the code exchange', () async {
    const redirectUri = 'https://login.example.com/mobile/google/callback/';
    final api = _LoginApi({'access': 'app-access', 'refresh': 'app-refresh'});
    await AuthRemoteDataSource(
      apiCallExecutor: api,
    ).loginWithGoogle(code: 'one-time-code', redirectUri: redirectUri);
    expect(api.parameters?['redirect_uri'], redirectUri);
  });

  test('missing, empty, and non-string token responses are rejected', () async {
    for (final response in <dynamic>[
      null,
      {'access': 'access'},
      {'access': '', 'refresh': 'refresh'},
      {'access': 'access', 'refresh': 42},
    ]) {
      await expectLater(
        AuthRemoteDataSource(apiCallExecutor: _LoginApi(response)).loginWithGoogle(
          code: 'test-code',
          redirectUri: 'https://dev.kaizenteams.ai/auth/google/callback',
        ),
        throwsA(isA<ApiError>()),
      );
    }
  });
}

class _LoginApi extends ApiCallExecutor {
  _LoginApi(this.response);

  final dynamic response;
  String? endpoint;
  String? authToken;
  Map<String, dynamic>? parameters;
  bool? autoRefresh;
  bool? conflictRetry;

  @override
  Future<Response> processApi<Response>({
    required ApiCallType apiCallType,
    required String endpoint,
    required Response Function(dynamic json) decoder,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    String? authToken,
    bool allowAutoRefresh = true,
    bool allowConflictRetry = true,
    bool invalidateCacheBeforeRequest = false,
  }) async {
    expect(apiCallType, ApiCallType.post);
    this.endpoint = endpoint;
    this.authToken = authToken;
    this.parameters = parameters;
    autoRefresh = allowAutoRefresh;
    conflictRetry = allowConflictRetry;
    return decoder(response);
  }
}
