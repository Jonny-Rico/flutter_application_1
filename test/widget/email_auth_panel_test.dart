import 'package:family_tasks/features/auth/presentation/widgets/email_auth_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpPanel(
    WidgetTester tester, {
    EmailAuthMode mode = EmailAuthMode.signIn,
    Future<void> Function(String, String)? onSignIn,
    Future<void> Function(String, String, String)? onRegister,
    Future<void> Function(String)? onReset,
    void Function(EmailAuthMode)? onSwitch,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmailAuthPanel(
            mode: mode,
            busy: false,
            onSignIn: onSignIn ?? (_, _) async {},
            onRegister: onRegister ?? (_, _, _) async {},
            onReset: onReset ?? (_) async {},
            onSwitchMode: onSwitch ?? (_) {},
            onBack: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('AUTH-N-03 passwords must match on register', (tester) async {
    var registered = false;
    await pumpPanel(
      tester,
      mode: EmailAuthMode.register,
      onRegister: (_, _, _) async => registered = true,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'QA User');
    await tester.enterText(find.byType(TextFormField).at(1), 'qa@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password1');
    await tester.enterText(find.byType(TextFormField).at(3), 'password2');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(registered, isFalse);
  });

  testWidgets('AUTH-P-05 forgot password submits email', (tester) async {
    String? sent;
    await pumpPanel(
      tester,
      mode: EmailAuthMode.reset,
      onReset: (email) async => sent = email,
    );

    await tester.enterText(
      find.byType(TextFormField),
      'qa.a.familytasks@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();

    expect(sent, 'qa.a.familytasks@example.com');
  });

  testWidgets('AUTH-N-05 reset empty email is blocked', (tester) async {
    var called = false;
    await pumpPanel(
      tester,
      mode: EmailAuthMode.reset,
      onReset: (_) async => called = true,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(called, isFalse);
  });
}
