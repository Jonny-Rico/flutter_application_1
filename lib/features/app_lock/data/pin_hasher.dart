import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

abstract final class PinHasher {
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hash(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$salt:$pin'));
    return digest.toString();
  }

  static bool verify({
    required String pin,
    required String salt,
    required String expectedHash,
  }) {
    return hash(pin, salt) == expectedHash;
  }
}
