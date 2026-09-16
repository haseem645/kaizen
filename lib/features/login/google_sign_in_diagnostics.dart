import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Debug-only diagnostics shared by the Google login layers.
class GoogleSignInDiagnostics {
  GoogleSignInDiagnostics._();

  static const _redacted = '[REDACTED]';
  // Keep the OAuth `code` visible for the requested sign-in debugging.
  static final _sensitiveKey = RegExp(
    r'^(authcode|authorizationcode|serverauthcode|codeverifier|state|access|refresh|(?:access|refresh|id|auth|bearer|session)?token|clientsecret|secret|password|authorization|cookie|setcookie|email|loginhint)$',
    caseSensitive: false,
  );
  static const _credentialNames =
      r'(?:state|access|refresh|access_token|refresh_token|id_token|client_secret|password|authorization|cookie|set-cookie)';
  static final _sensitiveText = RegExp(
    r'''((?:["']'''
    '$_credentialNames'
    r'''["']\s*:|\b'''
    '$_credentialNames'
    r'''\s*=)\s*)(?:"[^"]*"|'[^']*'|[^\s&,;}\]<>]+)''',
    caseSensitive: false,
  );

  static void log(
    String event, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    final payload = jsonEncode(
      _sanitize({
        ...data,
        if (error != null) 'exception': error.toString(),
        if (error != null) 'exception_type': error.runtimeType.toString(),
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      }),
    );
    final prefix = '[GoogleSignIn] ${DateTime.now().toIso8601String()} $event';
    // Keep every chunk searchable and below Android's per-message log limit.
    for (var start = 0; start < payload.length; start += 800) {
      final end = start + 800 < payload.length ? start + 800 : payload.length;
      debugPrint('$prefix ${payload.substring(start, end)}');
    }
  }

  /// Reports pending stages without altering their completion or timeout behavior.
  static Future<T> trace<T>(String stage, Future<T> Function() action) async {
    if (!kDebugMode) return action();
    final elapsed = Stopwatch()..start();
    log('$stage.start');
    final waiting = Timer.periodic(const Duration(seconds: 15), (_) {
      log('$stage.waiting', data: {'elapsed_seconds': elapsed.elapsed.inSeconds});
    });
    try {
      final result = await action();
      log('$stage.complete', data: {'elapsed_ms': elapsed.elapsedMilliseconds});
      return result;
    } catch (error, stackTrace) {
      log(
        '$stage.failed',
        data: {'elapsed_ms': elapsed.elapsedMilliseconds},
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      waiting.cancel();
      elapsed.stop();
    }
  }

  static Object? _sanitize(Object? value) {
    if (value is Uri) {
      return value
          .replace(
            userInfo: '',
            fragment: value.hasFragment ? _redacted : null,
            queryParameters: value.hasQuery
                ? value.queryParametersAll.map(
                    (key, values) => MapEntry(
                      key,
                      _isSensitive(key)
                          ? [_redacted]
                          : values.map((value) => _sanitize(value).toString()).toList(),
                    ),
                  )
                : null,
          )
          .toString();
    }
    if (value is Map) {
      return value.map(
        (key, value) =>
            MapEntry(key.toString(), _isSensitive(key.toString()) ? _redacted : _sanitize(value)),
      );
    }
    if (value is Iterable) return value.map(_sanitize).toList();
    if (value is String) {
      // Decode response JSON before masking nested credentials, including errors.
      if (value.trimLeft().startsWith('{') || value.trimLeft().startsWith('[')) {
        try {
          return _sanitize(jsonDecode(value));
        } on FormatException {
          // Preserve non-JSON error bodies for diagnosis, with text masking below.
        }
      }
      return value
          .replaceAllMapped(_sensitiveText, (match) => '${match[1]}$_redacted')
          .replaceAll(RegExp(r'\bBearer\s+\S+', caseSensitive: false), 'Bearer $_redacted')
          .replaceAll(RegExp(r'\beyJ[\w-]+\.[\w-]+\.[\w-]+\b'), _redacted)
          .replaceAll(RegExp(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}'), _redacted);
    }
    if (value == null || value is num || value is bool) return value;
    return _sanitize(value.toString());
  }

  static bool _isSensitive(String key) =>
      _sensitiveKey.hasMatch(key.replaceAll(RegExp(r'[_-]'), ''));
}
