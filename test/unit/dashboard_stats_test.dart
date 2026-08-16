import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/task_fixtures.dart';

void main() {
  group('DASH-P-01 / DASH-N-01 stats', () {
    test('empty list is empty and all zeros', () {
      final stats = DashboardStats.fromTasks(tasks: const [], userId: 'a');

      expect(stats.isEmpty, isTrue);
      expect(stats.total, 0);
      expect(stats.overdue, 0);
      expect(stats.open, 0);
    });

    test('counts open done overdue', () {
      final stats = DashboardStats.fromTasks(
        userId: 'user-a',
        tasks: [
          buildTask(id: '1', status: TaskStatus.todo),
          buildTask(id: '2', status: TaskStatus.inProgress),
          buildTask(id: '3', status: TaskStatus.done),
          buildTask(
            id: '4',
            deadline: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(stats.total, 4);
      expect(stats.done, 1);
      expect(stats.open, 3);
      expect(stats.overdue, 1);
    });

    test('week comparison labels', () {
      final up = DashboardStats.fromTasks(tasks: const [], userId: 'a');
      expect(up.weekComparisonLabel, contains('Done this week'));
    });
  });
}
