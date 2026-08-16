import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TASK-P-07 empty copy is visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'Nothing here',
            subtitle: 'Reset filters to see tasks.',
          ),
        ),
      ),
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Reset filters to see tasks.'), findsOneWidget);
  });
}
