import 'package:family_tasks/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';

/// Collects email + password to link to the current Auth session.
class LinkEmailPasswordDialog extends StatefulWidget {
  const LinkEmailPasswordDialog({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<LinkEmailPasswordDialog> createState() =>
      _LinkEmailPasswordDialogState();
}

class _LinkEmailPasswordDialogState extends State<LinkEmailPasswordDialog> {
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  var _obscure = true;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      email: _email.text.trim(),
      password: _password.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add email and password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'If this Google or email was used to register a separate '
                'FamilyTasks account, linking will fail and data will not merge.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                readOnly: widget.initialEmail.isNotEmpty,
                enabled: widget.initialEmail.isEmpty,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  helperText: 'Password will be for this address',
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
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
                validator: (value) {
                  if ((value ?? '').length < AuthRepository.minPasswordLength) {
                    return 'At least ${AuthRepository.minPasswordLength} characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirm,
                obscureText: _obscure,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (value) {
                  if (value != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Link'),
        ),
      ],
    );
  }
}
