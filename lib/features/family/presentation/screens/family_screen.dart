import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/auth/presentation/widgets/email_verification_card.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/family/presentation/utils/family_onboarding.dart';
import 'package:family_tasks/features/family/presentation/widgets/member_tile.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final groupAsync = ref.watch(familyGroupProvider);
    final membersAsync = ref.watch(groupMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Group'),
        actions: [
          if (profileAsync.valueOrNull?.isOwner ?? false)
            IconButton(
              onPressed: () => context.push(AppRoutes.familyInvite),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'Invite member',
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Not signed in'));
          }

          if (!profile.hasGroup) {
            return _NoGroupView(profile: profile);
          }

          return groupAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
            data: (group) {
              if (group == null) {
                return const Center(child: Text('Group not found'));
              }

              return membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
                data: (members) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${members.length}/${AppConstants.maxGroupMembers} members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.onSurfaceMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...members.map(
                      (member) => MemberTile(
                        member: member,
                        onRemove: profile.isOwner &&
                                member.userId != profile.userId
                            ? () => _removeMember(context, ref, profile, member.userId)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (profile.isOwner)
                      FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.familyInvite),
                        icon: const Icon(Icons.link_rounded),
                        label: const Text('Invite member'),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _leaveOrDissolve(
                        context,
                        ref,
                        profile,
                        members,
                      ),
                      icon: Icon(
                        profile.isOwner &&
                                members
                                        .where((m) => m.userId != profile.userId)
                                        .isEmpty
                            ? Icons.delete_forever_outlined
                            : Icons.logout_rounded,
                      ),
                      label: Text(
                        profile.isOwner &&
                                members
                                        .where((m) => m.userId != profile.userId)
                                        .isEmpty
                            ? 'Dissolve group'
                            : 'Leave group',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    String memberId,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'Remove member?',
      message: 'They will lose access to the family group.',
    );
    if (confirmed != true || profile.groupId == null) return;

    try {
      await ref.read(groupRepositoryProvider).removeMember(
            groupId: profile.groupId!,
            ownerId: profile.userId,
            memberId: memberId,
          );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _leaveOrDissolve(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    List<GroupMember> members,
  ) async {
    if (profile.groupId == null) return;

    final isOwner = profile.isOwner;
    final confirmed = await _confirm(
      context,
      title: isOwner ? 'Dissolve group?' : 'Leave group?',
      message: isOwner
          ? 'If you are the only member, the group is removed. Tasks you created come back to you as personal. '
            'If others remain, they become owner and keep the family board; your created tasks return to you.'
          : 'Family tasks you did not create stay with the group. Tasks you created come back to you as personal.',
      confirmLabel: isOwner ? 'Dissolve' : 'Leave',
    );
    if (confirmed != true) return;

    try {
      final repository = ref.read(groupRepositoryProvider);
      if (isOwner) {
        final hasOtherMembers =
            members.where((m) => m.userId != profile.userId).isNotEmpty;
        if (hasOtherMembers) {
          await repository.leaveGroup(
            groupId: profile.groupId!,
            userId: profile.userId,
            role: GroupRole.owner,
          );
        } else {
          await repository.dissolveGroup(
            groupId: profile.groupId!,
            ownerId: profile.userId,
          );
        }
      } else {
        await repository.leaveGroup(
          groupId: profile.groupId!,
          userId: profile.userId,
          role: GroupRole.member,
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _NoGroupView extends ConsumerStatefulWidget {
  const _NoGroupView({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_NoGroupView> createState() => _NoGroupViewState();
}

class _NoGroupViewState extends ConsumerState<_NoGroupView> {
  final _groupNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            owner: widget.profile,
            name: name,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family group created')),
      );
      await showInviteAfterCreateIfNeeded(
        context: context,
        ref: ref,
        userId: widget.profile.userId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _joinGroup() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an invite code')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(groupRepositoryProvider).joinGroup(
            user: widget.profile,
            inviteCode: code,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined the family group')),
      );
      await showJoinWelcomeIfNeeded(
        context: context,
        ref: ref,
        userId: widget.profile.userId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = ref.watch(emailVerifiedProvider);
    if (!verified) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          EmptyState(
            icon: Icons.mark_email_unread_outlined,
            title: 'Verify email to use Family',
            subtitle:
                'Personal tasks are available. Create or join a family after you confirm your email.',
          ),
          SizedBox(height: 16),
          EmailVerificationCard(),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EmptyState(
          icon: Icons.family_restroom_outlined,
          title: 'No family group yet',
          subtitle:
              'Create a group as owner or join with an invite code from your family.',
        ),
        const SizedBox(height: 24),
        Text(
          'Create a group',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _groupNameController,
          decoration: const InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Smith Family',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isBusy ? null : _createGroup,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create as owner'),
        ),
        const SizedBox(height: 32),
        Text(
          'Join a group',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _inviteCodeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            hintText: 'ABC123',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _joinGroup,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Join with code'),
        ),
      ],
    );
  }
}