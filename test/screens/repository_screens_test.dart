import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secure_http/config/dependency_injector.dart';
import 'package:secure_http/models/post.dart';
import 'package:secure_http/models/user.dart';
import 'package:secure_http/repositories/post_repository.dart';
import 'package:secure_http/repositories/user_repository.dart';
import 'package:secure_http/screens/post_list_screen.dart';
import 'package:secure_http/screens/user_list_screen.dart';
import 'package:secure_http/services/api_service.dart';

const alice = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.test',
  phone: '123',
  website: 'example.test',
  companyName: 'Company',
);
const post = Post(userId: 1, id: 2, title: 'Title', body: 'Body');

class FakeUsers implements UserRepository {
  Future<List<User>> Function() load = () async => [alice];
  final timeouts = <Duration>[];

  @override
  Future<List<User>> getUsers({
    Duration timeout = const Duration(seconds: 10),
  }) {
    timeouts.add(timeout);
    return load();
  }

  @override
  Future<User> getUserById(int id) async => alice;
}

class FakePosts implements PostRepository {
  Future<List<Post>> Function() load = () async => [post];
  int calls = 0;

  @override
  Future<List<Post>> getPosts() {
    calls++;
    return load();
  }
}

void main() {
  testWidgets('users loading, success, trimmed search, detail and refresh', (
    tester,
  ) async {
    final pending = Completer<List<User>>();
    final repository = FakeUsers()..load = () => pending.future;
    await tester.pumpWidget(
      MaterialApp(home: UserListScreen(repository: repository)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([alice]);
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Perusahaan: Company'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  ALICE  ');
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '<script>');
    await tester.pump();
    expect(find.text('Tidak ada hasil pencarian.'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump();
    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 detik').last);
    await tester.pumpAndSettle();
    repository.load = () async => [alice];
    await tester.tap(find.byTooltip('Muat ulang'));
    await tester.pumpAndSettle();
    expect(repository.timeouts.last, const Duration(seconds: 5));
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repository.timeouts.length, 3);
  });

  testWidgets('users arbitrary error is safe, retry and empty', (tester) async {
    final repository = FakeUsers()
      ..load = () async => throw StateError('secret-token');
    await tester.pumpWidget(
      MaterialApp(home: UserListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.text('Permintaan gagal. Silakan coba lagi.'), findsOneWidget);
    repository.load = () async => [];
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pengguna.'), findsOneWidget);
  });

  testWidgets('posts loading, success and refresh', (tester) async {
    final pending = Completer<List<Post>>();
    final repository = FakePosts()..load = () => pending.future;
    await tester.pumpWidget(
      MaterialApp(home: PostListScreen(repository: repository)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([post]);
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('userId: 1 · id: 2'), findsOneWidget);
    repository.load = () async => [post];
    await tester.tap(find.byTooltip('Muat ulang'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repository.calls, 3);
  });

  testWidgets('posts arbitrary error is safe, retry and empty', (tester) async {
    final repository = FakePosts()
      ..load = () async => throw StateError('secret-token');
    await tester.pumpWidget(
      MaterialApp(home: PostListScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.text('Permintaan gagal. Silakan coba lagi.'), findsOneWidget);
    repository.load = () async => [];
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada postingan.'), findsOneWidget);
  });

  for (final fail in [false, true]) {
    testWidgets('pending requests after unmount, failure: $fail', (
      tester,
    ) async {
      final users = Completer<List<User>>();
      final posts = Completer<List<Post>>();
      await tester.pumpWidget(
        MaterialApp(
          home: UserListScreen(
            repository: FakeUsers()..load = () => users.future,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PostListScreen(
            repository: FakePosts()..load = () => posts.future,
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      if (fail) {
        users.completeError(StateError('secret'));
        posts.completeError(StateError('secret'));
      } else {
        users.complete([alice]);
        posts.complete([post]);
      }
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scope injection has no network and survives screen disposal', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('[]', 200);
    });
    final service = ApiService(
      client: client,
      baseUrl: 'https://example.test',
      apiKey: 'dummy',
    );
    final users = FakeUsers();
    final posts = FakePosts();
    final injector = DependencyInjector.withDependencies(
      apiService: service,
      userRepository: users,
      postRepository: posts,
    );
    Widget scoped(Widget screen) => DependencyScope(
      injector: injector,
      child: MaterialApp(home: screen),
    );
    await tester.pumpWidget(scoped(const UserListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);
    expect(
      DependencyScope.of(tester.element(find.byType(UserListScreen))),
      same(injector),
    );
    await tester.pumpWidget(scoped(const PostListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);
    final override = FakeUsers()..load = () async => [];
    await tester.pumpWidget(scoped(UserListScreen(repository: override)));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pengguna.'), findsOneWidget);
    expect(users.timeouts.length, 1);
    await tester.pumpWidget(const SizedBox());
    expect(requests, 0);
    expect(await service.getPosts(), isEmpty);
    injector.dispose();
    expect(await service.getUsers(), isEmpty);
    service.dispose();
    client.close();
  });
}
