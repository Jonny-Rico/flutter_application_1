import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _AccountMenuAction { settings, logOut }

/// Menu on each root tab. Opens Settings or logs out.
class AccountMenuButton extends ConsumerWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AccountMenuAction>(
      key: const ValueKey('account-menu'),
      tooltip: 'Menu',
      icon: const Icon(Icons.menu),
      iconSize: 28.8,
      offset: const Offset(0, 12),
      onSelected: (action) => _onSelected(context, ref, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AccountMenuAction.settings,
          child: _AccountMenuRow(
            icon: Icons.settings_outlined,
            label: 'Settings',
          ),
        ),
        PopupMenuItem(
          value: _AccountMenuAction.logOut,
          child: _AccountMenuRow(
            icon: Icons.logout_rounded,
            label: 'Log Out',
          ),
        ),
      ],
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _AccountMenuAction action,
  ) async {
    switch (action) {
      case _AccountMenuAction.settings:
        context.push(AppRoutes.settings);
      case _AccountMenuAction.logOut:
        try {
          await ref.read(authRepositoryProvider).signOut();
        } catch (error) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Log out failed: $error'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
    }
  }
}

class _AccountMenuRow extends StatelessWidget {
  const _AccountMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
