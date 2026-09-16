import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/login/data/datasources/google_authorization_data_source.dart';
import 'package:sparrowkaizen/features/login/domain/entities/google_authorization.dart';

void main() {
  test('callback diagnostics explain ignored state and preserve Google errors', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final messages = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = originalPrint);
    final pending = harness.source.authorize();
    final expectation = expectLater(pending, throwsA(isA<GoogleAuthorizationException>()));
    harness.callbacks.add(harness.callback().replace(queryParameters: {'code': 'visible-code'}));
    harness.callbacks.add(
      harness.callback().replace(
        queryParameters: {
          'state': harness.requests.last.queryParameters['state']!,
          'error': 'invalid_request',
          'error_description': 'Redirect URI rejected',
        },
      ),
    );
    await expectation;
    final output = messages.join('\n');
    expect(output, contains('callback.received'));
    expect(output, contains('missing_duplicate_or_stale_state'));
    expect(output, contains('google.error'));
    expect(output, contains('Redirect URI rejected'));
    expect(output, contains('"code":["visible-code"]'));
    expect(output, isNot(contains(harness.requests.last.queryParameters['state']!)));
  });

  test('browser request and backend exchange use the same redirect and a fresh state', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final first = harness.source.authorize();
    final request = harness.requests.single;
    expect(request.origin, 'https://accounts.google.com');
    expect(request.queryParameters['response_type'], 'code');
    expect(request.queryParameters['scope'], 'openid email profile');
    expect(request.queryParameters['redirect_uri'], harness.source.redirectUri);
    expect(request.queryParameters['state']!.length, greaterThanOrEqualTo(32));
    harness.callbacks.add(harness.callback(code: 'code+/with_underscores'));
    final result = await first;
    expect(result!.code, 'code+/with_underscores');
    expect(result.redirectUri, harness.source.redirectUri);

    final second = harness.source.authorize();
    expect(harness.requests.last.queryParameters['state'], isNot(request.queryParameters['state']));
    harness.source.cancel();
    expect(await second, isNull);
  });

  test('wrong origin, path, missing state, and stale state cannot complete login', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    var completed = false;
    final result = harness.source.authorize()..then((_) => completed = true);
    final callback = harness.callback();
    harness.callbacks.add(callback.replace(host: 'example.com'));
    harness.callbacks.add(callback.replace(scheme: 'http'));
    harness.callbacks.add(callback.replace(path: '/auth/google/callback/extra'));
    harness.callbacks.add(callback.replace(queryParameters: {'code': 'unsolicited'}));
    harness.callbacks.add(callback.replace(queryParameters: {'code': 'stale', 'state': 'old'}));
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    harness.callbacks.add(callback);
    expect((await result)!.code, 'test-code');
  });

  test(
    'valid query callbacks accept browser fragments without changing the exchanged code',
    () async {
      final harness = _Harness();
      addTearDown(harness.close);

      for (final fragment in ['', '_=_', 'code=fragment-code&state=fragment-state']) {
        final pending = harness.source.authorize();
        final callback = harness.callback(code: 'query-code');
        final responseUri = callback.replace(
          queryParameters: {
            ...callback.queryParameters,
            'iss': 'https://accounts.google.com',
            'scope': 'openid email profile',
            'authuser': '0',
            'prompt': 'none',
          },
          fragment: fragment,
        );
        expect(responseUri.hasFragment, isTrue);
        harness.callbacks.add(responseUri);

        final authorization = await pending.timeout(const Duration(seconds: 1));
        expect(authorization!.code, 'query-code');
        expect(authorization.redirectUri, harness.source.redirectUri);
        expect(Uri.parse(authorization.redirectUri).hasFragment, isFalse);
      }
    },
  );

  test('fragments cannot supply missing state or override a mismatched callback', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    var completed = false;
    final pending = harness.source.authorize()..then((_) => completed = true);
    final callback = harness.callback();
    final fragmentCredentials = callback.query;

    harness.callbacks.add(callback.replace(host: 'example.com', fragment: '_=_'));
    harness.callbacks.add(callback.replace(scheme: 'http', fragment: '_=_'));
    harness.callbacks.add(callback.replace(port: 444, fragment: '_=_'));
    harness.callbacks.add(callback.replace(path: '/auth/google/other', fragment: '_=_'));
    harness.callbacks.add(callback.replace(userInfo: 'untrusted', fragment: '_=_'));
    harness.callbacks.add(
      callback.replace(queryParameters: {'code': 'query-code'}, fragment: fragmentCredentials),
    );
    harness.callbacks.add(
      callback.replace(
        queryParameters: {'code': 'query-code', 'state': 'stale'},
        fragment: fragmentCredentials,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    harness.callbacks.add(callback);
    expect((await pending)!.code, 'test-code');
  });

  test('a fragment cannot provide the authorization code', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final pending = harness.source.authorize();
    final expectation = expectLater(
      pending,
      throwsA(
        isA<GoogleAuthorizationException>().having(
          (error) => error.reason,
          'reason',
          GoogleAuthorizationFailure.invalidResponse,
        ),
      ),
    );
    harness.callbacks.add(
      harness.callback().replace(
        queryParameters: {'state': harness.requests.last.queryParameters['state']!},
        fragment: 'code=fragment-only-code',
      ),
    );
    await expectation;
  });

  test('denied consent and explicit cancel are silent cancellations', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final denied = harness.source.authorize();
    harness.callbacks.add(
      harness.callback().replace(
        queryParameters: {
          'state': harness.requests.last.queryParameters['state']!,
          'error': 'access_denied',
        },
      ),
    );
    expect(await denied, isNull);
    final canceled = harness.source.authorize();
    harness.source.cancel();
    expect(await canceled, isNull);
  });

  test('duplicate codes in a matching callback fail without returning a credential', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final result = harness.source.authorize();
    final expectation = expectLater(result, throwsA(isA<GoogleAuthorizationException>()));
    harness.callbacks.add(
      harness.callback().replace(
        queryParameters: {
          'state': harness.requests.last.queryParameters['state']!,
          'code': ['first', 'second'],
        },
      ),
    );
    await expectation;
  });

  test('browser launch failure and timeout release the pending attempt', () async {
    final failed = GoogleAuthorizationDataSource(
      isSupported: true,
      callbackUris: const Stream.empty(),
      launchBrowser: (_) async => false,
    );
    await expectLater(failed.authorize(), throwsA(isA<GoogleAuthorizationException>()));
    final timedOut = GoogleAuthorizationDataSource(
      isSupported: true,
      callbackUris: const Stream.empty(),
      launchBrowser: (_) async => true,
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      timedOut.authorize(),
      throwsA(
        isA<GoogleAuthorizationException>().having(
          (error) => error.reason,
          'reason',
          GoogleAuthorizationFailure.timedOut,
        ),
      ),
    );
    await expectLater(timedOut.authorize(), throwsA(isA<GoogleAuthorizationException>()));
  });

  test('late callbacks after cancel cannot authenticate the next attempt', () async {
    final harness = _Harness();
    addTearDown(harness.close);
    final first = harness.source.authorize();
    final staleCallback = harness.callback();
    harness.source.cancel();
    await first;
    var completed = false;
    final second = harness.source.authorize()..then((_) => completed = true);
    harness.callbacks.add(staleCallback);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    harness.callbacks.add(harness.callback(code: 'current-code'));
    expect((await second)!.code, 'current-code');
  });
}

class _Harness {
  _Harness() {
    source = GoogleAuthorizationDataSource(
      isSupported: true,
      callbackUris: callbacks.stream,
      launchBrowser: (uri) async {
        requests.add(uri);
        return true;
      },
    );
  }

  final callbacks = StreamController<Uri>.broadcast(sync: true);
  final requests = <Uri>[];
  late final GoogleAuthorizationDataSource source;

  Uri callback({String code = 'test-code'}) => Uri.parse(
    source.redirectUri,
  ).replace(queryParameters: {'code': code, 'state': requests.last.queryParameters['state']!});

  Future<void> close() async {
    source.cancel();
    await callbacks.close();
  }
}
