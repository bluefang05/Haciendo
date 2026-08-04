import 'package:flutter/services.dart';

class PlatformService {
  PlatformService._();
  static final PlatformService instance = PlatformService._();

  static const MethodChannel _channel =
      MethodChannel('com.enmanuelapps.haciendo/platform');

  Future<Map<String, String>> getAppDirectories() async {
    final result = await _channel.invokeMapMethod<String, String>(
      'getAppDirectories',
    );
    if (result == null || result['files'] == null || result['cache'] == null) {
      throw StateError('Android did not provide application directories.');
    }
    return result;
  }

  Future<void> shareFiles(
    List<String> paths, {
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    await _channel.invokeMethod<void>('shareFiles', {
      'paths': paths,
      'mimeType': mimeType,
      'subject': subject,
      'text': text,
    });
  }

  Future<void> shareText(String text, {String? subject}) async {
    await _channel.invokeMethod<void>('shareText', {
      'text': text,
      'subject': subject,
    });
  }
}
