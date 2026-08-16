class TaskPermissions {
  const TaskPermissions({
    this.assigneeCanEdit = false,
    this.assigneeCanDelete = false,
  });

  final bool assigneeCanEdit;
  final bool assigneeCanDelete;

  Map<String, dynamic> toMap() {
    return {
      'assigneeCanEdit': assigneeCanEdit,
      'assigneeCanDelete': assigneeCanDelete,
    };
  }

  factory TaskPermissions.fromMap(dynamic value) {
    if (value is! Map) return const TaskPermissions();
    final map = Map<String, dynamic>.from(value);
    return TaskPermissions(
      assigneeCanEdit: map['assigneeCanEdit'] as bool? ?? false,
      assigneeCanDelete: map['assigneeCanDelete'] as bool? ?? false,
    );
  }
}