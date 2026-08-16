import 'package:family_tasks/core/firebase/firestore_errors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('permission-denied and unauthenticated are auth loss', () {
    expect(
      isFirestoreAuthLoss(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      isTrue,
    );
    expect(
      isFirestoreAuthLoss(
        FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated'),
      ),
      isTrue,
    );
    expect(
      isFirestoreAuthLoss(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
      isFalse,
    );
    expect(isFirestoreAuthLoss(StateError('nope')), isFalse);
  });
}
