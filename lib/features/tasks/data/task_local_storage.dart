import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TaskLocalStorage {
  TaskLocalStorage(this._box);

  static const boxName = 'family_tasks_cache';

  final Box<dynamic> _box;

  Future<void> saveTasks(String userId, List<Task> tasks) async {
    await _box.put(userId, tasks.map((task) => task.toMap()).toList());
  }

  List<Task> loadTasks(String userId) {
    final raw = _box.get(userId);
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((entry) => Task.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }
}