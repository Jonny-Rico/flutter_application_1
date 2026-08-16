import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/data/group_repository.dart';
import 'package:family_tasks/features/family/data/onboarding_flags_storage.dart';
import 'package:family_tasks/features/family/domain/family_group.dart';
import 'package:family_tasks/features/family/domain/group_invite.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final onboardingFlagsStorageProvider = Provider<OnboardingFlagsStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return OnboardingFlagsStorage(box);
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) {
    yield null;
    return;
  }

  final repository = ref.watch(groupRepositoryProvider);
  await repository.ensureUserProfile(UserProfile.fromFirebaseUser(user));

  await for (final profile in repository.watchUserProfile(user.uid)) {
    if (profile == null) {
      yield UserProfile.fromFirebaseUser(user);
    } else {
      yield profile;
    }
  }
});

final familyGroupProvider = StreamProvider<FamilyGroup?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile?.groupId == null) return Stream.value(null);
  return ref.watch(groupRepositoryProvider).watchGroup(profile!.groupId!);
});

final groupMembersProvider = StreamProvider<List<GroupMember>>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile?.groupId == null) return Stream.value([]);
  return ref.watch(groupRepositoryProvider).watchMembers(profile!.groupId!);
});

final latestGroupInviteProvider = StreamProvider<GroupInvite?>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile?.groupId == null || !profile!.isOwner) return Stream.value(null);
  return ref.watch(groupRepositoryProvider).watchLatestInvite(
        groupId: profile.groupId!,
        ownerId: profile.userId,
      );
});

class TaskScope {
  const TaskScope({required this.userId, this.groupId});

  final String userId;
  final String? groupId;
}

final taskScopeProvider = Provider<TaskScope?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return TaskScope(userId: user.uid, groupId: profile?.groupId);
});