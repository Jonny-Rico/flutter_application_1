import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/domain/task_view_filter.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskUiPreferences {
  const TaskUiPreferences({
    required this.persistFilters,
    required this.viewFilter,
    required this.statusFilter,
    required this.notifyNewTasks,
    required this.hapticsEnabled,
  });

  static const loginDefaults = TaskUiPreferences(
    persistFilters: false,
    viewFilter: TaskViewFilter.all,
    statusFilter: null,
    notifyNewTasks: true,
    hapticsEnabled: true,
  );

  static const savedDefaults = TaskUiPreferences(
    persistFilters: true,
    viewFilter: TaskViewFilter.assignedToMe,
    statusFilter: TaskStatus.todo,
    notifyNewTasks: true,
    hapticsEnabled: true,
  );

  final bool persistFilters;
  final TaskViewFilter viewFilter;
  final TaskStatus? statusFilter;
  final bool notifyNewTasks;
  final bool hapticsEnabled;

  Map<String, dynamic> toMap() {
    return {
      'persistFilters': persistFilters,
      'viewFilter': viewFilter.name,
      'statusFilter': statusFilter?.value,
      'notifyNewTasks': notifyNewTasks,
      'hapticsEnabled': hapticsEnabled,
    };
  }

  factory TaskUiPreferences.fromMap(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final persistFilters = map['persistFilters'] as bool? ?? true;

    return TaskUiPreferences(
      persistFilters: persistFilters,
      viewFilter: taskViewFilterFromName(map['viewFilter'] as String?),
      statusFilter: map.containsKey('statusFilter')
          ? _statusFromStoredValue(map['statusFilter'] as String?)
          : TaskUiPreferences.savedDefaults.statusFilter,
      notifyNewTasks: map['notifyNewTasks'] as bool? ?? true,
      hapticsEnabled: map['hapticsEnabled'] as bool? ?? true,
    );
  }

  /// `null` in storage means "All statuses".
  static TaskStatus? _statusFromStoredValue(String? value) {
    if (value == null) return null;
    for (final status in TaskStatus.values) {
      if (status.value == value) return status;
    }
    return TaskUiPreferences.savedDefaults.statusFilter;
  }
}

class TaskUiPreferencesStorage {
  TaskUiPreferencesStorage(this._box);

  static const _keyPrefix = 'task_ui_prefs_';

  final Box<dynamic> _box;

  String _keyFor(String userId) => '$_keyPrefix$userId';

  TaskUiPreferences load(String userId) {
    final raw = _box.get(_keyFor(userId));
    if (raw is! Map) return TaskUiPreferences.savedDefaults;
    return TaskUiPreferences.fromMap(raw);
  }

  Future<void> save(String userId, TaskUiPreferences preferences) async {
    await _box.put(_keyFor(userId), preferences.toMap());
  }
}