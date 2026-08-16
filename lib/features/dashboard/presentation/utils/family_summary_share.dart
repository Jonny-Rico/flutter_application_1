import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:share_plus/share_plus.dart';

/// Builds and opens the system share sheet for a short Family progress blurb.
Future<void> shareFamilySummary(DashboardStats stats) async {
  final text =
      'Family closed ${stats.done}/${stats.total} tasks · ${stats.overdue} overdue';
  await SharePlus.instance.share(ShareParams(text: text));
}
