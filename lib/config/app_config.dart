import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/validators.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl => _value('BASE_URL');
  static String get apiKey => _value('API_KEY');
  static const int timeoutSeconds = 10;

  static bool get isConfigured => isValid(baseUrl, apiKey);

  static bool isValid(String baseUrl, String apiKey) {
    if (Validators.validateUrl(baseUrl) != null ||
        apiKey.trim().isEmpty ||
        apiKey.contains('\r') ||
        apiKey.contains('\n')) {
      return false;
    }
    final uri = Uri.parse(baseUrl);
    return uri.isAbsolute &&
        uri.scheme == 'https' &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  static String _value(String name) =>
      dotenv.isInitialized ? dotenv.env[name] ?? '' : '';
}
