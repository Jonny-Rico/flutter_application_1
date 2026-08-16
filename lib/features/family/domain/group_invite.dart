import 'package:cloud_firestore/cloud_firestore.dart';

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.invitedBy,
    required this.inviteCode,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String groupId;
  final String invitedBy;
  final String inviteCode;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isValid =>
      status == 'pending' && expiresAt.isAfter(DateTime.now());

  factory GroupInvite.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GroupInvite(
      id: doc.id,
      groupId: data['groupId'] as String,
      invitedBy: data['invitedBy'] as String,
      inviteCode: data['inviteCode'] as String,
      status: data['status'] as String? ?? 'pending',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      expiresAt: _parseDate(data['expiresAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}