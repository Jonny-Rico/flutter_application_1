import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_repository.dart';

void main() {
  Future<void> pumpLogin(
    WidgetTester tester,
    FakeAuthRepository repo,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('AUTH-N-02: unknown email shows mapped error', (tester) async {
    final repo = FakeAuthRepository(
      signInError: const AuthFailedException(
        'No account found for this email.',
      ),
    );
    await pumpLogin(tester, repo);

    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'nobody@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No account found for this email.'), findsOneWidget);
  });

  testWidgets('AUTH-N-04: duplicate email shows mapped error', (tester) async {
    final repo = FakeAuthRepository(
      registerError: const AuthFailedException(
        'An account already exists for this email.',
      ),
    );
    await pumpLogin(tester, repo);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'QA User');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'qa.a.familytasks@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');
    await tester.enterText(find.byType(TextFormField).at(3), 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.text('An account already exists for this email.'),
      findsOneWidget,
    );
  });

  testWidgets('AUTH-N-05: reset unknown email uses same success copy', (
    tester,
  ) async {
    final repo = FakeAuthRepository();
    await pumpLogin(tester, repo);

    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'nobody@example.com',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.lastResetEmail, 'nobody@example.com');
    expect(
      find.text('If an account exists for that email, we sent a reset link.'),
      findsOneWidget,
    );
  });
}
