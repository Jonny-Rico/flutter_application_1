import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:flutter/material.dart';

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    this.onRemove,
  });

  final GroupMember member;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage:
            member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        child: member.photoUrl == null
            ? Icon(Icons.person, color: theme.colorScheme.primary)
            : null,
      ),
      title: Text(member.displayName.isNotEmpty ? member.displayName : 'Member'),
      subtitle: Text(
        member.role == GroupRole.owner ? 'Owner' : 'Family member',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.onSurfaceMuted,
        ),
      ),
      trailing: onRemove != null
          ? IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined),
              color: AppColors.danger,
              tooltip: 'Remove member',
            )
          : (member.role == GroupRole.owner
              ? Chip(
                  label: Text(
                    'Owner',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                )
              : null),
    );
  }
}