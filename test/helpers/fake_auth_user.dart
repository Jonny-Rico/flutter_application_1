import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthUser extends Fake implements User {
  FakeAuthUser({
    this.uid = 'user-a',
    this.email = 'qa.a.familytasks@example.com',
    this.displayName = 'QA User A',
    this.emailVerified = true,
  });

  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool emailVerified;

  @override
  String? get photoURL => null;

  @override
  List<UserInfo> get providerData => const [];
}
