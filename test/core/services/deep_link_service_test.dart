import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/core/services/deep_link_service.dart';
import 'package:sparrowkaizen/features/auth/presentation/pages/forgot_password_screen.dart';
import 'package:sparrowkaizen/features/auth/presentation/pages/set_password_screen.dart';
import 'package:sparrowkaizen/features/auth/presentation/providers/set_password_controller.dart';
import 'package:sparrowkaizen/routes/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const messages = MethodChannel('com.llfbandit.app_links/messages');
  const events = MethodChannel('com.llfbandit.app_links/events');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = DeepLinkService.instance;
  String? initialLink;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    AppManager.instance.updateCurrentRouteName(null);
    initialLink = null;
    messenger.setMockMethodCallHandler(messages, (call) async => initialLink);
    messenger.setMockMethodCallHandler(events, (call) async => null);
  });

  tearDown(() async {
    await service.dispose();
    messenger.setMockMethodCallHandler(messages, null);
    messenger.setMockMethodCallHandler(events, null);
    AppManager.instance.updateCurrentRouteName(null);
  });

  Future<void> openForgotPassword(WidgetTester tester) async {
    await service.initialize();
    final startup = service.consumeStartupTarget(timeout: Duration.zero);
    await tester.pump(const Duration(milliseconds: 1));
    await startup;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        navigatorObservers: [_RouteObserver()],
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(name: AppRouter.forgotPassword),
          ),
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  }

  Future<void> receiveLink(WidgetTester tester, String link) async {
    await messenger.handlePlatformMessage(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope(link),
      (_) {},
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
  }

  for (final host in [
    'app.kaizenteams.ai',
    'dev.kaizenteams.ai',
    'api.kaizenteams.ai',
  ]) {
    testWidgets('$host reset link replaces Forgot Password with Set Password', (
      tester,
    ) async {
      await openForgotPassword(tester);
      await receiveLink(
        tester,
        'https://$host/auth/password-reset/confirm?token=reset-token',
      );

      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(find.byType(SetPasswordScreen), findsOneWidget);
      expect(AppManager.instance.currentRouteName, AppRouter.loginSetPassword);
      final field = find
          .descendant(
            of: find.byType(SetPasswordScreen),
            matching: find.byType(TextField),
          )
          .first;
      expect(
        tester.element(field).read<SetPasswordController>().token,
        'reset-token',
      );
      expect(AppRouter.navigatorKey.currentState!.canPop(), isFalse);
    });
  }

  test('production reset link is available to cold-start navigation', () async {
    initialLink =
        'https://app.kaizenteams.ai/auth/password-reset/confirm/?token=initial-token';
    await service.initialize();
    final target = await service.consumeStartupTarget(timeout: Duration.zero);

    expect(target?.routeName, AppRouter.loginSetPassword);
    expect(
      (target?.arguments as LoginSetPasswordRouteArgs?)?.token,
      'initial-token',
    );
  });

  testWidgets(
    'missing tokens, untrusted hosts and Google callbacks do not open Set Password',
    (tester) async {
      await openForgotPassword(tester);
      for (final link in [
        'https://app.kaizenteams.ai/auth/password-reset/confirm',
        'https://app.kaizenteams.ai/auth/password-reset/confirm?token=',
        'https://example.com/auth/password-reset/confirm?token=reset-token',
        'https://app.kaizenteams.ai/auth/google/callback?code=google-code&state=google-state',
      ]) {
        await receiveLink(tester, link);
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        expect(find.byType(SetPasswordScreen), findsNothing);
      }
    },
  );
}

class _RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppManager.instance.updateCurrentRouteName(route.settings.name);
  }
}
