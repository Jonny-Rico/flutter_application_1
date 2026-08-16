import 'package:family_tasks/app.dart';
import 'package:family_tasks/core/bootstrap.dart';
import 'package:family_tasks/core/firebase/firestore_errors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void installE2eErrorGuards() {
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (isFirestoreAuthLoss(details.exception)) return;
    previous?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    return isFirestoreAuthLoss(error);
  };
}

const qaAEmail = String.fromEnvironment('QA_A_EMAIL');
const qaAPassword = String.fromEnvironment('QA_A_PASSWORD');
const qaBEmail = String.fromEnvironment('QA_B_EMAIL');
const qaBPassword = String.fromEnvironment('QA_B_PASSWORD');

bool get hasQaCredentials =>
    qaAEmail.isNotEmpty &&
    qaAPassword.isNotEmpty &&
    qaBEmail.isNotEmpty &&
    qaBPassword.isNotEmpty;

Future<void> launchApp(WidgetTester tester) async {
  await bootstrap();
  await tester.pumpWidget(const ProviderScope(child: FamilyTasksApp()));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 25),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 45),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) return;
    }
  }
  throw TestFailure('Timed out waiting for any of $finders');
}

void failIfLocked() {
  if (find.text('App locked').evaluate().isNotEmpty) {
    throw TestFailure(
      'App lock is on for this QA account. Turn it off in Settings before e2e.',
    );
  }
}

Future<void> dismissPushedRoutes(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    if (find.byType(NavigationBar).evaluate().isNotEmpty) return;
    final back = find.byTooltip('Back');
    if (back.evaluate().isEmpty) return;
    await tester.tap(back);
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> tapNavTab(WidgetTester tester, String label) async {
  await dismissPushedRoutes(tester);
  final bar = find.byType(NavigationBar);
  await waitFor(tester, bar);
  final index = switch (label) {
    'Tasks' => 0,
    'Family' => 1,
    'Dashboard' => 2,
    'Settings' => 3,
    _ => throw ArgumentError.value(label, 'label'),
  };
  final rect = tester.getRect(bar);
  final slot = rect.width / 4;
  await tester.tapAt(Offset(rect.left + slot * (index + 0.5), rect.center.dy));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

/// ListView only builds on-screen children, so [finder] may not exist yet.
Future<void> scrollUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxDrags = 16,
}) async {
  for (var i = 0; i < maxDrags; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isNotEmpty) return;
    final scrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          widget.axis == Axis.vertical &&
          widget.restorationId != 'editable',
    );
    if (scrollable.evaluate().isEmpty) break;
    await tester.drag(scrollable.last, const Offset(0, -320));
  }
  await waitFor(tester, finder, timeout: const Duration(seconds: 8));
}

Future<void> tapWhenVisible(WidgetTester tester, Finder finder) async {
  await scrollUntilFound(tester, finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> enterField(
  WidgetTester tester,
  Finder field,
  String text,
) async {
  await waitFor(tester, field);
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> ensureLoggedOut(WidgetTester tester) async {
  await waitForAny(
    tester,
    [
      find.text('Sign in with email'),
      find.byType(NavigationBar),
      find.text('App locked'),
    ],
  );
  failIfLocked();
  if (find.text('Sign in with email').evaluate().isNotEmpty) return;

  await tapNavTab(tester, 'Settings');
  await waitFor(tester, find.widgetWithText(AppBar, 'Settings'));
  await tapWhenVisible(tester, find.byKey(const ValueKey('sign-out-button')));
  await waitFor(
    tester,
    find.text('Sign in with email'),
    timeout: const Duration(seconds: 30),
  );
}

Future<void> hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> openFamilySettled(WidgetTester tester) async {
  await tapNavTab(tester, 'Family');
  await waitForAny(tester, [
    find.text('Join with code'),
    find.text('Invite member'),
    find.text('Leave group'),
    find.text('Dissolve group'),
    find.text('Verify email to use Family'),
  ]);
  await tester.pump(const Duration(seconds: 2));
}

Future<void> loginWithEmail(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  failIfLocked();
  await waitFor(tester, find.text('Sign in with email'));
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in with email'));
  await tester.pump(const Duration(milliseconds: 500));

  final fields = find.byType(TextFormField);
  await waitFor(tester, fields);
  await enterField(tester, fields.at(0), email);
  await enterField(tester, fields.at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await waitFor(
    tester,
    find.byType(NavigationBar),
    timeout: const Duration(seconds: 35),
  );
  failIfLocked();
}
