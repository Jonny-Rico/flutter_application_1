import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Explains the family gate and lets the user resend / refresh verification.
class EmailVerificationCard extends ConsumerStatefulWidget {
  const EmailVerificationCard({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  ConsumerState<EmailVerificationCard> createState() =>
      _EmailVerificationCardState();
}

class _EmailVerificationCardState extends ConsumerState<EmailVerificationCard> {
  var _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Check your inbox.')),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final user = await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (!mounted) return;
      if (user?.emailVerified ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified. You can join a family.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not verified yet. Open the link in the email first.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? 'your email';
    final theme = Theme.of(context);

    return Card(
      color: AppColors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Verify your email',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.compact
                  ? 'Family is locked until you confirm $email.'
                  : 'We sent a link to $email. Confirm it to create or join a family. Personal tasks work now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _refresh,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I have verified'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Resend email'),
            ),
          ],
        ),
      ),
    );
  }
}
