import 'dart:developer' as developer;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:family_tasks/features/family/domain/family_group.dart';
import 'package:family_tasks/features/family/domain/group_invite.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:uuid/uuid.dart';

class GroupRepository {
  GroupRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;
  final _random = Random();

  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  DocumentReference<Map<String, dynamic>> _groupRef(String groupId) {
    return _firestore.collection('groups').doc(groupId);
  }

  CollectionReference<Map<String, dynamic>> _membersRef(String groupId) {
    return _groupRef(groupId).collection('members');
  }

  Future<void> ensureUserProfile(UserProfile profile) async {
    final doc = await _userRef(profile.userId).get();
    if (!doc.exists) {
      await _userRef(profile.userId).set(profile.toFirestore());
      return;
    }

    // Fill name/email if Auth has them but the profile doc was created empty
    // (e.g. register: auth snapshot raced ahead of updateDisplayName).
    final existing = UserProfile.fromFirestore(doc);
    final updates = <String, dynamic>{};
    if (existing.displayName.isEmpty && profile.displayName.isNotEmpty) {
      updates['displayName'] = profile.displayName;
    }
    if (existing.email.isEmpty && profile.email.isNotEmpty) {
      updates['email'] = profile.email;
    }
    if (updates.isNotEmpty) {
      await _userRef(profile.userId).update(updates);
    }
  }

  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
    String? groupId,
  }) async {
    final name = displayName.trim();
    if (name.length < 2) {
      throw Exception('Enter your name (at least 2 characters).');
    }

    final batch = _firestore.batch();
    batch.set(_userRef(userId), {'displayName': name}, SetOptions(merge: true));
    if (groupId != null && groupId.isNotEmpty) {
      batch.set(
        _membersRef(groupId).doc(userId),
        {'displayName': name},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Stream<UserProfile?> watchUserProfile(String userId) {
    return _userRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _userRef(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Stream<FamilyGroup?> watchGroup(String groupId) {
    return _groupRef(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return FamilyGroup.fromFirestore(doc);
    });
  }

  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _membersRef(groupId)
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(GroupMember.fromFirestore).toList(),
        );
  }

  void _requireVerifiedEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      throw Exception(
        'Verify your email before creating or joining a family.',
      );
    }
  }

  Future<String> createGroup({
    required UserProfile owner,
    required String name,
  }) async {
    _requireVerifiedEmail();
    if (owner.hasGroup) {
      throw Exception('You already belong to a family group.');
    }

    final groupId = _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.set(_groupRef(groupId), {
      'name': name.trim(),
      'ownerId': owner.userId,
      'createdAt': now,
      'updatedAt': now,
    });

    batch.set(_membersRef(groupId).doc(owner.userId), {
      'role': GroupRole.owner.value,
      'joinedAt': now,
      'displayName': owner.displayName,
      'email': owner.email,
      'photoUrl': owner.photoUrl,
    });

    batch.set(_userRef(owner.userId), {
      'groupId': groupId,
      'groupRole': GroupRole.owner.value,
      'displayName': owner.displayName,
      'email': owner.email,
      'photoUrl': owner.photoUrl,
    }, SetOptions(merge: true));

    await batch.commit();
    await _migratePersonalTasksSafely(owner.userId, groupId);
    return groupId;
  }

  Future<String> createInvite({
    required String groupId,
    required String ownerId,
  }) async {
    _requireVerifiedEmail();
    final expiresAt = DateTime.now().add(AppConstants.inviteTtl);

    final existing = await _firestore
        .collection('invites')
        .where('invitedBy', isEqualTo: ownerId)
        .get();

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      final data = doc.data();
      if (data['groupId'] == groupId && data['status'] == 'pending') {
        batch.update(doc.reference, {
          'status': 'revoked',
          'revokedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    var code = _generateInviteCode();
    var inviteRef = _firestore.collection('invites').doc(code);
    for (var i = 0; i < 5; i++) {
      final clash = await inviteRef.get();
      if (!clash.exists) break;
      code = _generateInviteCode();
      inviteRef = _firestore.collection('invites').doc(code);
    }

    batch.set(inviteRef, {
      'groupId': groupId,
      'invitedBy': ownerId,
      'inviteCode': code,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
    await batch.commit();
    return code;
  }

  Stream<GroupInvite?> watchLatestInvite({
    required String groupId,
    required String ownerId,
  }) {
    return _firestore
        .collection('invites')
        .where('invitedBy', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final invites = snapshot.docs
          .map(GroupInvite.fromFirestore)
          .where((invite) => invite.groupId == groupId && invite.status == 'pending')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (invites.isEmpty) return null;
      for (final invite in invites) {
        if (invite.isValid) return invite;
      }
      return invites.first;
    });
  }

  Future<void> joinGroup({
    required UserProfile user,
    required String inviteCode,
  }) async {
    _requireVerifiedEmail();
    if (user.hasGroup) {
      throw Exception('You already belong to a family group.');
    }

    final code = inviteCode.trim().toUpperCase();
    final inviteDoc = await _firestore.collection('invites').doc(code).get();
    if (!inviteDoc.exists) {
      throw Exception('Invalid or expired invite code.');
    }

    final invite = GroupInvite.fromFirestore(inviteDoc);
    if (!invite.isValid) {
      throw Exception('Invalid or expired invite code.');
    }

    final membersSnapshot = await _membersRef(invite.groupId).get();
    if (membersSnapshot.docs.length >= AppConstants.maxGroupMembers) {
      throw Exception('This family group is full.');
    }

    final batch = _firestore.batch();
    final memberRef = _membersRef(invite.groupId).doc(user.userId);

    batch.set(memberRef, {
      'role': GroupRole.member.value,
      'joinedAt': FieldValue.serverTimestamp(),
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl,
    });

    batch.set(_userRef(user.userId), {
      'groupId': invite.groupId,
      'groupRole': GroupRole.member.value,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl,
    }, SetOptions(merge: true));

    batch.update(_firestore.collection('invites').doc(invite.id), {
      'status': 'accepted',
      'acceptedBy': user.userId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    await _migratePersonalTasksSafely(user.userId, invite.groupId);
  }

  Future<void> removeMember({
    required String groupId,
    required String ownerId,
    required String memberId,
  }) async {
    if (ownerId == memberId) {
      throw Exception('Owner cannot remove themselves this way.');
    }

    final group = await _groupRef(groupId).get();
    if (!group.exists || group.data()?['ownerId'] != ownerId) {
      throw Exception('Only the owner can remove members.');
    }

    await _removeMemberFromGroup(groupId, memberId);
  }

  Future<void> leaveGroup({
    required String groupId,
    required String userId,
    required GroupRole role,
  }) async {
    if (role.isOwner) {
      await _ownerLeaveGroup(groupId, userId);
      return;
    }
    await _removeMemberFromGroup(groupId, userId);
  }

  Future<void> dissolveGroup({
    required String groupId,
    required String ownerId,
  }) async {
    final group = await _groupRef(groupId).get();
    if (!group.exists || group.data()?['ownerId'] != ownerId) {
      throw Exception('Only the owner can dissolve the group.');
    }

    final members = await _membersRef(groupId).get();
    for (final member in members.docs) {
      await _restoreCreatedTasksToPersonal(groupId, member.id);
    }

    final leftover = await _groupRef(groupId).collection('tasks').get();
    final invites = await _firestore
        .collection('invites')
        .where('invitedBy', isEqualTo: ownerId)
        .get();

    final batch = _firestore.batch();
    for (final task in leftover.docs) {
      batch.delete(task.reference);
    }
    for (final member in members.docs) {
      batch.delete(member.reference);
      batch.update(_userRef(member.id), {
        'groupId': null,
        'groupRole': null,
      });
    }
    for (final invite in invites.docs) {
      if (invite.data()['groupId'] == groupId) {
        batch.delete(invite.reference);
      }
    }
    batch.delete(_groupRef(groupId));
    await batch.commit();
  }

  Future<void> _ownerLeaveGroup(String groupId, String ownerId) async {
    final membersSnapshot = await _membersRef(groupId).orderBy('joinedAt').get();
    GroupMember? successor;
    for (final doc in membersSnapshot.docs) {
      final member = GroupMember.fromFirestore(doc);
      if (member.userId != ownerId && member.role == GroupRole.member) {
        successor = member;
        break;
      }
    }

    if (successor == null) {
      await dissolveGroup(groupId: groupId, ownerId: ownerId);
      return;
    }
    await _restoreCreatedTasksToPersonal(groupId, ownerId);
    final batch = _firestore.batch();

    batch.update(_groupRef(groupId), {
      'ownerId': successor.userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(_membersRef(groupId).doc(successor.userId), {
      'role': GroupRole.owner.value,
    });

    batch.update(_userRef(successor.userId), {
      'groupRole': GroupRole.owner.value,
    });

    batch.delete(_membersRef(groupId).doc(ownerId));
    batch.update(_userRef(ownerId), {
      'groupId': null,
      'groupRole': null,
    });

    await batch.commit();
  }

  Future<void> _removeMemberFromGroup(String groupId, String memberId) async {
    await _restoreCreatedTasksToPersonal(groupId, memberId);
    final batch = _firestore.batch();
    batch.delete(_membersRef(groupId).doc(memberId));
    batch.update(_userRef(memberId), {
      'groupId': null,
      'groupRole': null,
    });
    batch.update(_groupRef(groupId), {
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Moves tasks this user created (personal + family they authored) back
  /// to `users/{userId}/tasks` while they are still a member.
  Future<void> _restoreCreatedTasksToPersonal(
    String groupId,
    String userId,
  ) async {
    final groupTasks =
        await _groupRef(groupId).collection('tasks').get();
    final mine = groupTasks.docs.where((doc) {
      final data = doc.data();
      return data['createdBy'] == userId;
    }).toList();
    if (mine.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in mine) {
      final task = Task.fromFirestore(doc);
      final restored = Task(
        id: task.id,
        groupId: null,
        createdBy: task.createdBy,
        assigneeId: task.assigneeId,
        completedBy: task.completedBy,
        title: task.title,
        description: task.description,
        deadline: task.deadline,
        reminderAt: task.reminderAt,
        priority: task.priority,
        status: task.status,
        isGroupTask: false,
        permissions: task.permissions,
        createdAt: task.createdAt,
        updatedAt: DateTime.now(),
        recurrence: task.recurrence,
      );
      batch.set(
        _firestore.collection('users').doc(userId).collection('tasks').doc(task.id),
        restored.toFirestore(),
      );
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _migratePersonalTasksSafely(String userId, String groupId) async {
    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await _migratePersonalTasks(userId, groupId);
        return;
      } on FirebaseException catch (error) {
        final isLastAttempt = attempt == maxAttempts - 1;
        if (error.code != 'permission-denied' || isLastAttempt) {
          developer.log(
            'Personal task migration skipped after group join/create',
            name: 'GroupRepository',
            error: error,
          );
          return;
        }
        await Future<void>.delayed(
          Duration(milliseconds: 400 * (attempt + 1)),
        );
      }
    }
  }

  Future<void> _migratePersonalTasks(String userId, String groupId) async {
    final personalTasks = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();

    if (personalTasks.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in personalTasks.docs) {
      final task = Task.fromFirestore(doc);
      final migrated = Task(
        id: task.id,
        groupId: groupId,
        createdBy: task.createdBy,
        assigneeId: task.assigneeId ?? task.createdBy,
        completedBy: task.completedBy,
        title: task.title,
        description: task.description,
        deadline: task.deadline,
        reminderAt: task.reminderAt,
        priority: task.priority,
        status: task.status,
        isGroupTask: task.isGroupTask,
        permissions: task.permissions,
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        recurrence: task.recurrence,
      );

      batch.set(
        _groupRef(groupId).collection('tasks').doc(task.id),
        migrated.toFirestore(),
      );
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}