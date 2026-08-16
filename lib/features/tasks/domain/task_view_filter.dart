enum TaskViewFilter { assignedToMe, assignedByMe, group, all }

const taskViewFilterDisplayOrder = <TaskViewFilter>[
  TaskViewFilter.assignedToMe,
  TaskViewFilter.assignedByMe,
  TaskViewFilter.group,
  TaskViewFilter.all,
];

TaskViewFilter taskViewFilterFromName(String? value) {
  if (value == null) return TaskViewFilter.assignedToMe;
  for (final filter in TaskViewFilter.values) {
    if (filter.name == value) return filter;
  }
  return TaskViewFilter.assignedToMe;
}