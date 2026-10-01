import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-owned Gemini key stays encrypted on the device and never in source.
class GeminiKeyStore {
  GeminiKeyStore._();
  static const _keyName = 'gemini_image_key_v1';
  static const _enabledName = 'gemini_image_enabled_v1';
  static const _secure = FlutterSecureStorage();

  static Future<String?> activeKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_enabledName) != true) return null;
    final key = await _secure.read(key: _keyName);
    return key?.trim().isNotEmpty == true ? key!.trim() : null;
  }

  static Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_enabledName) == true;

  static Future<void> save(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty || trimmed.length > 256) {
      throw ArgumentError('Introduce una clave válida.');
    }
    await _secure.write(key: _keyName, value: trimmed);
    await (await SharedPreferences.getInstance()).setBool(_enabledName, true);
  }

  static Future<void> useLocalReader() async =>
      (await SharedPreferences.getInstance()).setBool(_enabledName, false);

  static Future<void> deleteKey() async {
    await _secure.delete(key: _keyName);
    await useLocalReader();
  }
}
