import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

String? generatedInviteCode;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  installE2eErrorGuards();

  testWidgets(
    'AUTH-N-01 / AUTH-P-05: wrong password and reset copy',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      await ensureLoggedOut(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in with email'));
      await tester.pump(const Duration(milliseconds: 500));
      final fields = find.byType(TextFormField);
      await waitFor(tester, fields);
      await enterField(tester, fields.at(0), qaAEmail);
      await enterField(tester, fields.at(1), 'definitely-wrong-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await waitFor(tester, find.text('Incorrect email or password.'));

      await tester.tap(find.text('Forgot password?'));
      await tester.pump(const Duration(milliseconds: 400));
      await enterField(tester, find.byType(TextFormField).first, qaAEmail);
      await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
      await waitFor(
        tester,
        find.textContaining('If an account exists for that email'),
      );
    },
  );

  testWidgets(
    'FAM-P-01 / FAM-P-02: A has a group and a fresh invite',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      await ensureLoggedOut(tester);
      await loginWithEmail(tester, email: qaAEmail, password: qaAPassword);
      await openFamilySettled(tester);

      if (find.text('Join with code').evaluate().isNotEmpty) {
        final name = 'autotest-fam-${DateTime.now().millisecondsSinceEpoch}';
        await enterField(
          tester,
          find.widgetWithText(TextField, 'Group name'),
          name,
        );
        await tapWhenVisible(tester, find.text('Create as owner'));
        await waitForAny(tester, [
          find.text('Family group created'),
          find.text('Invite your family'),
          find.text('Invite member'),
        ]);
        if (find.text('Invite your family').evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(FilledButton, 'Invite member'));
          await tester.pump(const Duration(seconds: 1));
        }
      }

      if (find.text('Invite member').evaluate().isEmpty &&
          find.byTooltip('Invite member').evaluate().isEmpty) {
        expect(
          find.text('Family Group'),
          findsWidgets,
          reason: 'A is not owner and cannot generate an invite',
        );
        return;
      }

      if (find.widgetWithText(AppBar, 'Invite member').evaluate().isEmpty) {
        final tooltip = find.byTooltip('Invite member');
        if (tooltip.evaluate().isNotEmpty) {
          await tester.tap(tooltip);
        } else {
          await tapWhenVisible(tester, find.text('Invite member'));
        }
        await waitFor(tester, find.widgetWithText(AppBar, 'Invite member'));
      }

      final generate = find.textContaining('enerate code');
      await waitFor(tester, generate);
      await tester.tap(generate);
      await waitFor(
        tester,
        find.byKey(const ValueKey('invite-code')),
        timeout: const Duration(seconds: 20),
      );
      final codeWidget = tester.widget<Text>(
        find.byKey(const ValueKey('invite-code')),
      );
      generatedInviteCode = codeWidget.data;
      expect(generatedInviteCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
      expect(find.textContaining('Expires'), findsWidgets);
    },
  );

  testWidgets(
    'FAM-P-03: B joins with A invite or is already a member',
    skip: !hasQaCredentials,
    (tester) async {
      await launchApp(tester);
      await ensureLoggedOut(tester);
      await loginWithEmail(tester, email: qaBEmail, password: qaBPassword);
      await openFamilySettled(tester);

      if (find.text('Join with code').evaluate().isEmpty) {
        expect(find.text('Family Group'), findsWidgets);
        expect(find.text('Leave group'), findsWidgets);
        return;
      }

      final code = generatedInviteCode;
      if (code == null) {
        throw TestFailure(
          'No invite from FAM-P-02. Run this file as a suite so A generates a code first.',
        );
      }

      await enterField(
        tester,
        find.widgetWithText(TextField, 'Invite code'),
        code,
      );
      await hideKeyboard(tester);
      await tapWhenVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Join with code'),
      );
      await waitForAny(tester, [
        find.text('Joined the family group'),
        find.textContaining('in!'),
        find.text('Leave group'),
      ]);
      if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
        await tester.pump(const Duration(milliseconds: 400));
      }
    },
  );
}
