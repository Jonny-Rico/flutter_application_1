import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onBiometrics,
    this.showBiometrics = false,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometrics;
  final bool showBiometrics;

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      [showBiometrics ? 'bio' : '', '0', 'del'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final key in row)
                  _KeyButton(
                    label: key,
                    onTap: () {
                      if (key == 'del') {
                        onBackspace();
                      } else if (key == 'bio') {
                        onBiometrics?.call();
                      } else if (key.isNotEmpty) {
                        onDigit(key);
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 72);
    }

    final isAction = label == 'del' || label == 'bio';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isAction
                ? Colors.transparent
                : AppColors.surfaceElevated.withValues(alpha: 0.9),
            border: isAction
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(
            child: label == 'del'
                ? const Icon(Icons.backspace_outlined, size: 22)
                : label == 'bio'
                    ? Icon(
                        Icons.fingerprint_rounded,
                        size: 28,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}

class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.error = false,
  });

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? AppColors.danger
        : Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? color : Colors.transparent,
              border: Border.all(
                color: i < filled
                    ? color
                    : AppColors.onSurfaceMuted.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}
