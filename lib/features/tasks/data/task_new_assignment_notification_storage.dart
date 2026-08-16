import 'package:hive_flutter/hive_flutter.dart';

class TaskNewAssignmentNotificationState {
  const TaskNewAssignmentNotificationState({
    required this.notifiedTaskIds,
    required this.scopedBaselines,
  });

  static const empty = TaskNewAssignmentNotificationState(
    notifiedTaskIds: {},
    scopedBaselines: {},
  );

  final Set<String> notifiedTaskIds;
  final Set<String> scopedBaselines;

  bool hasScopedBaseline(String scopeKey) => scopedBaselines.contains(scopeKey);

  TaskNewAssignmentNotificationState withBaseline({
    required String scopeKey,
    required Iterable<String> taskIds,
  }) {
    return TaskNewAssignmentNotificationState(
      notifiedTaskIds: {...notifiedTaskIds, ...taskIds},
      scopedBaselines: {...scopedBaselines, scopeKey},
    );
  }

  TaskNewAssignmentNotificationState withNotifiedTaskIds(
    Iterable<String> taskIds,
  ) {
    return TaskNewAssignmentNotificationState(
      notifiedTaskIds: {...notifiedTaskIds, ...taskIds},
      scopedBaselines: scopedBaselines,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifiedTaskIds': notifiedTaskIds.toList(),
      'scopedBaselines': scopedBaselines.toList(),
    };
  }

  factory TaskNewAssignmentNotificationState.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    return TaskNewAssignmentNotificationState(
      notifiedTaskIds: (map['notifiedTaskIds'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toSet(),
      scopedBaselines: (map['scopedBaselines'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toSet(),
    );
  }
}

class TaskNewAssignmentNotificationStorage {
  TaskNewAssignmentNotificationStorage(this._box);

  static const _keyPrefix = 'task_new_assignment_notify_';

  final Box<dynamic> _box;

  String _keyFor(String userId) => '$_keyPrefix$userId';

  TaskNewAssignmentNotificationState load(String userId) {
    final raw = _box.get(_keyFor(userId));
    if (raw is! Map) return TaskNewAssignmentNotificationState.empty;
    return TaskNewAssignmentNotificationState.fromMap(raw);
  }

  Future<void> save(
    String userId,
    TaskNewAssignmentNotificationState state,
  ) async {
    await _box.put(_keyFor(userId), state.toMap());
  }
}