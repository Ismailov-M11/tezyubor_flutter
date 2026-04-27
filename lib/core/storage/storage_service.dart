import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage — for tokens
  static Future<void> setToken(String token) =>
      _secureStorage.write(key: 'auth_token', value: token);

  static Future<String?> getToken() =>
      _secureStorage.read(key: 'auth_token');

  static Future<void> deleteToken() =>
      _secureStorage.delete(key: 'auth_token');

  // Shared preferences — for settings
  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  static String? getString(String key) => _prefs.getString(key);

  static Future<void> remove(String key) => _prefs.remove(key);

  static Future<void> clear() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
