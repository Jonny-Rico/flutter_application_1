import 'package:family_tasks/features/tasks/domain/task_recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('REC-P-01 / REC-P-02 nextDeadlineFrom', () {
    final base = DateTime(2026, 1, 15, 10, 30);

    test('daily adds one day', () {
      expect(
        TaskRecurrence.daily.nextDeadlineFrom(base),
        DateTime(2026, 1, 16, 10, 30),
      );
    });

    test('weekly adds seven days', () {
      expect(
        TaskRecurrence.weekly.nextDeadlineFrom(base),
        DateTime(2026, 1, 22, 10, 30),
      );
    });

    test('monthly clamps end of month', () {
      final jan31 = DateTime(2026, 1, 31, 9);
      expect(
        TaskRecurrence.monthly.nextDeadlineFrom(jan31),
        DateTime(2026, 2, 28, 9),
      );
    });

    test('no repeat keeps the same instant', () {
      expect(TaskRecurrence.none.nextDeadlineFrom(base), base);
    });
  });
}
