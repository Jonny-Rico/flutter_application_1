import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  installE2eErrorGuards();

  testWidgets(
    'AUTH-P-01 / TASK-P-01: A signs in and creates a task',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      await ensureLoggedOut(tester);
      await loginWithEmail(tester, email: qaAEmail, password: qaAPassword);

      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.byTooltip('New task'));
      await waitFor(tester, find.widgetWithText(FilledButton, 'Create task'));

      final title = 'autotest-task-${DateTime.now().millisecondsSinceEpoch}';
      await enterField(tester, find.byType(TextField).first, title);
      await tester.tap(find.widgetWithText(FilledButton, 'Create task'));
      await waitFor(
        tester,
        find.text(title),
        timeout: const Duration(seconds: 25),
      );
    },
  );

  testWidgets(
    'AUTH-P-04 / FAM-N-01: B signs in and rejects bad invite',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      await ensureLoggedOut(tester);
      await loginWithEmail(tester, email: qaBEmail, password: qaBPassword);

      await tapNavTab(tester, 'Family');
      await waitForAny(tester, [
        find.text('Join with code'),
        find.text('Invite member'),
        find.text('Leave group'),
        find.text('Dissolve group'),
        find.text('Verify email to use Family'),
      ]);
      // Profile can land on the empty state before the group snapshot arrives.
      await tester.pump(const Duration(seconds: 2));

      if (find.text('Join with code').evaluate().isEmpty) {
        expect(find.text('Family Group'), findsWidgets);
        return;
      }

      await enterField(
        tester,
        find.widgetWithText(TextField, 'Invite code'),
        'XXXXXX',
      );
      await tapWhenVisible(tester, find.text('Join with code'));
      await waitFor(
        tester,
        find.textContaining('Invalid'),
        timeout: const Duration(seconds: 20),
      );
    },
  );

  testWidgets(
    'AUTH-P-03: sign out returns to login',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      failIfLocked();
      await waitForAny(tester, [
        find.text('Sign in with email'),
        find.byType(NavigationBar),
      ]);
      if (find.text('Sign in with email').evaluate().isNotEmpty) {
        await loginWithEmail(tester, email: qaAEmail, password: qaAPassword);
      }
      await tapNavTab(tester, 'Settings');
      await waitFor(tester, find.widgetWithText(AppBar, 'Settings'));
      await tapWhenVisible(tester, find.byKey(const ValueKey('sign-out-button')));
      await waitFor(
        tester,
        find.text('Sign in with email'),
        timeout: const Duration(seconds: 30),
      );
      expect(find.text('Sign in with email'), findsOneWidget);
    },
  );
}
