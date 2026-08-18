import 'package:family_tasks/features/auth/data/auth_repository.dart';
import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({this.signInError, this.registerError});

  AuthException? signInError;
  AuthException? registerError;
  String? lastResetEmail;
  String? lastDisplayName;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final error = signInError;
    if (error != null) throw error;
    throw const AuthFailedException('Sign-in not stubbed.');
  }

  @override
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final error = registerError;
    if (error != null) throw error;
    throw const AuthFailedException('Register not stubbed.');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    lastDisplayName = displayName;
  }
}
