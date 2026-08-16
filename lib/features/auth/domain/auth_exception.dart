import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Sign-in was cancelled.');
}

final class AuthFailedException extends AuthException {
  const AuthFailedException(super.message);
}

AuthFailedException authFailedFromFirebase(FirebaseAuthException error) {
  return AuthFailedException(switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' => 'No account found for this email.',
    'wrong-password' || 'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Password must be at least 8 characters.',
    'too-many-requests' => 'Too many attempts. Try again later.',
    'network-request-failed' => 'Network error. Check your connection.',
    'operation-not-allowed' =>
      'Email sign-in is not enabled. Turn on Email/Password in Firebase Console.',
    'credential-already-in-use' || 'account-exists-with-different-credential' =>
      'This Google or email account is already used by another user. Sign in with that account instead.',
    'provider-already-linked' => 'This sign-in method is already linked.',
    'requires-recent-login' =>
      'For security, sign out and sign in again, then retry.',
    _ => error.message ?? 'Authentication failed.',
  });
}
