import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/network/api_error.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/features/login/data/datasources/auth_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('logs real HTTP response handling before API errors or JSON decoding', () async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    final messages = <String>[];
    final originalPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = originalPrint);

    var response = http.Response(
      '{"access":"private-access","refresh":"private-refresh"}',
      200,
      headers: {'content-type': 'application/json', 'set-cookie': 'private-cookie'},
    );
    final client = MockClient((_) async => response);
    addTearDown(client.close);
    await http.runWithClient(() async {
      final source = AuthRemoteDataSource();
      Future<void> exchange() async {
        await source.loginWithGoogle(
          code: 'visible-code',
          redirectUri: 'https://example.com/auth/google/callback',
        );
      }

      await exchange();
      expect(messages.join('\n'), contains('backend.tokens_validated'));
      expect(messages.join('\n'), contains('"code":"visible-code"'));
      expect(messages.join('\n'), isNot(contains('private-')));

      messages.clear();
      response = http.Response('{"error":"invalid_google_code"}', 400);
      await expectLater(exchange(), throwsA(isA<ApiError>()));
      final failedOutput = messages.join('\n');
      expect(failedOutput, contains('"status_code":400'));
      expect(failedOutput, contains('invalid_google_code'));
      expect(
        failedOutput.indexOf('backend.response'),
        lessThan(failedOutput.indexOf('backend.error')),
      );

      messages.clear();
      response = http.Response('<html>Upstream unavailable</html>', 503);
      await expectLater(exchange(), throwsA(isA<ApiError>()));
      expect(messages.join('\n'), contains('Upstream unavailable'));
      expect(messages.join('\n'), contains('"status_code":503'));

      messages.clear();
      response = http.Response('malformed JSON response', 200);
      await expectLater(exchange(), throwsA(isA<FormatException>()));
      expect(messages.join('\n'), contains('malformed JSON response'));
      expect(messages.join('\n'), contains('FormatException'));
    }, () => client);
  });
}
