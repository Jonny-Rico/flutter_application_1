import 'dart:io';

import 'package:family_tasks/features/auth/data/auth_repository.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/data/group_repository.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/settings/presentation/screens/settings_screen.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import '../helpers/fake_notification_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../helpers/fake_auth_user.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  String? lastName;

  @override
  Future<void> updateDisplayName(String displayName) async {
    lastName = displayName;
  }
}

class _FakeGroupRepository extends Fake implements GroupRepository {
  @override
  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
    String? groupId,
  }) async {}
}

void main() {
  late Directory hiveDir;
  late _FakeAuthRepository authRepo;

  const profile = UserProfile(
    userId: 'user-a',
    displayName: 'QA User A',
    email: 'qa.a.familytasks@example.com',
  );

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ft_hive_settings');
    Hive.init(hiveDir.path);
    await Hive.openBox<dynamic>(TaskLocalStorage.boxName);
    authRepo = _FakeAuthRepository();
  });

  tearDown(() async {
    if (Hive.isBoxOpen(TaskLocalStorage.boxName)) {
      await Hive.box<dynamic>(TaskLocalStorage.boxName).close();
    }
    await Hive.deleteFromDisk();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(FakeAuthUser()),
          ),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          emailVerifiedProvider.overrideWith((ref) => true),
          hasGoogleProviderProvider.overrideWith((ref) => false),
          hasPasswordProviderProvider.overrideWith((ref) => true),
          authRepositoryProvider.overrideWithValue(authRepo),
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
          taskNotificationSchedulerProvider.overrideWithValue(
            FakeNotificationScheduler(),
          ),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('SET-N-01: name shorter than 2 characters is rejected', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'A');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(find.text('Enter your name (at least 2 characters).'), findsOneWidget);
    expect(authRepo.lastName, isNull);
  });

  testWidgets('SET-P-01: edit name saves', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byTooltip('Edit name'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Alex QA');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();

    expect(authRepo.lastName, 'Alex QA');
    expect(find.text('Name updated'), findsOneWidget);
  });

  testWidgets('SET-P-02 / SET-P-03: remember and notify toggles flip', (
    tester,
  ) async {
    await pumpSettings(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(SettingsScreen)),
    );

    expect(container.read(taskPersistFiltersProvider), isTrue);
    await tester.tap(find.text('Remember task filters'));
    await tester.pump();
    expect(container.read(taskPersistFiltersProvider), isFalse);

    expect(container.read(taskNotifyNewTasksProvider), isTrue);
    await tester.tap(find.text('Notify about new tasks'));
    await tester.pump();
    expect(container.read(taskNotifyNewTasksProvider), isFalse);
  });

  testWidgets('SET-P-05: email user sees password linked and Google not linked', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Email and password'), findsOneWidget);
    expect(find.text('Linked · you can sign in with email'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Not linked'), findsOneWidget);
    expect(find.text('Link'), findsOneWidget);
  });
}
