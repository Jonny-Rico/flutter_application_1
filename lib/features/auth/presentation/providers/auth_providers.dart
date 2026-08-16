import 'package:family_tasks/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// True when the signed-in user has a verified email (Google usually is).
final emailVerifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.emailVerified ?? false;
});

final hasGoogleProviderProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.providerData.any(
        (info) => info.providerId == AuthRepository.googleProviderId,
      ) ??
      false;
});

final hasPasswordProviderProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.providerData.any(
        (info) => info.providerId == AuthRepository.passwordProviderId,
      ) ??
      false;
});