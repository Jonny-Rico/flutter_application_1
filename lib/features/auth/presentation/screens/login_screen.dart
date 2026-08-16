import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/auth/presentation/widgets/email_auth_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login / Home — design variant K (Aurora curtains) + Google or email.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  EmailAuthMode? _emailMode;

  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() => _isLoading = true);
    try {
      await action();
    } on AuthCancelledException {
      // User closed the Google account picker.
    } on AuthException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('Sign-in failed: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    await _runAuth(() => ref.read(authRepositoryProvider).signInWithGoogle());
  }

  Future<void> _signInWithEmail(String email, String password) async {
    await _runAuth(
      () => ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> _register(
    String name,
    String email,
    String password,
  ) async {
    await _runAuth(() async {
      await ref.read(authRepositoryProvider).registerWithEmail(
            displayName: name,
            email: email,
            password: password,
          );
      AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Check your email to verify before joining a family.',
          ),
        ),
      );
    });
  }

  Future<void> _resetPassword(String email) async {
    await _runAuth(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for that email, we sent a reset link.',
          ),
        ),
      );
      setState(() => _emailMode = EmailAuthMode.signIn);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact = _emailMode != null || keyboard > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF080C12),
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackground(),
          const _AuroraScrim(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottomInset * 0.15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: _AppLogoMark(
                      size: compact ? 88 : 192,
                      borderRadius: compact ? 22 : 44,
                    ),
                  ),
                  if (_emailMode == null) ...[
                    const Spacer(),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        fontSize: compact ? 26 : 32,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Organize home life — beautifully.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _AccentLine(),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleMark(),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(
                                  () => _emailMode = EmailAuthMode.signIn,
                                ),
                        child: const Text('Sign in with email'),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                                () => _emailMode = EmailAuthMode.register,
                              ),
                      child: const Text('Create account'),
                    ),
                    Text(
                      'Google or email · same family space',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceMuted.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(top: 16, bottom: keyboard),
                        child: EmailAuthPanel(
                          mode: _emailMode!,
                          busy: _isLoading,
                          onSignIn: _signInWithEmail,
                          onRegister: _register,
                          onReset: _resetPassword,
                          onSwitchMode: (mode) =>
                              setState(() => _emailMode = mode),
                          onBack: () => setState(() => _emailMode = null),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/login_bg_k.jpg',
      fit: BoxFit.cover,
      color: Colors.black.withValues(alpha: 0.28),
      colorBlendMode: BlendMode.darken,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: Color(0xFF0F1419)),
    );
  }
}

/// Vertical aurora bands + bottom readability gradient (variant K).
class _AuroraScrim extends StatelessWidget {
  const _AuroraScrim();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF080C12).withValues(alpha: 0.45),
              const Color(0xFF080C12).withValues(alpha: 0.12),
              const Color(0xFF080C12).withValues(alpha: 0.55),
              const Color(0xFF080C12).withValues(alpha: 0.94),
            ],
            stops: const [0.0, 0.35, 0.62, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.9, -1),
                  end: const Alignment(0.6, 1),
                  colors: [
                    Colors.transparent,
                    AppColors.seed.withValues(alpha: 0.14),
                    Colors.transparent,
                    const Color(0xFFA78BFA).withValues(alpha: 0.14),
                    Colors.transparent,
                    AppColors.seed.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.18, 0.32, 0.52, 0.68, 0.86, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppLogoMark extends StatelessWidget {
  const _AppLogoMark({
    required this.size,
    required this.borderRadius,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: AppColors.surfaceElevated,
          child: Icon(
            Icons.home_work_rounded,
            color: AppColors.seed,
            size: size * 0.45,
          ),
        ),
      ),
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 36,
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: const LinearGradient(
            colors: [AppColors.seed, Color(0xFFA78BFA)],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
  }
}
