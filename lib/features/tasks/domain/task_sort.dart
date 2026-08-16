import 'package:family_tasks/features/tasks/domain/task.dart';

/// Default list order: overdue first → deadline asc (null last) →
/// priority high first → updatedAt desc.
List<Task> sortTasksDefault(List<Task> tasks) {
  final sorted = List<Task>.from(tasks);
  sorted.sort((a, b) {
    final overdueCmp = (a.isOverdue ? 0 : 1).compareTo(b.isOverdue ? 0 : 1);
    if (overdueCmp != 0) return overdueCmp;

    final aDeadline = a.deadline;
    final bDeadline = b.deadline;
    if (aDeadline == null && bDeadline != null) return 1;
    if (aDeadline != null && bDeadline == null) return -1;
    if (aDeadline != null && bDeadline != null) {
      final deadlineCmp = aDeadline.compareTo(bDeadline);
      if (deadlineCmp != 0) return deadlineCmp;
    }

    final priorityCmp = b.priority.value.compareTo(a.priority.value);
    if (priorityCmp != 0) return priorityCmp;

    return b.updatedAt.compareTo(a.updatedAt);
  });
  return sorted;
}
