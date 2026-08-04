import 'dart:convert';

import 'package:crypto/crypto.dart';

class PinService {
  const PinService();

  String hashPin(String projectId, String pin) {
    final normalized = pin.trim();
    if (!RegExp(r'^\d{4,8}$').hasMatch(normalized)) {
      throw const FormatException('PIN must contain 4 to 8 digits.');
    }
    return sha256.convert(utf8.encode('$projectId:$normalized:haciendo-v1')).toString();
  }

  bool verify({
    required String projectId,
    required String pin,
    required String storedHash,
  }) =>
      hashPin(projectId, pin) == storedHash;
}
