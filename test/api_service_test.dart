import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secure_http/models/post.dart';
import 'package:secure_http/models/user.dart';
import 'package:secure_http/services/api_service.dart';

void main() {
  const userJson = <String, dynamic>{
    'id': 1,
    'name': ' Alice Example ',
    'username': 'alice',
    'email': 'alice@example.com',
    'phone': '123456',
    'website': 'example.com',
    'company': {'name': 'Example Company'},
  };
  const postJson = <String, dynamic>{
    'userId': 1,
    'id': 2,
    'title': 'Example title',
    'body': 'Example body',
  };

  Matcher apiError(String message) => throwsA(
    isA<ApiException>().having((error) => error.message, 'message', message),
  );

  ApiService serviceWithBody(String body, {int status = 200}) {
    final service = ApiService(
      client: MockClient((_) async => http.Response(body, status)),
    );
    addTearDown(service.dispose);
    return service;
  }

  group('models', () {
    test('parses all user fields and initial', () {
      final user = User.fromJson(userJson);
      expect(user.id, 1);
      expect(user.name, ' Alice Example ');
      expect(user.username, 'alice');
      expect(user.email, 'alice@example.com');
      expect(user.phone, '123456');
      expect(user.website, 'example.com');
      expect(user.companyName, 'Example Company');
      expect(user.initial, 'A');
      expect(User.fromJson({...userJson, 'name': '  '}).initial, '?');
      expect(User.fromJson({...userJson, 'name': 'éva'}).initial, 'É');
    });

    test('parses all post fields', () {
      final post = Post.fromJson(postJson);
      expect(post.userId, 1);
      expect(post.id, 2);
      expect(post.title, 'Example title');
      expect(post.body, 'Example body');
    });
  });

  test('requests HTTPS endpoints and returns typed results', () async {
    final paths = <String>[];
    final service = ApiService(
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'jsonplaceholder.typicode.com');
        paths.add(request.url.path);
        final Object body = switch (request.url.path) {
          '/users' => [userJson],
          '/users/1' => userJson,
          '/posts' => [postJson],
          _ => throw StateError('Unexpected endpoint'),
        };
        return http.Response(jsonEncode(body), 200);
      }),
    );
    addTearDown(service.dispose);

    expect((await service.getUsers()).single.name, ' Alice Example ');
    expect((await service.getUserById(1)).companyName, 'Example Company');
    expect((await service.getPosts()).single.title, 'Example title');
    expect(paths, ['/users', '/users/1', '/posts']);
  });

  final requests = <String, Future<Object> Function(ApiService)>{
    'users': (service) => service.getUsers(),
    'user': (service) => service.getUserById(1),
    'posts': (service) => service.getPosts(),
  };

  for (final entry in requests.entries) {
    group(entry.key, () {
      for (final status in [201, 400, 401, 404, 500]) {
        test('rejects HTTP $status without exposing response', () async {
          final service = serviceWithBody(
            'private server details',
            status: status,
          );
          await expectLater(
            entry.value(service),
            apiError('Gagal mengambil data dari server.'),
          );
        });
      }

      for (final body in ['not JSON', '', 'null', '42', '"secret"', '[null]']) {
        test('rejects malformed JSON or schema: $body', () async {
          await expectLater(
            entry.value(serviceWithBody(body)),
            apiError('Format data dari server tidak valid.'),
          );
        });
      }

      test('handles client exceptions safely', () async {
        final service = ApiService(
          client: MockClient((_) async {
            throw http.ClientException('private connection details');
          }),
        );
        addTearDown(service.dispose);
        await expectLater(
          entry.value(service),
          apiError('Tidak dapat terhubung ke server.'),
        );
      });

      test('handles timeout exceptions safely', () async {
        final service = ApiService(
          client: MockClient((_) async {
            throw TimeoutException('private timeout details');
          }),
        );
        addTearDown(service.dispose);
        await expectLater(
          entry.value(service),
          apiError('Waktu permintaan habis. Silakan coba lagi.'),
        );
      });
    });
  }

  test('rejects missing and incorrectly typed user fields', () async {
    for (final key in userJson.keys) {
      for (final invalid in [
        {...userJson}..remove(key),
        {...userJson, key: null},
        {...userJson, key: false},
      ]) {
        for (final entry in [
          (jsonEncode([invalid]), false),
          (jsonEncode(invalid), true),
        ]) {
          final service = serviceWithBody(entry.$1);
          await expectLater(
            entry.$2 ? service.getUserById(1) : service.getUsers(),
            apiError('Format data dari server tidak valid.'),
          );
        }
      }
    }
    for (final company in [
      {},
      {'name': 3},
      {'name': null},
    ]) {
      await expectLater(
        serviceWithBody(
          jsonEncode([
            {...userJson, 'company': company},
          ]),
        ).getUsers(),
        apiError('Format data dari server tidak valid.'),
      );
    }
  });

  test('rejects missing and incorrectly typed post fields', () async {
    for (final key in postJson.keys) {
      for (final invalid in [
        {...postJson}..remove(key),
        {...postJson, key: null},
        {...postJson, key: false},
      ]) {
        await expectLater(
          serviceWithBody(jsonEncode([invalid])).getPosts(),
          apiError('Format data dari server tidak valid.'),
        );
      }
    }
  });

  test('rejects incorrect top-level shapes', () async {
    await expectLater(
      serviceWithBody(jsonEncode(userJson)).getUsers(),
      apiError('Format data dari server tidak valid.'),
    );
    await expectLater(
      serviceWithBody(jsonEncode([userJson])).getUserById(1),
      apiError('Format data dari server tidak valid.'),
    );
    await expectLater(
      serviceWithBody(jsonEncode(postJson)).getPosts(),
      apiError('Format data dari server tidak valid.'),
    );
  });

  test('accepts empty lists', () async {
    final service = serviceWithBody('[]');
    expect(await service.getUsers(), isEmpty);
    expect(await service.getPosts(), isEmpty);
  });

  test('honors custom getUsers timeout', () async {
    final response = Completer<http.Response>();
    final service = ApiService(client: MockClient((_) => response.future));
    addTearDown(service.dispose);
    await expectLater(
      service.getUsers(timeout: const Duration(milliseconds: 1)),
      apiError('Waktu permintaan habis. Silakan coba lagi.'),
    );
    response.complete(http.Response('[]', 200));
  });

  test('validates user IDs before making a request', () async {
    final service = ApiService(
      client: MockClient((_) async => fail('Unexpected request')),
    );
    addTearDown(service.dispose);
    for (final id in [0, -1]) {
      await expectLater(
        service.getUserById(id),
        apiError('ID pengguna tidak valid.'),
      );
    }
  });

  group('login', () {
    test('validates email and password without HTTP requests', () async {
      final service = ApiService(
        client: MockClient((_) async => fail('Unexpected request')),
      );
      addTearDown(service.dispose);
      for (final email in [
        '',
        'alice',
        'alice@',
        '@example.com',
        'a b@c.com',
      ]) {
        await expectLater(
          service.login(email, 'secret123'),
          apiError('Alamat email tidak valid.'),
        );
      }
      for (final password in ['', '12345', '      ']) {
        await expectLater(
          service.login('alice@example.com', password),
          apiError('Kata sandi minimal 6 karakter.'),
        );
      }
    });

    testWidgets('returns dummy token only after one second', (tester) async {
      final service = ApiService(
        client: MockClient((_) async => fail('Unexpected request')),
      );
      addTearDown(service.dispose);
      String? token;
      final login = service.login('alice@example.com', 'secret123').then((
        value,
      ) {
        token = value;
      });
      await tester.pump(const Duration(milliseconds: 999));
      expect(token, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      await login;
      expect(token, 'dummy-token');
    });
  });

  test('logs endpoints and statuses without payloads', () async {
    final originalDebugPrint = debugPrint;
    final logs = <String?>[];
    debugPrint = (String? message, {int? wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = originalDebugPrint);
    await serviceWithBody(jsonEncode([userJson])).getUsers();
    expect(logs, ['GET /users', 'GET /users 200']);
  });

  test('dispose is idempotent and prevents further operations', () async {
    final service = serviceWithBody('[]');
    service.dispose();
    service.dispose();
    for (final operation in <Future<Object> Function()>[
      () => service.getUsers(),
      () => service.getUserById(1),
      () => service.getPosts(),
      () => service.login('alice@example.com', 'secret123'),
    ]) {
      await expectLater(operation(), apiError('Layanan API sudah ditutup.'));
    }
  });
}
