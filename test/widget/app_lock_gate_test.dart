import 'dart:io';

import 'package:family_tasks/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:family_tasks/features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('ft_hive_lock');
    Hive.init(hiveDir.path);
    await Hive.openBox<dynamic>(TaskLocalStorage.boxName);
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

  testWidgets('LOCK-P-02 UI: lock overlay shows App locked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockGateVisibleProvider.overrideWith((ref) => true),
        ],
        child: const MaterialApp(
          home: AppLockGate(
            child: Scaffold(body: Text('secret')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('App locked'), findsOneWidget);
    expect(find.text('secret'), findsOneWidget);
  });

  testWidgets('LOCK: unlocked gate does not show PIN wall', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockGateVisibleProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          home: AppLockGate(
            child: Scaffold(body: Text('secret')),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('App locked'), findsNothing);
    expect(find.text('secret'), findsOneWidget);
  });
}
