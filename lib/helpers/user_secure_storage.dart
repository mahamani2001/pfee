import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ignore: avoid_classes_with_only_static_members
class UserSecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _keyUsername = 'mypsy_username';
  static const _keyPwd = 'mypsy_password';

  static IOSOptions _getIOSOptions() => const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      );

  static AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  static Future setUsername(String? username) async => await _storage.write(
        key: _keyUsername,
        value: username,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );

  static Future setPwd(String? pwd) async => await _storage.write(
        key: _keyPwd,
        value: pwd,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );

  static Future<String?> getUsername() async => await _storage.read(
        key: _keyUsername,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );

  static Future<String?> getPwd() async => await _storage.read(
        key: _keyPwd,
        iOptions: _getIOSOptions(),
        aOptions: _getAndroidOptions(),
      );

  static Future<void> deleteAllSecureData() async {
    await _storage.deleteAll(
      aOptions: _getAndroidOptions(),
      iOptions: _getIOSOptions(),
    );
  }
}
