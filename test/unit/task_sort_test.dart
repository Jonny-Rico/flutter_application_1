import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_sort.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/task_fixtures.dart';

void main() {
  group('Default task sort', () {
    test('overdue comes before future deadline', () {
      final future = buildTask(
        id: 'future',
        deadline: DateTime.now().add(const Duration(days: 2)),
      );
      final overdue = buildTask(
        id: 'overdue',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      final sorted = sortTasksDefault([future, overdue]);
      expect(sorted.first.id, 'overdue');
    });

    test('null deadline sorts after dated open tasks', () {
      final dated = buildTask(
        id: 'dated',
        deadline: DateTime.now().add(const Duration(days: 1)),
      );
      final undated = buildTask(id: 'undated');

      final sorted = sortTasksDefault([undated, dated]);
      expect(sorted.first.id, 'dated');
      expect(sorted.last.id, 'undated');
    });

    test('higher priority wins when deadlines match', () {
      final day = DateTime.now().add(const Duration(days: 3));
      final low = buildTask(id: 'low', deadline: day);
      final high = buildTask(id: 'high', deadline: day).copyWith(
        priority: TaskPriorityLevel.high,
      );

      final sorted = sortTasksDefault([low, high]);
      expect(sorted.first.id, 'high');
    });
  });
}
