import '../models/user.dart';
import '../services/api_service.dart';

abstract class UserRepository {
  Future<List<User>> getUsers({Duration timeout = const Duration(seconds: 10)});

  Future<User> getUserById(int id);
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsService = apiService == null;

  final ApiService _apiService;
  final bool _ownsService;

  @override
  Future<List<User>> getUsers({
    Duration timeout = const Duration(seconds: 10),
  }) => _apiService.getUsers(timeout: timeout);

  @override
  Future<User> getUserById(int id) => _apiService.getUserById(id);

  void dispose() {
    if (_ownsService) _apiService.close();
  }
}
