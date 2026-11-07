import 'package:flutter/widgets.dart';

import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';

class DependencyInjector {
  factory DependencyInjector() => _instance ??= DependencyInjector._();

  DependencyInjector._() : apiService = ApiService(), _ownsService = true {
    userRepository = UserRepositoryImpl(apiService: apiService);
    postRepository = PostRepositoryImpl(apiService: apiService);
  }

  DependencyInjector.withDependencies({
    required this.apiService,
    UserRepository? userRepository,
    PostRepository? postRepository,
  }) : _ownsService = false {
    this.userRepository =
        userRepository ?? UserRepositoryImpl(apiService: apiService);
    this.postRepository =
        postRepository ?? PostRepositoryImpl(apiService: apiService);
  }

  static DependencyInjector? _instance;
  final ApiService apiService;
  late final UserRepository userRepository;
  late final PostRepository postRepository;
  final bool _ownsService;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_ownsService) apiService.close();
    if (identical(_instance, this)) _instance = null;
  }
}

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required this.injector,
    required super.child,
  });

  final DependencyInjector injector;

  static DependencyInjector? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DependencyScope>()?.injector;

  static DependencyInjector of(BuildContext context) {
    final injector = maybeOf(context);
    if (injector == null) {
      throw StateError('DependencyScope tidak ditemukan.');
    }
    return injector;
  }

  @override
  bool updateShouldNotify(DependencyScope oldWidget) =>
      !identical(injector, oldWidget.injector);
}
