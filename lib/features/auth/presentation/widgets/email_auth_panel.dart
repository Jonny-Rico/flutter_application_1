import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';

enum EmailAuthMode { signIn, register, reset }

class EmailAuthPanel extends StatefulWidget {
  const EmailAuthPanel({
    super.key,
    required this.mode,
    required this.busy,
    required this.onSignIn,
    required this.onRegister,
    required this.onReset,
    required this.onSwitchMode,
    required this.onBack,
  });

  final EmailAuthMode mode;
  final bool busy;
  final Future<void> Function(String email, String password) onSignIn;
  final Future<void> Function(String name, String email, String password)
      onRegister;
  final Future<void> Function(String email) onReset;
  final ValueChanged<EmailAuthMode> onSwitchMode;
  final VoidCallback onBack;

  @override
  State<EmailAuthPanel> createState() => _EmailAuthPanelState();
}

class _EmailAuthPanelState extends State<EmailAuthPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < AuthRepository.minPasswordLength) {
      return 'At least ${AuthRepository.minPasswordLength} characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (widget.busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    switch (widget.mode) {
      case EmailAuthMode.signIn:
        await widget.onSignIn(
          _emailController.text,
          _passwordController.text,
        );
      case EmailAuthMode.register:
        await widget.onRegister(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
      case EmailAuthMode.reset:
        await widget.onReset(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = switch (widget.mode) {
      EmailAuthMode.signIn => 'Sign in with email',
      EmailAuthMode.register => 'Create account',
      EmailAuthMode.reset => 'Reset password',
    };
    final actionLabel = switch (widget.mode) {
      EmailAuthMode.signIn => 'Sign in',
      EmailAuthMode.register => 'Create account',
      EmailAuthMode.reset => 'Send reset link',
    };

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: widget.busy ? null : widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.white,
              ),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.mode == EmailAuthMode.register) ...[
            TextFormField(
              controller: _nameController,
              enabled: !widget.busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'Shown to family members',
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 2) {
                  return 'Enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
          ],
          TextFormField(
            controller: _emailController,
            enabled: !widget.busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: widget.mode == EmailAuthMode.reset
                ? TextInputAction.done
                : TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
            validator: _emailValidator,
          ),
          if (widget.mode != EmailAuthMode.reset) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              enabled: !widget.busy,
              obscureText: _obscure,
              textInputAction: widget.mode == EmailAuthMode.register
                  ? TextInputAction.next
                  : TextInputAction.done,
              onFieldSubmitted: (_) {
                if (widget.mode == EmailAuthMode.signIn) _submit();
              },
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _passwordValidator,
            ),
          ],
          if (widget.mode == EmailAuthMode.register) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmController,
              enabled: !widget.busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Confirm password',
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return _passwordValidator(value);
              },
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: widget.busy ? null : _submit,
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(actionLabel),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.mode == EmailAuthMode.signIn)
            TextButton(
              onPressed: widget.busy
                  ? null
                  : () => widget.onSwitchMode(EmailAuthMode.reset),
              child: const Text('Forgot password?'),
            ),
          if (widget.mode == EmailAuthMode.signIn)
            TextButton(
              onPressed: widget.busy
                  ? null
                  : () => widget.onSwitchMode(EmailAuthMode.register),
              child: Text(
                'Create an account',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          if (widget.mode == EmailAuthMode.register)
            TextButton(
              onPressed: widget.busy
                  ? null
                  : () => widget.onSwitchMode(EmailAuthMode.signIn),
              child: const Text('Already have an account? Sign in'),
            ),
          if (widget.mode == EmailAuthMode.reset)
            Text(
              'We will email a link to set a new password.',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
