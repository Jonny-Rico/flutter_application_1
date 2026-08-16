import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    this.groupId,
    this.groupRole,
    this.displayName = '',
    this.email = '',
    this.photoUrl,
  });

  final String userId;
  final String? groupId;
  final GroupRole? groupRole;
  final String displayName;
  final String email;
  final String? photoUrl;

  bool get hasGroup => groupId != null;

  bool get isOwner => groupRole?.isOwner ?? false;

  factory UserProfile.fromFirebaseUser(User user) {
    return UserProfile(
      userId: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final roleValue = data['groupRole'] as String?;
    return UserProfile(
      userId: doc.id,
      groupId: data['groupId'] as String?,
      groupRole: roleValue != null ? GroupRole.fromValue(roleValue) : null,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'groupRole': groupRole?.value,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
    };
  }
}