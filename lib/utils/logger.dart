import 'dart:convert';

import 'package:flutter/foundation.dart';

enum LogEvent {
  apiRequest,
  apiResponse,
  loginSuccess,
  storageWrite,
  storageDelete,
  storageRead,
  configInvalid,
}

class Logger {
  Logger._();

  static void debug(LogEvent event, {int? statusCode}) =>
      _log('debug', event, statusCode);

  static void info(LogEvent event, {int? statusCode}) =>
      _log('info', event, statusCode);

  static void warning(LogEvent event, {int? statusCode}) =>
      _log('warning', event, statusCode);

  static void error(LogEvent event, {int? statusCode}) =>
      _log('error', event, statusCode);

  static void _log(String level, LogEvent event, int? statusCode) {
    if (!kDebugMode) return;
    debugPrint(
      jsonEncode({
        'level': level,
        'event': event.name,
        if (statusCode != null && statusCode >= 100 && statusCode <= 599)
          'statusCode': statusCode,
      }),
    );
  }
}
