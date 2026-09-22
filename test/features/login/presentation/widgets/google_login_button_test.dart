import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';
import 'package:sparrowkaizen/features/login/presentation/pages/login_screen.dart';
import 'package:sparrowkaizen/features/login/presentation/widgets/google_login_button.dart';

void main() {
  testWidgets('Google button starts sign-in and blocks taps while loading', (tester) async {
    var taps = 0;
    Future<void> mount(bool isLoading) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleLoginButton(isLoading: isLoading, onPressed: () => taps++),
        ),
      ),
    );
    await mount(false);
    await tester.tap(find.text(AppStrings.loginContinueWithGoogle));
    expect(taps, 1);
    await mount(true);
    await tester.tap(find.text(AppStrings.loginContinueWithGoogle));
    expect(taps, 1);
    expect(find.byType(FastCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Login, OR, and Google stay ordered and scrollable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    );
    await tester.pump();
    final login = find.text(AppStrings.loginButton);
    final separator = find.text(AppStrings.loginAlternativeSeparator);
    final google = find.text(AppStrings.loginContinueWithGoogle);
    expect(tester.getTopLeft(login).dy, lessThan(tester.getTopLeft(separator).dy));
    expect(tester.getTopLeft(separator).dy, lessThan(tester.getTopLeft(google).dy));
    await tester.ensureVisible(google);
    await tester.pump();
    expect(google.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
