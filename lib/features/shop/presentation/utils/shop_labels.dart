import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';

String memberDisplayName({
  required String userId,
  required List<GroupMember> members,
  String? currentUserId,
  String? currentUserName,
  String fallback = 'Someone',
}) {
  if (currentUserId != null && currentUserId == userId) {
    final self = currentUserName?.trim();
    if (self != null && self.isNotEmpty) return self;
    return 'You';
  }
  for (final member in members) {
    if (member.userId == userId) {
      return member.displayName.trim().isEmpty
          ? fallback
          : member.displayName.trim();
    }
  }
  return fallback;
}

String memberInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String needPreview(List<NeedItem> items, {int maxItems = 3}) {
  final open = items.where((item) => !item.bought).toList();
  if (open.isEmpty) return 'Nothing waiting';
  final names = open.take(maxItems).map((item) => item.title).join(', ');
  if (open.length > maxItems) return '$names waiting at home';
  return '$names waiting at home';
}

String planPreview(List<PlanItem> items, {int maxItems = 3}) {
  final open = items.where((item) => !item.bought).toList();
  if (open.isEmpty) return 'Nothing planned';
  final names = open.take(maxItems).map((item) => item.title).join(', ');
  if (open.length > maxItems) return '$names and more';
  return names;
}

String quantityLabel(int quantity) => quantity > 1 ? '×$quantity' : '';
