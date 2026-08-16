import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TaskPriorityLevel {
  lowest(0, 'Lowest'),
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High'),
  critical(4, 'Critical');

  const TaskPriorityLevel(this.value, this.label);

  final int value;
  final String label;

  static TaskPriorityLevel fromValue(int value) {
    return TaskPriorityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => TaskPriorityLevel.medium,
    );
  }

  Color get color => switch (this) {
        TaskPriorityLevel.lowest => AppColors.onSurfaceMuted,
        TaskPriorityLevel.low => const Color(0xFF60A5FA),
        TaskPriorityLevel.medium => const Color(0xFF5EEAD4),
        TaskPriorityLevel.high => AppColors.warning,
        TaskPriorityLevel.critical => AppColors.danger,
      };
}