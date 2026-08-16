import 'package:firebase_core/firebase_core.dart';

/// True when a Firestore listener fails because the user signed out
/// or no longer has access. These are expected during auth transitions.
bool isFirestoreAuthLoss(Object error) {
  return error is FirebaseException &&
      (error.code == 'permission-denied' || error.code == 'unauthenticated');
}

extension IgnoreFirestoreAuthLoss<T> on Stream<T> {
  Stream<T> ignoreFirestoreAuthLoss() {
    return handleError((Object error, StackTrace stackTrace) {
      if (isFirestoreAuthLoss(error)) return;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}
