import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  String? _generatedCode;
  DateTime? _generatedExpiresAt;
  bool _isGenerating = false;

  Future<void> _generateCode() async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile?.groupId == null || !profile!.isOwner) return;

    setState(() => _isGenerating = true);
    try {
      final code = await ref.read(groupRepositoryProvider).createInvite(
            groupId: profile.groupId!,
            ownerId: profile.userId,
          );
      setState(() {
        _generatedCode = code;
        _generatedExpiresAt = DateTime.now().add(AppConstants.inviteTtl);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final latestInvite = ref.watch(latestGroupInviteProvider).valueOrNull;
    final code = _generatedCode ?? latestInvite?.inviteCode;
    final expiresAt = _generatedExpiresAt ?? latestInvite?.expiresAt;
    final isExpired = latestInvite != null &&
        _generatedCode == null &&
        !latestInvite.isValid;

    if (profile != null && !profile.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invite member')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only the group owner can invite new members.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final expiresLabel = expiresAt != null
        ? DateFormat('MMM d, yyyy • HH:mm').format(expiresAt)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Invite member')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Share invite code',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send this code to one family member. They join from the Family tab. '
            'One code works for one person. For the next person, tap Regenerate. '
            'Codes expire in ${AppConstants.inviteTtl.inDays} days. '
            'A new code revokes the previous one.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 24),
          if (code != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      code,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        color: isExpired ? AppColors.onSurfaceMuted : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (expiresLabel != null)
                      Text(
                        isExpired
                            ? 'Expired $expiresLabel — generate a new code'
                            : 'Expires $expiresLabel',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? AppColors.danger
                              : AppColors.onSurfaceMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (!isExpired) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _copyCode(code),
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy code'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No active invite code yet.'),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateCode,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(
              _isGenerating
                  ? 'Generating...'
                  : (code == null ? 'Generate code' : 'Regenerate code'),
            ),
          ),
        ],
      ),
    );
  }
}
