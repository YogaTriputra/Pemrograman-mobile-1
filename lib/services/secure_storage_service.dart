import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/logger.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    Logger.debug(LogEvent.storageWrite);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'auth_token');
    Logger.debug(LogEvent.storageRead);
    return token;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
    Logger.debug(LogEvent.storageDelete);
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: 'user_pin', value: pin);
    Logger.debug(LogEvent.storageWrite);
  }

  Future<String?> getPin() async {
    final pin = await _storage.read(key: 'user_pin');
    Logger.debug(LogEvent.storageRead);
    return pin;
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
    Logger.debug(LogEvent.storageDelete);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }
}
