import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/post.dart';
import '../models/user.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const _defaultTimeout = Duration(seconds: 10);

  final http.Client _client;
  bool _disposed = false;

  Future<List<User>> getUsers({Duration timeout = _defaultTimeout}) async {
    final data = await _get('/users', timeout: timeout);
    return _parse(() {
      if (data is! List) {
        throw const FormatException();
      }
      return data.map((item) => User.fromJson(_object(item))).toList();
    });
  }

  Future<User> getUserById(int id) async {
    _ensureActive();
    if (id <= 0) {
      throw const ApiException('ID pengguna tidak valid.');
    }
    final data = await _get('/users/$id');
    return _parse(() => User.fromJson(_object(data)));
  }

  Future<List<Post>> getPosts() async {
    final data = await _get('/posts');
    return _parse(() {
      if (data is! List) {
        throw const FormatException();
      }
      return data.map((item) => Post.fromJson(_object(item))).toList();
    });
  }

  Future<String> login(String email, String password) async {
    _ensureActive();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      throw const ApiException('Alamat email tidak valid.');
    }
    if (password.trim().length < 6) {
      throw const ApiException('Kata sandi minimal 6 karakter.');
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    _ensureActive();
    return 'dummy-token';
  }

  Future<dynamic> _get(
    String endpoint, {
    Duration timeout = _defaultTimeout,
  }) async {
    _ensureActive();
    try {
      if (kDebugMode) {
        debugPrint('GET $endpoint');
      }
      final response = await _client
          .get(Uri.parse('$_baseUrl$endpoint'))
          .timeout(timeout);
      if (kDebugMode) {
        debugPrint('GET $endpoint ${response.statusCode}');
      }
      if (response.statusCode != 200) {
        throw const ApiException('Gagal mengambil data dari server.');
      }
      return jsonDecode(response.body);
    } on TimeoutException {
      throw const ApiException('Waktu permintaan habis. Silakan coba lagi.');
    } on http.ClientException {
      throw const ApiException('Tidak dapat terhubung ke server.');
    } on FormatException {
      throw const ApiException('Format data dari server tidak valid.');
    }
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException();
    }
    return value;
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on FormatException {
      throw const ApiException('Format data dari server tidak valid.');
    }
  }

  void _ensureActive() {
    if (_disposed) {
      throw const ApiException('Layanan API sudah ditutup.');
    }
  }

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _client.close();
    }
  }
}
