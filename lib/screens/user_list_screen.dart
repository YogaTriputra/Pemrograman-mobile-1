import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/user_card.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  List<User> _users = [];
  bool _loading = false;
  String? _error;
  int _timeoutSeconds = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
      final users = await _api.getUsers(
        timeout: Duration(seconds: _timeoutSeconds),
      );
      if (!mounted) return;
      setState(() => _users = users);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is ApiException
            ? error.message
            : 'Gagal memuat pengguna. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  void _showUser(User user) {
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
              Text(
                'Detail pengguna',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final field in <String, String>{
                'ID': '${user.id}',
                'Nama': user.name,
                'Username': user.username,
                'Email': user.email,
                'Telepon': user.phone,
                'Website': user.website,
                'Perusahaan': user.companyName,
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.key,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      SelectableText(field.value),
                    ],
                  ),
                ),
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

  Widget _buildList() {
    final query = _searchController.text.trim().toLowerCase();
    final users = _users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();

    if (!_loading && _error == null && users.isNotEmpty) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) =>
            UserCard(user: users[index], onTap: () => _showUser(users[index])),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          Text(
            _error ??
                (_users.isEmpty
                    ? 'Belum ada pengguna.'
                    : 'Tidak ada pengguna yang cocok dengan pencarian.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: Text(_error == null ? 'Muat ulang' : 'Coba lagi'),
            ),
          ),
        ],
      ],
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
          title: const Text('Daftar pengguna'),
          actions: [
            IconButton(
              tooltip: 'Muat ulang',
              onPressed: _loading ? null : _loadUsers,
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
                  decoration: const InputDecoration(
                    labelText: 'Cari nama atau email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: _buildList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
