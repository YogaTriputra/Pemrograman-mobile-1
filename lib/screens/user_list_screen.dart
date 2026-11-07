import 'package:flutter/material.dart';

import '../models/user.dart';
import '../config/dependency_injector.dart';
import '../repositories/user_repository.dart';
import '../widgets/user_card.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key, this.repository});

  final UserRepository? repository;

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late final UserRepository _repository;
  UserRepositoryImpl? _ownedRepository;
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  bool _loading = false;
  String? _error;
  int _timeoutSeconds = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _repository =
        widget.repository ??
        DependencyScope.maybeOf(context)?.userRepository ??
        (_ownedRepository = UserRepositoryImpl());
    _loadUsers();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUsers() async {
    if (!mounted || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await _repository.getUsers(
        timeout: Duration(seconds: _timeoutSeconds),
      );
      if (!mounted) return;
      setState(() => _users = users);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Permintaan gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetails(User user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text('Username: ${user.username}'),
              const SizedBox(height: 12),
              Text('Email: ${user.email}'),
              const SizedBox(height: 12),
              Text('Telepon: ${user.phone}'),
              const SizedBox(height: 12),
              Text('Website: ${user.website}'),
              const SizedBox(height: 12),
              Text('Perusahaan: ${user.companyName}'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _ownedRepository?.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: _error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: _loadUsers,
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            )
          : filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  _users.isEmpty
                      ? 'Belum ada pengguna.'
                      : 'Tidak ada hasil pencarian.',
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final user = filtered[index];
                return UserCard(user: user, onTap: () => _showDetails(user));
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
          title: const Text('Daftar Pengguna'),
          actions: [
            IconButton(
              onPressed: _loading ? null : _loadUsers,
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari nama atau email',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _searchController.clear,
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: DropdownButtonFormField<int>(
                  initialValue: _timeoutSeconds,
                  decoration: const InputDecoration(
                    labelText: 'Timeout',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final seconds in [1, 5, 10, 30])
                      DropdownMenuItem(
                        value: seconds,
                        child: Text('$seconds detik'),
                      ),
                  ],
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _timeoutSeconds = value);
                          }
                        },
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }
}
