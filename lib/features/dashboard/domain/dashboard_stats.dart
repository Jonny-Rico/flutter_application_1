import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';

class MemberActivityStat {
  const MemberActivityStat({
    required this.userId,
    required this.displayName,
    required this.assignedOpen,
    required this.completed,
    required this.created,
  });

  final String userId;
  final String displayName;
  final int assignedOpen;
  final int completed;
  final int created;
}

class DayBucket {
  const DayBucket({
    required this.day,
    required this.created,
    required this.completed,
  });

  final DateTime day;
  final int created;
  final int completed;
}

class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.overdue,
    required this.completionRate,
    required this.byPriority,
    required this.assignedToMe,
    required this.assignedByMe,
    required this.groupTasks,
    required this.groupDone,
    required this.groupCompletionRate,
    required this.overdueTasks,
    required this.last7Days,
    required this.memberActivities,
    required this.activityStreakDays,
    required this.completedThisWeek,
    required this.completedLastWeek,
  });

  final int total;
  final int todo;
  final int inProgress;
  final int done;
  final int overdue;
  final double completionRate;
  final Map<TaskPriorityLevel, int> byPriority;
  final int assignedToMe;
  final int assignedByMe;
  final int groupTasks;
  final int groupDone;
  final double groupCompletionRate;
  final List<Task> overdueTasks;
  final List<DayBucket> last7Days;
  final List<MemberActivityStat> memberActivities;
  final int activityStreakDays;
  final int completedThisWeek;
  final int completedLastWeek;

  int get open => todo + inProgress;

  bool get isEmpty => total == 0;

  int get weekCompletionDelta => completedThisWeek - completedLastWeek;

  String get weekComparisonLabel {
    final delta = weekCompletionDelta;
    final base = 'Done this week: $completedThisWeek';
    if (delta > 0) return '$base (↑$delta vs last week)';
    if (delta < 0) return '$base (↓${-delta} vs last week)';
    return '$base (same as last week)';
  }

  factory DashboardStats.fromTasks({
    required List<Task> tasks,
    required String userId,
    List<GroupMember> members = const [],
  }) {
    var todo = 0;
    var inProgress = 0;
    var done = 0;
    var overdue = 0;
    var assignedToMe = 0;
    var assignedByMe = 0;
    var groupTasks = 0;
    var groupDone = 0;

    final byPriority = {
      for (final level in TaskPriorityLevel.values) level: 0,
    };

    final overdueTasks = <Task>[];

    for (final task in tasks) {
      switch (task.status) {
        case TaskStatus.todo:
          todo++;
        case TaskStatus.inProgress:
          inProgress++;
        case TaskStatus.done:
          done++;
      }

      byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;

      if (task.isOverdue) {
        overdue++;
        overdueTasks.add(task);
      }

      if (task.isGroupTask) {
        groupTasks++;
        if (task.status == TaskStatus.done) groupDone++;
      } else {
        if (task.assigneeId == userId) assignedToMe++;
        if (task.createdBy == userId && task.assigneeId != userId) {
          assignedByMe++;
        }
      }
    }

    overdueTasks.sort((a, b) {
      final aDeadline = a.deadline ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDeadline = b.deadline ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDeadline.compareTo(bDeadline);
    });

    final total = tasks.length;
    final completionRate = total == 0 ? 0.0 : done / total;
    final groupCompletionRate =
        groupTasks == 0 ? 0.0 : groupDone / groupTasks;

    final last7Days = _buildLast7Days(tasks);
    final memberActivities = _buildMemberActivities(tasks, members);
    final streak = _activityStreakDays(tasks);
    final (thisWeek, lastWeek) = _completedWeekCounts(tasks);

    return DashboardStats(
      total: total,
      todo: todo,
      inProgress: inProgress,
      done: done,
      overdue: overdue,
      completionRate: completionRate,
      byPriority: byPriority,
      assignedToMe: assignedToMe,
      assignedByMe: assignedByMe,
      groupTasks: groupTasks,
      groupDone: groupDone,
      groupCompletionRate: groupCompletionRate,
      overdueTasks: overdueTasks.take(5).toList(growable: false),
      last7Days: last7Days,
      memberActivities: memberActivities,
      activityStreakDays: streak,
      completedThisWeek: thisWeek,
      completedLastWeek: lastWeek,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static List<DayBucket> _buildLast7Days(List<Task> tasks) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    final createdCounts = {for (final day in days) day: 0};
    final completedCounts = {for (final day in days) day: 0};

    for (final task in tasks) {
      final createdDay = _dateOnly(task.createdAt);
      if (createdCounts.containsKey(createdDay)) {
        createdCounts[createdDay] = createdCounts[createdDay]! + 1;
      }

      if (task.status == TaskStatus.done) {
        final completedDay = _dateOnly(task.updatedAt);
        if (completedCounts.containsKey(completedDay)) {
          completedCounts[completedDay] = completedCounts[completedDay]! + 1;
        }
      }
    }

    return [
      for (final day in days)
        DayBucket(
          day: day,
          created: createdCounts[day] ?? 0,
          completed: completedCounts[day] ?? 0,
        ),
    ];
  }

  static List<MemberActivityStat> _buildMemberActivities(
    List<Task> tasks,
    List<GroupMember> members,
  ) {
    if (members.isEmpty) return const [];

    final stats = <String, MemberActivityStat>{};
    for (final member in members) {
      final name = member.displayName.isNotEmpty
          ? member.displayName
          : (member.email.isNotEmpty ? member.email : 'Member');
      stats[member.userId] = MemberActivityStat(
        userId: member.userId,
        displayName: name,
        assignedOpen: 0,
        completed: 0,
        created: 0,
      );
    }

    for (final task in tasks) {
      final creator = stats[task.createdBy];
      if (creator != null) {
        stats[task.createdBy] = MemberActivityStat(
          userId: creator.userId,
          displayName: creator.displayName,
          assignedOpen: creator.assignedOpen,
          completed: creator.completed,
          created: creator.created + 1,
        );
      }

      if (task.status != TaskStatus.done) {
        if (!task.isGroupTask && task.assigneeId != null) {
          final assignee = stats[task.assigneeId];
          if (assignee != null) {
            stats[task.assigneeId!] = MemberActivityStat(
              userId: assignee.userId,
              displayName: assignee.displayName,
              assignedOpen: assignee.assignedOpen + 1,
              completed: assignee.completed,
              created: assignee.created,
            );
          }
        } else if (task.isGroupTask) {
          // Family tasks have no assignee — count open load on creator.
          final creatorOpen = stats[task.createdBy];
          if (creatorOpen != null) {
            stats[task.createdBy] = MemberActivityStat(
              userId: creatorOpen.userId,
              displayName: creatorOpen.displayName,
              assignedOpen: creatorOpen.assignedOpen + 1,
              completed: creatorOpen.completed,
              created: creatorOpen.created,
            );
          }
        }
      }

      if (task.status == TaskStatus.done) {
        final completerId = task.completedBy ??
            (task.isGroupTask ? null : task.assigneeId) ??
            task.createdBy;
        final completer = stats[completerId];
        if (completer != null) {
          stats[completerId] = MemberActivityStat(
            userId: completer.userId,
            displayName: completer.displayName,
            assignedOpen: completer.assignedOpen,
            completed: completer.completed + 1,
            created: completer.created,
          );
        }
      }
    }

    final list = stats.values.toList()
      ..sort((a, b) {
        final scoreA = a.completed * 2 + a.created + a.assignedOpen;
        final scoreB = b.completed * 2 + b.created + b.assignedOpen;
        return scoreB.compareTo(scoreA);
      });
    return list;
  }

  /// Monday-based week: completed tasks by `updatedAt` while Done.
  static (int thisWeek, int lastWeek) _completedWeekCounts(List<Task> tasks) {
    final today = _dateOnly(DateTime.now());
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    var thisWeek = 0;
    var lastWeek = 0;

    for (final task in tasks) {
      if (task.status != TaskStatus.done) continue;
      final day = _dateOnly(task.updatedAt);
      if (!day.isBefore(thisWeekStart) && !day.isAfter(today)) {
        thisWeek++;
      } else if (!day.isBefore(lastWeekStart) && day.isBefore(thisWeekStart)) {
        lastWeek++;
      }
    }

    return (thisWeek, lastWeek);
  }

  /// Consecutive days (ending today) with at least one completed task update.
  static int _activityStreakDays(List<Task> tasks) {
    final completedDays = <DateTime>{};
    for (final task in tasks) {
      if (task.status != TaskStatus.done) continue;
      completedDays.add(_dateOnly(task.updatedAt));
    }
    if (completedDays.isEmpty) return 0;

    var streak = 0;
    var cursor = _dateOnly(DateTime.now());
    // If nothing done today, start from yesterday (streak still counts).
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
