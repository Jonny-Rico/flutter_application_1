import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:family_tasks/features/app_lock/presentation/screens/pin_setup_screen.dart';
import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/auth/presentation/widgets/email_verification_card.dart';
import 'package:family_tasks/features/auth/presentation/widgets/link_email_password_dialog.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;
    final isSigningOut = ref.watch(_signOutLoadingProvider);
    final persistTaskFilters = ref.watch(taskPersistFiltersProvider);
    final notifyNewTasks = ref.watch(taskNotifyNewTasksProvider);
    final hapticsEnabled = ref.watch(appHapticsEnabledProvider);
    final lockConfig = ref.watch(appLockConfigProvider);
    final emailVerified = ref.watch(emailVerifiedProvider);
    final hasGoogle = ref.watch(hasGoogleProviderProvider);
    final hasPassword = ref.watch(hasPasswordProviderProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final displayName = (profile?.displayName.isNotEmpty ?? false)
        ? profile!.displayName
        : (user?.displayName ?? 'Profile');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary)
                  : null,
            ),
            title: Text(displayName),
            subtitle: Text(
              [
                user?.email ?? 'Not signed in',
                if (user != null && !emailVerified) 'Email not verified',
              ].join(' · '),
            ),
            trailing: user == null
                ? null
                : IconButton(
                    tooltip: 'Edit name',
                    onPressed: () => _editDisplayName(
                      context,
                      ref,
                      currentName: displayName == 'Profile' ? '' : displayName,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
          ),
          if (user != null && !emailVerified) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EmailVerificationCard(compact: true),
            ),
          ],
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                'Sign-in methods',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                'Linking adds a way to sign in. It does not merge two existing accounts.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.g_mobiledata_rounded),
              title: const Text('Google'),
              subtitle: Text(
                hasGoogle
                    ? 'Linked · you can sign in with Google'
                    : 'Not linked',
              ),
              trailing: hasGoogle
                  ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                  : TextButton(
                      onPressed: () => _linkGoogle(context, ref),
                      child: const Text('Link'),
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email and password'),
              subtitle: Text(
                hasPassword
                    ? 'Linked · you can sign in with email'
                    : 'Not linked',
              ),
              trailing: hasPassword
                  ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                  : TextButton(
                      onPressed: () => _linkEmailPassword(context, ref),
                      child: const Text('Add'),
                    ),
            ),
          ],
          const Divider(height: 32),
          SwitchListTile(
            secondary: const Icon(Icons.filter_list_rounded),
            title: const Text('Remember task filters'),
            subtitle: const Text(
              'When off, Tasks opens with All tab and All statuses',
            ),
            value: persistTaskFilters,
            onChanged: user == null
                ? null
                : (value) {
                    ref.read(taskPersistFiltersProvider.notifier).state = value;
                  },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notify about new tasks'),
            subtitle: const Text(
              'Alerts on this device after the app syncs. Not push while closed.',
            ),
            value: notifyNewTasks,
            onChanged: user == null
                ? null
                : (value) => _setNotifyNewTasks(context, ref, value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Haptic feedback'),
            subtitle: const Text(
              'Vibration when you mark Done or delete a task',
            ),
            value: hapticsEnabled,
            onChanged: user == null
                ? null
                : (value) {
                    ref.read(appHapticsEnabledProvider.notifier).state = value;
                    AppHaptics.enabled = value;
                    if (value) {
                      AppHaptics.light();
                    }
                  },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.lock_rounded),
            title: const Text('App lock'),
            subtitle: const Text(
              'PIN and biometrics when opening the app',
            ),
            value: lockConfig.isActive,
            onChanged: user == null
                ? null
                : (value) => _setAppLock(context, ref, value),
          ),
          if (lockConfig.isActive) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Unlock with biometrics'),
              subtitle: const Text(
                'Fingerprint / face when available; PIN always works',
              ),
              value: lockConfig.biometricsEnabled,
              onChanged: user == null
                  ? null
                  : (value) {
                      ref
                          .read(appLockConfigProvider.notifier)
                          .setBiometricsEnabled(value);
                    },
            ),
            ListTile(
              leading: const Icon(Icons.pin_rounded),
              title: const Text('Change PIN'),
              subtitle: const Text('Set a new 4-digit PIN'),
              onTap: user == null
                  ? null
                  : () => _changePin(context, ref),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification permission'),
            subtitle: const Text('Allow system notifications'),
            onTap: user == null
                ? null
                : () => _requestNotificationPermission(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Help'),
            subtitle: const Text('User manual (EN / RU)'),
            onTap: () => context.push(AppRoutes.help),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            subtitle: Text(AppConstants.appName),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              key: const ValueKey('sign-out-button'),
              onPressed: isSigningOut || user == null
                  ? null
                  : () => _signOut(context, ref),
              icon: isSigningOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: Text(isSigningOut ? 'Signing out...' : 'Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref, {
    required String currentName,
  }) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'Shown to family members',
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || !context.mounted) return;
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your name (at least 2 characters).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (name == currentName) return;

    try {
      await ref.read(authRepositoryProvider).updateDisplayName(name);
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (user != null) {
        await ref.read(groupRepositoryProvider).updateDisplayName(
              userId: user.uid,
              displayName: name,
              groupId: profile?.groupId,
            );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _linkGoogle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).linkGoogleAccount();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google account linked')),
      );
    } on AuthCancelledException {
      return;
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _linkEmailPassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).valueOrNull;
    final result = await showDialog<({String email, String password})>(
      context: context,
      builder: (_) => LinkEmailPasswordDialog(
        initialEmail: user?.email ?? '',
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).linkEmailPassword(
            email: result.email,
            password: result.password,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password linked')),
      );
    } on AuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _setAppLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      final pin = await Navigator.of(context, rootNavigator: true).push<String>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PinSetupScreen(title: 'Set up app lock'),
        ),
      );
      if (pin == null || !context.mounted) return;
      await ref.read(appLockConfigProvider.notifier).setPinAndEnable(pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App lock enabled')),
      );
      return;
    }

    final verified = await _verifyIdentity(
      context,
      ref,
      reason: 'Confirm to turn off app lock',
    );
    if (!verified || !context.mounted) return;

    await ref.read(appLockConfigProvider.notifier).disableAndClearPin();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App lock disabled')),
    );
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final verified = await _verifyIdentity(
      context,
      ref,
      reason: 'Confirm to change PIN',
    );
    if (!verified || !context.mounted) return;

    final pin = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const PinSetupScreen(title: 'Change PIN'),
      ),
    );
    if (pin == null || !context.mounted) return;
    await ref.read(appLockConfigProvider.notifier).changePin(pin);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN updated')),
    );
  }

  /// Biometrics (if enabled) or PIN verification.
  Future<bool> _verifyIdentity(
    BuildContext context,
    WidgetRef ref, {
    required String reason,
  }) async {
    final config = ref.read(appLockConfigProvider);
    final session = ref.read(appLockUnlockedProvider.notifier);

    if (config.biometricsEnabled) {
      final available =
          await ref.read(biometricAuthServiceProvider).isAvailable;
      if (available) {
        session.suppressLifecycleLock = true;
        try {
          final ok = await ref.read(biometricAuthServiceProvider).authenticate(
                reason: reason,
              );
          if (ok) return true;
        } finally {
          Future<void>.delayed(const Duration(milliseconds: 600), () {
            session.suppressLifecycleLock = false;
          });
        }
      }
    }

    if (!context.mounted) return false;
    final pinOk = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PinVerifyScreen(
          title: 'Confirm',
          subtitle: reason,
          verify: (pin) => ref.read(appLockConfigProvider.notifier).verifyPin(pin),
        ),
      ),
    );
    return pinOk == true;
  }

  Future<void> _setNotifyNewTasks(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    ref.read(taskNotifyNewTasksProvider.notifier).state = value;
    if (!value) return;

    final granted =
        await ref.read(taskNotificationSchedulerProvider).requestPermission();
    if (!context.mounted || granted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification permission denied. Enable it under Notification permission.',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _requestNotificationPermission(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final granted =
        await ref.read(taskNotificationSchedulerProvider).requestPermission();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notifications allowed'
              : 'Notification permission denied',
        ),
        backgroundColor: granted ? null : AppColors.danger,
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    ref.read(_signOutLoadingProvider.notifier).state = true;
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-out failed: $error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      ref.read(_signOutLoadingProvider.notifier).state = false;
    }
  }
}

final _signOutLoadingProvider = StateProvider<bool>((ref) => false);
