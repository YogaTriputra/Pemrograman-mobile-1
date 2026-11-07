import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_http/utils/logger.dart';

void main() {
  late DebugPrintCallback originalDebugPrint;
  late List<String> output;

  setUp(() {
    originalDebugPrint = debugPrint;
    output = [];
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) output.add(message);
    };
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  test('each level emits one JSON object with only fixed level and event', () {
    Logger.debug(LogEvent.apiRequest);
    Logger.info(LogEvent.loginSuccess);
    Logger.warning(LogEvent.configInvalid);
    Logger.error(LogEvent.apiResponse);
    if (!kDebugMode) {
      expect(output, isEmpty);
      return;
    }
    expect(output.map(jsonDecode).toList(), [
      {'level': 'debug', 'event': 'apiRequest'},
      {'level': 'info', 'event': 'loginSuccess'},
      {'level': 'warning', 'event': 'configInvalid'},
      {'level': 'error', 'event': 'apiResponse'},
    ]);
  });

  test('all allowlisted events produce their fixed enum names', () {
    for (final event in LogEvent.values) {
      Logger.info(event);
    }
    expect(output.length, kDebugMode ? LogEvent.values.length : 0);
    if (kDebugMode) {
      expect(output.map((line) => (jsonDecode(line) as Map)['event']), [
        'apiRequest',
        'apiResponse',
        'loginSuccess',
        'storageWrite',
        'storageDelete',
        'storageRead',
        'configInvalid',
      ]);
    }
  });

  test('includes only bounded numeric HTTP status codes', () {
    for (final code in [100, 200, 401, 500, 599]) {
      Logger.info(LogEvent.apiResponse, statusCode: code);
    }
    if (!kDebugMode) {
      expect(output, isEmpty);
      return;
    }
    expect(output.map((line) => (jsonDecode(line) as Map)['statusCode']), [
      100,
      200,
      401,
      500,
      599,
    ]);
    for (final line in output) {
      expect((jsonDecode(line) as Map).keys, ['level', 'event', 'statusCode']);
    }
  });

  test('omits invalid numeric metadata for every log level', () {
    for (final code in [-1, 0, 99, 600, 123456789]) {
      Logger.debug(LogEvent.apiRequest, statusCode: code);
      Logger.info(LogEvent.storageWrite, statusCode: code);
      Logger.warning(LogEvent.storageDelete, statusCode: code);
      Logger.error(LogEvent.storageRead, statusCode: code);
    }
    expect(output.length, kDebugMode ? 20 : 0);
    for (final line in output) {
      expect((jsonDecode(line) as Map).keys, ['level', 'event']);
      expect(line, isNot(contains('123456789')));
    }
  });

  test(
    'arbitrary sensitive events and string metadata cannot reach output',
    () {
      final dynamic log = Logger.info;
      for (final secret in [
        'Bearer secret-token',
        'password=Abcdef1!',
        'person@example.test',
        'https://example.test?token=secret',
        'storage-key',
        '{"level":"error"}\nforged-event',
      ]) {
        expect(() => log(secret), throwsA(isA<TypeError>()));
        expect(
          () => log(LogEvent.apiResponse, statusCode: secret),
          throwsA(isA<TypeError>()),
        );
        expect(output, isEmpty);
      }
    },
  );
}
