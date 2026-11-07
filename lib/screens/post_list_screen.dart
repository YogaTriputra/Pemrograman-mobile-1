import 'package:flutter/material.dart';

import '../models/post.dart';
import '../config/dependency_injector.dart';
import '../repositories/post_repository.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key, this.repository});

  final PostRepository? repository;

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late final PostRepository _repository;
  PostRepositoryImpl? _ownedRepository;
  List<Post> _posts = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        DependencyScope.maybeOf(context)?.postRepository ??
        (_ownedRepository = PostRepositoryImpl());
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _repository.getPosts();
      if (!mounted) return;
      setState(() => _posts = posts);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Permintaan gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ownedRepository?.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: _loadPosts,
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            )
          : _posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                Text('Belum ada postingan.', textAlign: TextAlign.center),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(post.body),
                        const SizedBox(height: 12),
                        Text(
                          'userId: ${post.userId} · id: ${post.id}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Theme.of(context).brightness,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daftar Postingan'),
          actions: [
            IconButton(
              onPressed: _loading ? null : _loadPosts,
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(child: _buildContent()),
      ),
    );
  }
}
