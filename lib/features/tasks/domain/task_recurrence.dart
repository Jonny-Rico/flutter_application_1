import 'package:flutter/material.dart';

enum TaskRecurrence {
  none('none', 'No repeat'),
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly');

  const TaskRecurrence(this.value, this.label);

  final String value;
  final String label;

  static TaskRecurrence fromValue(String? value) {
    for (final item in TaskRecurrence.values) {
      if (item.value == value) return item;
    }
    return TaskRecurrence.none;
  }

  bool get isRepeating => this != TaskRecurrence.none;

  /// Short help under the form control.
  String? get formHint {
    switch (this) {
      case TaskRecurrence.none:
        return null;
      case TaskRecurrence.daily:
        return 'When marked Done, a new copy is created with deadline +1 day.';
      case TaskRecurrence.weekly:
        return 'When marked Done, a new copy is created with deadline +7 days.';
      case TaskRecurrence.monthly:
        return 'When marked Done, a new copy is created with deadline +1 month.';
    }
  }

  /// Detail row value.
  String get detailLabel {
    switch (this) {
      case TaskRecurrence.none:
        return 'No repeat';
      case TaskRecurrence.daily:
        return 'Daily — next copy after Done';
      case TaskRecurrence.weekly:
        return 'Weekly — next copy after Done';
      case TaskRecurrence.monthly:
        return 'Monthly — next copy after Done';
    }
  }

  IconData get formIcon {
    switch (this) {
      case TaskRecurrence.none:
        return Icons.event_busy_outlined;
      case TaskRecurrence.daily:
        return Icons.today_outlined;
      case TaskRecurrence.weekly:
        return Icons.repeat_rounded;
      case TaskRecurrence.monthly:
        return Icons.calendar_month_outlined;
    }
  }

  /// Next occurrence deadline from the completed task's deadline (or now).
  DateTime nextDeadlineFrom(DateTime base) {
    switch (this) {
      case TaskRecurrence.none:
        return base;
      case TaskRecurrence.daily:
        return base.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return base.add(const Duration(days: 7));
      case TaskRecurrence.monthly:
        return _addCalendarMonths(base, 1);
    }
  }

  /// Adds calendar months, clamping day to end-of-month when needed.
  static DateTime _addCalendarMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
