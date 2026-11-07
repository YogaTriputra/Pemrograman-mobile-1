import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_http/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secure_http/models/user.dart';
import 'package:secure_http/services/api_service.dart';

void main() {
  const baseUrl = 'https://api.example.test';
  const apiKey = 'dummy-test-key';
  final user = <String, dynamic>{
    'id': 1,
    'name': ' Budi Santoso ',
    'username': 'budi',
    'email': 'budi@example.test',
    'phone': '123',
    'website': 'example.test',
    'company': {'name': 'Perusahaan'},
  };

  ApiService service(http.Response Function(http.Request) handler) {
    final client = MockClient((request) async => handler(request));
    final api = ApiService(client: client, baseUrl: baseUrl, apiKey: apiKey);
    addTearDown(() {
      api.close();
      client.close();
    });
    return api;
  }

  Matcher message(String value) =>
      isA<HttpException>().having((error) => error.message, 'message', value);

  test('configuration is empty before dotenv initialization', () {
    expect(AppConfig.baseUrl, isEmpty);
    expect(AppConfig.apiKey, isEmpty);
    expect(AppConfig.isConfigured, isFalse);
    expect(AppConfig.timeoutSeconds, 10);
  });

  test('configuration reads dotenv and defaults are used', () async {
    dotenv.testLoad(fileInput: 'BASE_URL=$baseUrl\nAPI_KEY=$apiKey');
    addTearDown(dotenv.clean);
    expect(AppConfig.baseUrl, baseUrl);
    expect(AppConfig.apiKey, apiKey);
    expect(AppConfig.isConfigured, isTrue);
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/users');
      expect(request.headers['X-API-Key'], apiKey);
      return http.Response('[]', 200);
    });
    final api = ApiService(client: client);
    addTearDown(api.close);
    addTearDown(client.close);
    expect(await api.getUsers(), isEmpty);
  });

  for (final invalidBase in [
    '',
    'http://api.example.test',
    '/relative',
    'https:',
    'https:///users',
    'https://user:secret@api.example.test',
    'https://@api.example.test',
    '$baseUrl?secret=value',
    '$baseUrl?',
    '$baseUrl#fragment',
    '$baseUrl#',
    '$baseUrl/invalid path',
    '$baseUrl/%0d%0a',
    '$baseUrl/%zz',
    'https://api.example.test:99999',
  ]) {
    test('rejects invalid base URL without a request: $invalidBase', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('[]', 200);
      });
      final api = ApiService(
        client: client,
        baseUrl: invalidBase,
        apiKey: apiKey,
      );
      addTearDown(api.close);
      addTearDown(client.close);
      expect(AppConfig.isValid(invalidBase, apiKey), isFalse);
      for (final request in [
        api.getUsers,
        () => api.getUserById(1),
        api.getPosts,
      ]) {
        await expectLater(
          request(),
          throwsA(message('Konfigurasi layanan tidak valid.')),
        );
      }
      expect(requests, 0);
    });
  }

  for (final invalidKey in [
    '',
    '   ',
    'key\rInjected: secret',
    'key\nsecret',
  ]) {
    test('rejects invalid key without a request', () async {
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('[]', 200);
      });
      final api = ApiService(
        client: client,
        baseUrl: baseUrl,
        apiKey: invalidKey,
      );
      addTearDown(api.close);
      addTearDown(client.close);
      expect(AppConfig.isValid(baseUrl, invalidKey), isFalse);
      await expectLater(
        api.getUsers(),
        throwsA(message('Konfigurasi layanan tidak valid.')),
      );
      expect(requests, 0);
    });
  }

  for (final path in ['/api/v1', '/api/v1/']) {
    test('preserves configured base path $path', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/api/v1/users');
        return http.Response('[]', 200);
      });
      final api = ApiService(
        client: client,
        baseUrl: '$baseUrl$path',
        apiKey: apiKey,
      );
      addTearDown(api.close);
      addTearDown(client.close);
      expect(await api.getUsers(), isEmpty);
    });
  }

  test('API logs contain only fixed events and status', () async {
    final logs = <String>[];
    final original = debugPrint;
    debugPrint = (String? value, {int? wrapWidth}) {
      if (value != null) logs.add(value);
    };
    addTearDown(() => debugPrint = original);
    final api = service((_) => http.Response('[]', 200));
    await api.getUsers();
    expect(logs.map(jsonDecode).toList(), [
      {'level': 'debug', 'event': 'apiRequest'},
      {'level': 'debug', 'event': 'apiResponse', 'statusCode': 200},
    ]);
  });

  test('users use HTTPS and parse all fields', () async {
    final api = service((request) {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.example.test');
      expect(request.url.path, '/users');
      expect(request.headers, {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': apiKey,
      });
      return http.Response(jsonEncode([user]), 200);
    });
    final users = await api.getUsers();
    expect(users, hasLength(1));
    expect(users.single.id, 1);
    expect(users.single.name, ' Budi Santoso ');
    expect(users.single.username, 'budi');
    expect(users.single.email, 'budi@example.test');
    expect(users.single.phone, '123');
    expect(users.single.website, 'example.test');
    expect(users.single.companyName, 'Perusahaan');
    expect(users.single.initial, 'B');
    expect(User.fromJson({...user, 'name': '  '}).initial, '?');
  });

  test('user detail uses id endpoint', () async {
    final api = service((request) {
      expect(request.url.path, '/users/1');
      return http.Response(jsonEncode(user), 200);
    });
    expect((await api.getUserById(1)).id, 1);
    expect(() => api.getUserById(0), throwsA(isA<HttpException>()));
  });

  test('posts parse all fields', () async {
    final api = service((request) {
      expect(request.url.path, '/posts');
      return http.Response(
        jsonEncode([
          {'userId': 1, 'id': 2, 'title': 'Judul', 'body': 'Isi'},
        ]),
        200,
      );
    });
    final post = (await api.getPosts()).single;
    expect(post.userId, 1);
    expect(post.id, 2);
    expect(post.title, 'Judul');
    expect(post.body, 'Isi');
  });

  for (final entry in {
    400: 'Permintaan tidak dapat diproses.',
    401: 'Akses tidak diizinkan.',
    403: 'Akses tidak diizinkan.',
    404: 'Data tidak ditemukan.',
    429: 'Terlalu banyak permintaan. Coba lagi nanti.',
    500: 'Server bermasalah. Silakan coba lagi nanti.',
  }.entries) {
    test('status ${entry.key} has a safe message', () async {
      final api = service((_) => http.Response('private response', entry.key));
      await expectLater(api.getUsers(), throwsA(message(entry.value)));
    });
  }

  for (final body in [
    '{',
    '{}',
    'null',
    '[null]',
    '[1]',
    '[{}]',
    jsonEncode([
      {...user, 'id': '1'},
    ]),
    jsonEncode([
      {...user, 'company': null},
    ]),
    jsonEncode([
      {...user, 'email': 4},
    ]),
  ]) {
    test('rejects malformed users: $body', () async {
      final api = service((_) => http.Response(body, 200));
      await expectLater(
        api.getUsers(),
        throwsA(message('Data dari server tidak valid.')),
      );
    });
  }

  test('rejects malformed detail and posts', () async {
    final api = service((_) => http.Response('{}', 200));
    await expectLater(api.getUserById(1), throwsA(isA<HttpException>()));
    await expectLater(api.getPosts(), throwsA(isA<HttpException>()));
    final invalidPost = service(
      (_) => http.Response('[{"userId":1,"id":2,"title":3,"body":"Isi"}]', 200),
    );
    await expectLater(invalidPost.getPosts(), throwsA(isA<HttpException>()));
  });

  test('timeout has a friendly message', () async {
    final pending = Completer<http.Response>();
    final client = MockClient((_) => pending.future);
    final api = ApiService(client: client, baseUrl: baseUrl, apiKey: apiKey);
    addTearDown(() {
      api.close();
      client.close();
    });
    await expectLater(
      api.getUsers(timeout: const Duration(milliseconds: 1)),
      throwsA(message('Permintaan terlalu lama. Silakan coba lagi.')),
    );
    pending.complete(http.Response('[]', 200));
  });

  test('network errors do not expose exception details', () async {
    final api = service((_) => throw http.ClientException('private details'));
    await expectLater(
      api.getUsers(),
      throwsA(message('Tidak dapat terhubung. Periksa koneksi internet.')),
    );
    expect(const HttpException('Pesan').toString(), 'Pesan');
  });

  testWidgets('login is simulated for one second without a request', (
    tester,
  ) async {
    final api = service((_) => throw StateError('Unexpected request'));
    String? token;
    final login = api.login('budi@example.test', 'Password1!').then((value) {
      token = value;
    });
    await tester.pump(const Duration(milliseconds: 999));
    expect(token, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    await login;
    expect(token, 'dummy_token');
  });

  test('login validates credentials', () async {
    final api = service((_) => throw StateError('Unexpected request'));
    for (final credentials in [
      ['', 'password'],
      ['invalid', 'password'],
      ['budi@example.test', ''],
      ['budi@example.test', '   '],
      ['budi@example.test', 'Aa1!'],
      ['budi@example.test', 'password1!'],
      ['budi@example.test', 'Password!'],
      ['budi@example.test', 'Password1'],
    ]) {
      await expectLater(
        api.login(credentials[0], credentials[1]),
        throwsA(message('Masukkan email dan kata sandi yang valid.')),
      );
    }
  });

  test('close is idempotent and leaves injected client usable', () async {
    final client = MockClient((_) async => http.Response('[]', 200));
    addTearDown(client.close);
    final api = ApiService(client: client, baseUrl: baseUrl, apiKey: apiKey);
    api.dispose();
    api.close();
    await expectLater(
      api.getUsers(),
      throwsA(message('Layanan sudah ditutup.')),
    );
    expect((await client.get(Uri.https('example.test'))).statusCode, 200);
    await expectLater(
      api.login('budi@example.test', 'Password1!'),
      throwsA(message('Layanan sudah ditutup.')),
    );
    ApiService().close();
  });
}
