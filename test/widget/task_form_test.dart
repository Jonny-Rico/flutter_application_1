import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TASK-N-01: create without title is blocked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userProfileProvider.overrideWith((ref) => Stream.value(null)),
          groupMembersProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: TaskFormScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Create task'));
    await tester.pump();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);
  });
}
