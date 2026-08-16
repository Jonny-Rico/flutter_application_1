import 'package:family_tasks/features/family/domain/group_invite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GroupInvite invite({
    required DateTime expiresAt,
    String status = 'pending',
  }) {
    return GroupInvite(
      id: 'ABC123',
      groupId: 'g1',
      invitedBy: 'user-a',
      inviteCode: 'ABC123',
      status: status,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: expiresAt,
    );
  }

  group('FAM-N-01 / FAM-N-02 invite validity', () {
    test('pending future expiry is valid', () {
      expect(
        invite(expiresAt: DateTime.now().add(const Duration(days: 1))).isValid,
        isTrue,
      );
    });

    test('expired pending is invalid', () {
      expect(
        invite(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        ).isValid,
        isFalse,
      );
    });

    test('accepted code is invalid even if not expired', () {
      expect(
        invite(
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          status: 'accepted',
        ).isValid,
        isFalse,
      );
    });
  });
}
