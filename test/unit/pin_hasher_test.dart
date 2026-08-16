import 'package:family_tasks/features/app_lock/data/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LOCK-P-02 / LOCK-N-01 PIN hash', () {
    test('correct PIN verifies', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', salt);

      expect(
        PinHasher.verify(pin: '1234', salt: salt, expectedHash: hash),
        isTrue,
      );
    });

    test('wrong PIN does not verify', () {
      final salt = PinHasher.generateSalt();
      final hash = PinHasher.hash('1234', salt);

      expect(
        PinHasher.verify(pin: '0000', salt: salt, expectedHash: hash),
        isFalse,
      );
    });
  });
}
