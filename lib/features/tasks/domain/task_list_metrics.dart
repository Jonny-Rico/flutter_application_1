/// Extra list filters applied after view filter (Dashboard Overview taps).
enum TaskDashboardScope {
  /// Use normal view filter chips.
  none,

  /// Personal tasks where user is assignee or creator (Dashboard My).
  my,

  /// Family (group) tasks only (Dashboard Family).
  family,
}

enum TaskMetricFilter {
  none,
  openOnly,
  overdueOnly,
}
