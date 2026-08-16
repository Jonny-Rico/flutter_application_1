import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _pinLength = 4;

/// Full-screen flow: enter PIN twice. Returns the PIN via [Navigator.pop], or null if cancelled.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    super.key,
    this.title = 'Create PIN',
  });

  final String title;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _first = '';
  String _current = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String digit) {
    if (_current.length >= _pinLength) return;
    setState(() {
      _error = null;
      _current += digit;
    });
    if (_current.length == _pinLength) {
      _onCompleteEntry();
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() {
      _error = null;
      _current = _current.substring(0, _current.length - 1);
    });
  }

  void _onCompleteEntry() {
    if (!_confirming) {
      setState(() {
        _first = _current;
        _current = '';
        _confirming = true;
      });
      return;
    }

    if (_current != _first) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'PINs do not match. Try again.';
        _first = '';
        _current = '';
        _confirming = false;
      });
      return;
    }

    Navigator.of(context).pop(_current);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _confirming
        ? 'Re-enter PIN to confirm'
        : 'Choose a 4-digit PIN';

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                _confirming ? 'Confirm PIN' : 'Create PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 28),
              PinDots(
                length: _pinLength,
                filled: _current.length,
                error: _error != null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              PinPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen: verify existing PIN. Pops `true` if correct.
class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({
    super.key,
    required this.verify,
    this.title = 'Enter PIN',
    this.subtitle = 'Confirm with your app PIN',
  });

  final bool Function(String pin) verify;
  final String title;
  final String subtitle;

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  String _pin = '';
  String? _error;

  void _onDigit(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _error = null;
      _pin += digit;
    });
    if (_pin.length == _pinLength) {
      final ok = widget.verify(_pin);
      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Wrong PIN';
        _pin = '';
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _error = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 28),
              PinDots(
                length: _pinLength,
                filled: _pin.length,
                error: _error != null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              PinPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
