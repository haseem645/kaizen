import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/google_authorization.dart';

/// Uses the browser and the app's verified HTTPS callback for the web code flow.
class GoogleAuthorizationDataSource {
  GoogleAuthorizationDataSource({
    this.clientId = const String.fromEnvironment(
      'GOOGLE_OAUTH_CLIENT_ID',
      // Public web client used by dev.kaizenteams.ai; this is not a client secret.
      defaultValue: '273718420607-sma08mj14celj9c4dshthl3nbeqttb12.apps.googleusercontent.com',
    ),
    this.redirectUri = const String.fromEnvironment(
      'GOOGLE_OAUTH_REDIRECT_URI',
      defaultValue: 'https://dev.kaizenteams.ai/auth/google/callback',
    ),
    Stream<Uri>? callbackUris,
    Future<bool> Function(Uri)? launchBrowser,
    bool? isSupported,
    this.timeout = const Duration(minutes: 3),
  }) : _callbackUris = callbackUris,
       _launchBrowser = launchBrowser ?? _openBrowser,
       _isSupported =
           isSupported ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.iOS));

  final String clientId;
  final String redirectUri;
  final Duration timeout;
  final Stream<Uri>? _callbackUris;
  final Future<bool> Function(Uri) _launchBrowser;
  final bool _isSupported;
  Completer<GoogleAuthorization?>? _pending;

  Future<GoogleAuthorization?> authorize() async {
    final callback = Uri.tryParse(redirectUri);
    if (!_isSupported ||
        _pending != null ||
        clientId.trim().isEmpty ||
        callback == null ||
        callback.scheme != 'https' ||
        callback.host.isEmpty ||
        callback.hasQuery ||
        callback.hasFragment ||
        callback.userInfo.isNotEmpty) {
      throw const GoogleAuthorizationException(GoogleAuthorizationFailure.unavailable);
    }

    final random = Random.secure();
    final state = base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)));
    final result = Completer<GoogleAuthorization?>();
    _pending = result;
    StreamSubscription<Uri>? subscription;
    Timer? timer;

    try {
      subscription = (_callbackUris ?? AppLinks().uriLinkStream).listen(
        (uri) => _handleCallback(uri, callback, state, result),
        onError: (Object _) => _fail(result, GoogleAuthorizationFailure.unavailable),
      );
      timer = Timer(timeout, () => _fail(result, GoogleAuthorizationFailure.timedOut));
      final authorizationUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'prompt': 'select_account',
        'state': state,
      });
      unawaited(_launch(authorizationUri, result));
      return await result.future;
    } finally {
      timer?.cancel();
      await subscription?.cancel();
      _pending = null;
    }
  }

  void cancel() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  Future<void> _launch(Uri uri, Completer<GoogleAuthorization?> result) async {
    try {
      if (!await _launchBrowser(uri)) _fail(result, GoogleAuthorizationFailure.unavailable);
    } catch (_) {
      _fail(result, GoogleAuthorizationFailure.unavailable);
    }
  }

  void _handleCallback(
    Uri uri,
    Uri callback,
    String expectedState,
    Completer<GoogleAuthorization?> result,
  ) {
    if (result.isCompleted ||
        uri.scheme != callback.scheme ||
        uri.host != callback.host ||
        uri.port != callback.port ||
        uri.path != callback.path ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return;
    }

    final states = uri.queryParametersAll['state'];
    // Ignore unsolicited or stale callbacks, including links from a prior attempt.
    if (states == null || states.length != 1 || states.single != expectedState) return;

    final errors = uri.queryParametersAll['error'];
    if (errors != null) {
      if (errors.length == 1 && errors.single == 'access_denied') {
        result.complete(null);
      } else {
        _fail(result, GoogleAuthorizationFailure.invalidResponse);
      }
      return;
    }
    final codes = uri.queryParametersAll['code'];
    if (codes == null || codes.length != 1 || codes.single.trim().isEmpty) {
      _fail(result, GoogleAuthorizationFailure.invalidResponse);
      return;
    }
    result.complete(GoogleAuthorization(code: codes.single, redirectUri: redirectUri));
  }

  static void _fail(Completer<GoogleAuthorization?> result, GoogleAuthorizationFailure failure) {
    if (!result.isCompleted) result.completeError(GoogleAuthorizationException(failure));
  }

  static Future<bool> _openBrowser(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}
