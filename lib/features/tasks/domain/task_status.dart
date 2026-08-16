import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  done('done', 'Done');

  const TaskStatus(this.value, this.label);

  final String value;
  final String label;

  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }

  Color get color => switch (this) {
        TaskStatus.todo => AppColors.onSurfaceMuted,
        TaskStatus.inProgress => const Color(0xFF5EEAD4),
        TaskStatus.done => AppColors.success,
      };

  IconData get icon => switch (this) {
        TaskStatus.todo => Icons.radio_button_unchecked_rounded,
        TaskStatus.inProgress => Icons.timelapse_rounded,
        TaskStatus.done => Icons.check_circle_rounded,
      };
}