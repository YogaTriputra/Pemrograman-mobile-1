import '../models/post.dart';
import '../services/api_service.dart';

abstract class PostRepository {
  Future<List<Post>> getPosts();
}

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      _ownsService = apiService == null;

  final ApiService _apiService;
  final bool _ownsService;

  @override
  Future<List<Post>> getPosts() => _apiService.getPosts();

  void dispose() {
    if (_ownsService) _apiService.close();
  }
}
