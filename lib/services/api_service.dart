import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../utils/logger.dart';
import '../utils/validators.dart';

class HttpException implements Exception {
  const HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl, String? apiKey})
    : _client = client ?? http.Client(),
      _ownsClient = client == null,
      _baseUrl = baseUrl ?? AppConfig.baseUrl,
      _apiKey = apiKey ?? AppConfig.apiKey;

  final http.Client _client;
  final bool _ownsClient;
  final String _baseUrl;
  final String _apiKey;
  bool _closed = false;

  Future<List<User>> getUsers({
    Duration timeout = const Duration(seconds: AppConfig.timeoutSeconds),
  }) => _get('/users', (data) {
    if (data is! List) {
      throw const FormatException();
    }
    return data.map((item) => User.fromJson(_object(item))).toList();
  }, timeout: timeout);

  Future<User> getUserById(int id) {
    if (id <= 0) {
      throw const HttpException('ID pengguna tidak valid.');
    }
    return _get('/users/$id', (data) => User.fromJson(_object(data)));
  }

  Future<List<Post>> getPosts() => _get('/posts', (data) {
    if (data is! List) {
      throw const FormatException();
    }
    return data.map((item) => Post.fromJson(_object(item))).toList();
  });

  Future<String> login(String email, String password) async {
    if (_closed) {
      throw const HttpException('Layanan sudah ditutup.');
    }
    if (Validators.validateEmail(email) != null ||
        Validators.validatePassword(password) != null) {
      throw const HttpException('Masukkan email dan kata sandi yang valid.');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    Logger.info(LogEvent.loginSuccess);
    return 'dummy_token';
  }

  Future<T> _get<T>(
    String endpoint,
    T Function(dynamic) parse, {
    Duration timeout = const Duration(seconds: AppConfig.timeoutSeconds),
  }) async {
    if (_closed) {
      throw const HttpException('Layanan sudah ditutup.');
    }
    if (!AppConfig.isValid(_baseUrl, _apiKey)) {
      Logger.warning(LogEvent.configInvalid);
      throw const HttpException('Konfigurasi layanan tidak valid.');
    }
    try {
      final base = Uri.parse(_baseUrl);
      final segments = [...base.pathSegments];
      while (segments.isNotEmpty && segments.last.isEmpty) {
        segments.removeLast();
      }
      final uri = base.replace(
        pathSegments: [
          ...segments,
          ...endpoint.split('/').where((s) => s.isNotEmpty),
        ],
      );
      Logger.debug(LogEvent.apiRequest);
      final response = await _client
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-API-Key': _apiKey,
            },
          )
          .timeout(timeout);
      Logger.debug(LogEvent.apiResponse, statusCode: response.statusCode);
      if (response.statusCode != 200) {
        throw HttpException(_statusMessage(response.statusCode));
      }
      return parse(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      throw const HttpException('Permintaan terlalu lama. Silakan coba lagi.');
    } on http.ClientException {
      throw const HttpException(
        'Tidak dapat terhubung. Periksa koneksi internet.',
      );
    } on HttpException {
      rethrow;
    } on FormatException {
      throw const HttpException('Data dari server tidak valid.');
    } on TypeError {
      throw const HttpException('Data dari server tidak valid.');
    } catch (_) {
      throw const HttpException('Permintaan gagal. Silakan coba lagi.');
    }
  }

  static Map<String, dynamic> _object(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException();
    }
    return value;
  }

  static String _statusMessage(int status) {
    if (status == 404) return 'Data tidak ditemukan.';
    if (status == 401 || status == 403) return 'Akses tidak diizinkan.';
    if (status == 429) return 'Terlalu banyak permintaan. Coba lagi nanti.';
    if (status >= 500) return 'Server bermasalah. Silakan coba lagi nanti.';
    return 'Permintaan tidak dapat diproses.';
  }

  void dispose() => close();

  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }
}
