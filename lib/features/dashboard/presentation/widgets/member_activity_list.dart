import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:family_tasks/features/dashboard/presentation/utils/dashboard_overview_navigation.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:flutter/material.dart';

class MemberActivityList extends StatelessWidget {
  const MemberActivityList({
    super.key,
    required this.members,
    this.overloadThreshold = kMemberOverloadThreshold,
  });

  final List<MemberActivityStat> members;
  final int overloadThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return DashboardCard(
        child: Text(
          'Join or create a family group to see member activity.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceMuted,
          ),
        ),
      );
    }

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.onSurfaceMuted.withValues(alpha: 0.12),
              ),
            _MemberRow(
              member: members[i],
              overloaded: members[i].assignedOpen >= overloadThreshold,
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.overloaded,
  });

  final MemberActivityStat member;
  final bool overloaded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = overloaded ? AppColors.warning : theme.colorScheme.primary;

    return Container(
      color: overloaded
          ? AppColors.warning.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.15),
            child: Text(
              member.displayName.isNotEmpty
                  ? member.displayName[0].toUpperCase()
                  : '?',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (overloaded) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Busy',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Open ${member.assignedOpen} · Done ${member.completed} · Created ${member.created}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: overloaded
                        ? AppColors.warning
                        : AppColors.onSurfaceMuted,
                    fontWeight:
                        overloaded ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (overloaded)
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}
