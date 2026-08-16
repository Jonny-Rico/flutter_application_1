import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String userId;
  final GroupRole role;
  final DateTime joinedAt;
  final String displayName;
  final String email;
  final String? photoUrl;

  factory GroupMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GroupMember(
      userId: doc.id,
      role: GroupRole.fromValue(data['role'] as String? ?? 'member'),
      joinedAt: _parseDate(data['joinedAt']) ?? DateTime.now(),
      displayName: data['displayName'] as String? ?? 'Member',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}