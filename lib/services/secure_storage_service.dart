import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const _tokenKey = 'token';
  static const _pinKey = 'pin';

  Future<T> _perform<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      if (kDebugMode) debugPrint('Secure storage: berhasil.');
      return result;
    } catch (_) {
      if (kDebugMode) debugPrint('Secure storage: gagal.');
      rethrow;
    }
  }

  Future<void> saveToken(String token) =>
      _perform(() => _storage.write(key: _tokenKey, value: token));

  Future<String?> getToken() => _perform(() => _storage.read(key: _tokenKey));

  Future<void> deleteToken() => _perform(() => _storage.delete(key: _tokenKey));

  Future<void> savePin(String pin) =>
      _perform(() => _storage.write(key: _pinKey, value: pin));

  Future<String?> getPin() => _perform(() => _storage.read(key: _pinKey));

  Future<void> deleteAll() => _perform(() => _storage.deleteAll());

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
