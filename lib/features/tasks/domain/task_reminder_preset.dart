enum TaskReminderPreset {
  none('No reminder'),
  inOneHour('In 1 hour'),
  inOneDay('In 1 day');

  const TaskReminderPreset(this.label);

  final String label;

  DateTime? resolveFromNow() {
    final now = DateTime.now();
    return switch (this) {
      TaskReminderPreset.none => null,
      TaskReminderPreset.inOneHour => now.add(const Duration(hours: 1)),
      TaskReminderPreset.inOneDay => now.add(const Duration(days: 1)),
    };
  }
}