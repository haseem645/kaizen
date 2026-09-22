import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/login/google_sign_in_diagnostics.dart';

void main() {
  final messages = <String>[];
  setUp(messages.clear);

  test('shows callback code while masking tokens, state, cookies, and email', () {
    addTearDown(_captureLogs(messages));
    GoogleSignInDiagnostics.log(
      'backend.response',
      data: {
        'status_code': 400,
        'headers': {'set-cookie': 'private-cookie', 'content-type': 'application/json'},
        'body':
            '{"error":"invalid_grant","tokens":{"access":"private-access",'
            '"refresh_token":"private-refresh"},"email":"member@example.com"}',
        'url': Uri.parse('https://example.com/callback?code=visible-code&state=private-state'),
        'has_access_token': true,
      },
    );
    final output = messages.join('\n');
    expect(output, contains('invalid_grant'));
    expect(output, contains('application/json'));
    expect(output, contains('"status_code":400'));
    expect(output, contains('"has_access_token":true'));
    expect(output, contains('code=visible-code'));
    expect(output, isNot(contains('private-')));
    expect(output, isNot(contains('member@example.com')));
  });

  test('shows code in non-JSON errors while masking tokens and state', () {
    addTearDown(_captureLogs(messages));
    GoogleSignInDiagnostics.log(
      'backend.error',
      data: {'body': '<html>Bad gateway; code=visible-code&state=private-state</html>'},
      error: StateError('invalid_grant access_token=private-token'),
      stackTrace: StackTrace.fromString('login_fixture.dart:42'),
    );
    final output = messages.join('\n');
    expect(output, contains('Bad gateway'));
    expect(output, contains('invalid_grant'));
    expect(output, contains('login_fixture.dart:42'));
    expect(output, contains('code=visible-code'));
    expect(output, isNot(contains('private-')));
  });

  testWidgets('pending stages report every 15 seconds and stop after completion', (tester) async {
    final restorePrint = _captureLogs(messages);
    try {
      final pending = Completer<String>();
      final result = GoogleSignInDiagnostics.trace('authorization', () => pending.future);
      await tester.pump(const Duration(seconds: 15));
      expect(messages.where((line) => line.contains('authorization.waiting')), hasLength(1));
      pending.complete('done');
      await tester.pump();
      expect(await result, 'done');
      final logCount = messages.length;
      await tester.pump(const Duration(seconds: 30));
      expect(messages, hasLength(logCount));
      expect(messages.last, contains('authorization.complete'));
    } finally {
      restorePrint();
    }
  });

  testWidgets('failed stages rethrow and stop their waiting timer', (tester) async {
    final restorePrint = _captureLogs(messages);
    try {
      final failure = StateError('test failure');
      final result = GoogleSignInDiagnostics.trace<void>(
        'backend_exchange',
        () async => throw failure,
      );
      await expectLater(result, throwsA(same(failure)));
      final logCount = messages.length;
      await tester.pump(const Duration(seconds: 30));
      expect(messages, hasLength(logCount));
      expect(messages.join('\n'), contains('backend_exchange.failed'));
    } finally {
      restorePrint();
    }
  });
}

VoidCallback _captureLogs(List<String> messages) {
  final originalPrint = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message != null) messages.add(message);
  };
  return () => debugPrint = originalPrint;
}
