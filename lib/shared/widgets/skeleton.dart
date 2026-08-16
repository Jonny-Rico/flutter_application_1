import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = 10,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class TaskListSkeleton extends StatelessWidget {
  const TaskListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.scrollBottom,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _TaskRowSkeleton(),
    );
  }
}

class _TaskRowSkeleton extends StatelessWidget {
  const _TaskRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 22, height: 22, borderRadius: 6),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 120, height: 10),
              ],
            ),
          ),
          SkeletonBox(width: 28, height: 28, borderRadius: 14),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.scrollBottom,
      ),
      children: [
        const SkeletonBox(width: 100, height: 16),
        const SizedBox(height: AppSpacing.sectionTitle),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: SkeletonBox(height: 72, borderRadius: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: SkeletonBox(height: 72, borderRadius: 16),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.section),
        const SkeletonBox(width: 120, height: 16),
        const SizedBox(height: AppSpacing.sectionTitle),
        const SkeletonBox(height: 96, borderRadius: 16),
        const SizedBox(height: AppSpacing.section),
        const SkeletonBox(width: 90, height: 16),
        const SizedBox(height: AppSpacing.sectionTitle),
        const SkeletonBox(height: 120, borderRadius: 16),
        const SizedBox(height: AppSpacing.section),
        const SkeletonBox(width: 110, height: 16),
        const SizedBox(height: AppSpacing.sectionTitle),
        const SkeletonBox(height: 140, borderRadius: 16),
      ],
    );
  }
}
