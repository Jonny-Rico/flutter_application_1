import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/task_fixtures.dart';

void main() {
  const owner = 'user-a';
  const other = 'user-b';

  group('PERM-N-01 / PERM-N-02 creator-only fields', () {
    test('assignee cannot delete or edit title by default', () {
      final task = buildTask(createdBy: owner, assigneeId: other);

      expect(task.canDelete(other), isFalse);
      expect(task.canEditFields(other), isFalse);
      expect(task.canDelete(owner), isTrue);
      expect(task.canEditFields(owner), isTrue);
    });
  });

  group('PERM-P-02 assignee status', () {
    test('personal assignee can change status', () {
      final task = buildTask(createdBy: owner, assigneeId: other);

      expect(task.canChangeStatus(other), isTrue);
    });

    test('family member can change status on group task', () {
      final task = buildTask(
        createdBy: owner,
        isGroupTask: true,
        assigneeId: null,
      );

      expect(task.canChangeStatus(other), isTrue);
    });

    test('unrelated user cannot change personal task status', () {
      final task = buildTask(createdBy: owner, assigneeId: owner);

      expect(task.canChangeStatus(other), isFalse);
    });
  });

  group('TASK-P-06 overdue', () {
    test('open past deadline is overdue', () {
      final task = buildTask(
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(task.isOverdue, isTrue);
    });

    test('done task is never overdue', () {
      final task = buildTask(
        deadline: DateTime.now().subtract(const Duration(days: 1)),
        status: TaskStatus.done,
      );

      expect(task.isOverdue, isFalse);
    });

    test('future deadline is not overdue', () {
      final task = buildTask(
        deadline: DateTime.now().add(const Duration(days: 1)),
      );

      expect(task.isOverdue, isFalse);
    });
  });
}
