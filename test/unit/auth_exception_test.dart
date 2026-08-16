import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AuthFailedException map(String code) {
    return authFailedFromFirebase(
      FirebaseAuthException(code: code, message: 'raw'),
    );
  }

  group('AUTH-N mapped Firebase errors', () {
    test('AUTH-N-01 wrong password is generic', () {
      expect(map('wrong-password').message, 'Incorrect email or password.');
      expect(map('invalid-credential').message, 'Incorrect email or password.');
    });

    test('AUTH-N-04 duplicate email', () {
      expect(
        map('email-already-in-use').message,
        'An account already exists for this email.',
      );
    });

    test('AUTH-N-02 unknown email message exists', () {
      expect(map('user-not-found').message, contains('No account found'));
    });

    test('weak password is explicit', () {
      expect(map('weak-password').message, contains('8 characters'));
    });
  });
}
