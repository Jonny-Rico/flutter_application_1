import 'package:family_tasks/core/constants/firebase_constants.dart';
import 'package:family_tasks/features/auth/domain/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: FirebaseConstants.googleWebClientId,
            );

  static const minPasswordLength = 8;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// Includes profile updates (e.g. emailVerified after reload).
  Stream<User?> authStateChanges() => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  static const googleProviderId = 'google.com';
  static const passwordProviderId = 'password';

  bool hasProvider(String providerId) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == providerId);
  }

  bool get hasGoogleProvider => hasProvider(googleProviderId);

  bool get hasPasswordProvider => hasProvider(passwordProviderId);

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthCancelledException();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final name = displayName.trim();
    if (name.length < 2) {
      throw const AuthFailedException('Enter your name (at least 2 characters).');
    }
    if (password.length < minPasswordLength) {
      throw const AuthFailedException(
        'Password must be at least 8 characters.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      try {
        await credential.user?.sendEmailVerification();
      } on FirebaseAuthException {
        // Account exists even if the verification mail fails.
      }
      await credential.user?.reload();
      return credential;
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthFailedException('Enter your email address.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-not-found') return;
      throw authFailedFromFirebase(error);
    }
  }

  /// Link the current session to a Google account. Same uid.
  Future<User> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailedException('Not signed in.');
    }
    if (hasGoogleProvider) {
      throw const AuthFailedException('Google is already linked.');
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthCancelledException();
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.linkWithCredential(credential);
      await user.reload();
      return _auth.currentUser ?? user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      await _googleSignIn.signOut();
      throw authFailedFromFirebase(error);
    }
  }

  /// Add email + password to the current session (typically a Google user).
  Future<User> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailedException('Not signed in.');
    }
    if (hasPasswordProvider) {
      throw const AuthFailedException('Email and password are already linked.');
    }
    if (password.length < minPasswordLength) {
      throw const AuthFailedException(
        'Password must be at least 8 characters.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.linkWithCredential(credential);
      if (!(user.emailVerified)) {
        try {
          await user.sendEmailVerification();
        } on FirebaseAuthException {
          // Link succeeded even if the mail fails.
        }
      }
      await user.reload();
      return _auth.currentUser ?? user;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailedException('Not signed in.');
    }
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final name = displayName.trim();
    if (name.length < 2) {
      throw const AuthFailedException('Enter your name (at least 2 characters).');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthFailedException('Not signed in.');
    }
    try {
      await user.updateDisplayName(name);
      await user.reload();
    } on FirebaseAuthException catch (error) {
      throw authFailedFromFirebase(error);
    }
  }

  /// Reloads Auth user so [emailVerified] updates after the link is opened.
  Future<User?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    // Refresh ID token so Firestore rules see email_verified.
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser;
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}