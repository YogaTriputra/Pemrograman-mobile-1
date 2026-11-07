import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:secure_http/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureStorageService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    service = SecureStorageService();
  });

  test('missing token and PIN return null', () async {
    expect(await service.getToken(), isNull);
    expect(await service.getPin(), isNull);
    expect(await service.hasToken(), isFalse);
  });

  test('saves and replaces token', () async {
    await service.saveToken('first-token');
    expect(await service.getToken(), 'first-token');
    expect(await service.hasToken(), isTrue);
    await service.saveToken('replacement-token');
    expect(await service.getToken(), 'replacement-token');
  });

  test('empty tokens are not considered authenticated', () async {
    await service.saveToken('');
    expect(await service.hasToken(), isFalse);
    await service.saveToken('  ');
    expect(await service.hasToken(), isFalse);
  });

  test('PIN retains leading zeroes and can be replaced', () async {
    await service.savePin('0123');
    expect(await service.getPin(), '0123');
    await service.savePin('0456');
    expect(await service.getPin(), '0456');
  });

  test('deleting token preserves PIN', () async {
    await service.saveToken('token');
    await service.savePin('0123');
    await service.deleteToken();
    expect(await service.getToken(), isNull);
    expect(await service.hasToken(), isFalse);
    expect(await service.getPin(), '0123');
    await service.deleteToken();
  });

  test('deleteAll removes all stored values', () async {
    await service.saveToken('token');
    await service.savePin('0123');
    await service.deleteAll();
    expect(await service.getToken(), isNull);
    expect(await service.getPin(), isNull);
    expect(await service.hasToken(), isFalse);
    await service.deleteAll();
  });

  test('storage logs fixed events without token or PIN values', () async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? value, {int? wrapWidth}) {
      if (value != null) logs.add(value);
    };
    addTearDown(() => debugPrint = original);
    await service.saveToken('private-token');
    await service.getToken();
    await service.savePin('0123');
    await service.getPin();
    await service.deleteToken();
    await service.deleteAll();
    expect(logs.map(jsonDecode).toList(), [
      {'level': 'debug', 'event': 'storageWrite'},
      {'level': 'debug', 'event': 'storageRead'},
      {'level': 'debug', 'event': 'storageWrite'},
      {'level': 'debug', 'event': 'storageRead'},
      {'level': 'debug', 'event': 'storageDelete'},
      {'level': 'debug', 'event': 'storageDelete'},
    ]);
  });

  test('supports injected secure storage', () async {
    const storage = FlutterSecureStorage();
    final injected = SecureStorageService(storage: storage);
    await injected.saveToken('token');
    expect(await injected.getToken(), 'token');
    await injected.savePin('0123');
    expect(await injected.getPin(), '0123');
  });
}
