import 'package:family_tasks/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('AUTH-P-01 / UI: email and Google CTAs are visible', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('FamilyTasks'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('AUTH-N-03: register validation blocks empty submit', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
  });

  testWidgets('AUTH-N-01 form: sign-in requires email and password', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
