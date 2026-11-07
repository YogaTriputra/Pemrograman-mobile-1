import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secure_http/config/dependency_injector.dart';
import 'package:secure_http/repositories/post_repository.dart';
import 'package:secure_http/repositories/user_repository.dart';
import 'package:secure_http/services/api_service.dart';

class TrackingApiService extends ApiService {
  TrackingApiService()
    : super(baseUrl: 'https://example.test', apiKey: 'dummy');

  int closes = 0;

  @override
  void close() {
    closes++;
    super.close();
  }
}

void main() {
  final user = {
    'id': 1,
    'name': 'Alice',
    'username': 'alice',
    'email': 'alice@example.test',
    'phone': '123',
    'website': 'example.test',
    'company': {'name': 'Company'},
  };

  test('repositories forward endpoints and parse responses', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      expect(request.headers['X-API-Key'], 'dummy');
      final Object data;
      if (request.url.path == '/users') {
        data = [user];
      } else if (request.url.path == '/users/1') {
        data = user;
      } else {
        data = [
          {'userId': 1, 'id': 2, 'title': 'Title', 'body': 'Body'},
        ];
      }
      return http.Response(jsonEncode(data), 200);
    });
    final service = ApiService(
      client: client,
      baseUrl: 'https://example.test',
      apiKey: 'dummy',
    );
    final users = UserRepositoryImpl(apiService: service);
    final posts = PostRepositoryImpl(apiService: service);
    expect((await users.getUsers()).single.name, 'Alice');
    expect((await users.getUserById(1)).id, 1);
    expect((await posts.getPosts()).single.title, 'Title');
    expect(paths, ['/users', '/users/1', '/posts']);
    users.dispose();
    posts.dispose();
    expect((await users.getUsers()).length, 1);
    service.dispose();
    client.close();
  });

  test('user repository forwards timeout', () async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    final service = ApiService(
      client: client,
      baseUrl: 'https://example.test',
      apiKey: 'dummy',
    );
    await expectLater(
      UserRepositoryImpl(apiService: service)
          .getUsers(timeout: const Duration(milliseconds: 1)),
      throwsA(isA<HttpException>()),
    );
    response.complete(http.Response('[]', 200));
    service.dispose();
    client.close();
  });

  test('repositories preserve service errors', () async {
    final client = MockClient((_) async => http.Response('', 500));
    final service = ApiService(
      client: client,
      baseUrl: 'https://example.test',
      apiKey: 'dummy',
    );
    final users = UserRepositoryImpl(apiService: service);
    await expectLater(users.getUsers(), throwsA(isA<HttpException>()));
    await expectLater(users.getUserById(1), throwsA(isA<HttpException>()));
    await expectLater(
      PostRepositoryImpl(apiService: service).getPosts(),
      throwsA(isA<HttpException>()),
    );
    service.dispose();
    client.close();
  });

  test('injected resources remain caller owned', () {
    final service = TrackingApiService();
    final users = UserRepositoryImpl(apiService: service);
    final posts = PostRepositoryImpl(apiService: service);
    final injector = DependencyInjector.withDependencies(
      apiService: service,
      userRepository: users,
      postRepository: posts,
    );
    expect(injector.apiService, same(service));
    expect(injector.userRepository, same(users));
    expect(injector.postRepository, same(posts));
    users.dispose();
    posts.dispose();
    injector.dispose();
    injector.dispose();
    expect(service.closes, 0);
    service.dispose();
  });

  test('default injector is singleton with explicit lifetime', () async {
    final injector = DependencyInjector();
    expect(DependencyInjector(), same(injector));
    injector.dispose();
    injector.dispose();
    await expectLater(
      injector.userRepository.getUsers(),
      throwsA(isA<HttpException>()),
    );
    await expectLater(
      injector.postRepository.getPosts(),
      throwsA(isA<HttpException>()),
    );
    final replacement = DependencyInjector();
    expect(replacement, isNot(same(injector)));
    replacement.dispose();
  });
}
