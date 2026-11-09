import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/secure_storage_service.dart';
import 'login_screen.dart';
import 'post_list_screen.dart';
import 'user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = SecureStorageService();
  final _tokenController = TextEditingController();
  final _pinController = TextEditingController();
  bool _busy = false;
  bool _loaded = false;
  bool _hasToken = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _readStatus() async {
    final hasToken = await _storage.hasToken();
    final pin = await _storage.getPin();
    if (!mounted) return;
    setState(() {
      _hasToken = hasToken;
      _hasPin = pin != null && pin.isNotEmpty;
      _loaded = true;
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      _message('Gagal mengakses penyimpanan aman. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() => _run(_readStatus);

  Future<void> _saveToken() async {
    if (_busy || !mounted) return;
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _message('Masukkan token terlebih dahulu.');
      return;
    }
    await _run(() async {
      await _storage.saveToken(token);
      if (!mounted) return;
      _tokenController.clear();
      await _readStatus();
      _message('Token berhasil disimpan.');
    });
  }

  Future<void> _deleteToken() => _run(() async {
    await _storage.deleteToken();
    if (!mounted) return;
    _tokenController.clear();
    await _readStatus();
    _message('Token berhasil dihapus.');
  });

  Future<void> _savePin() async {
    if (_busy || !mounted) return;
    final pin = _pinController.text;
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      _message('PIN harus terdiri dari 4–6 digit.');
      return;
    }
    await _run(() async {
      await _storage.savePin(pin);
      if (!mounted) return;
      _pinController.clear();
      await _readStatus();
      _message('PIN berhasil disimpan.');
    });
  }

  Future<bool> _confirm(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, lanjutkan'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteAll() => _run(() async {
    if (!await _confirm(
      'Hapus semua data aman?',
      'Token dan PIN yang tersimpan akan dihapus.',
    )) {
      return;
    }
    if (!mounted) return;
    await _storage.deleteAll();
    if (!mounted) return;
    _tokenController.clear();
    _pinController.clear();
    await _readStatus();
    _message('Semua data aman berhasil dihapus.');
  });

  Future<void> _login() => _run(() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (mounted) await _readStatus();
  });

  Future<void> _logout() => _run(() async {
    if (!await _confirm('Logout?', 'Token tersimpan akan dihapus.')) return;
    if (!mounted) return;
    await _storage.deleteToken();
    if (!mounted) return;
    _tokenController.clear();
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  });

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure HTTP'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            tooltip: 'Perbarui status',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Modul publik: penyimpanan aman dan API'),
            if (_busy) const LinearProgressIndicator(),
            _section('Penyimpanan token', [
              Text(
                !_loaded
                    ? 'Status token: belum diketahui'
                    : _hasToken
                    ? 'Token: •••••• (tersimpan)'
                    : 'Token: belum tersimpan',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenController,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'Token'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _saveToken,
                child: const Text('Simpan token'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _deleteToken,
                child: const Text('Hapus token'),
              ),
            ]),
            _section('PIN tambahan', [
              Text(
                !_loaded
                    ? 'Status PIN: belum diketahui'
                    : _hasPin
                    ? 'PIN: •••••• (tersimpan)'
                    : 'PIN: belum tersimpan',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(labelText: 'PIN (4–6 digit)'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _savePin,
                child: const Text('Simpan PIN'),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _deleteAll,
                child: const Text('Hapus semua data aman'),
              ),
            ]),
            _section('Login simulasi', [
              Text(
                !_loaded
                    ? 'Status login: belum diketahui'
                    : _hasToken
                    ? 'Status login: token tersedia (simulasi)'
                    : 'Status login: belum login',
              ),
              const Text('Simulasi pembelajaran, bukan autentikasi nyata.'),
              FilledButton(
                onPressed: _busy ? null : _login,
                child: const Text('Buka login'),
              ),
              OutlinedButton(
                onPressed: _busy || !_hasToken ? null : _logout,
                child: const Text('Logout'),
              ),
            ]),
            _section('API melalui HTTPS', [
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const UserListScreen(),
                        ),
                      ),
                child: const Text('Daftar pengguna'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const PostListScreen(),
                        ),
                      ),
                child: const Text('Daftar postingan'),
              ),
            ]),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Token dan PIN disimpan dengan secure storage. '
                'Permintaan API menggunakan HTTPS. '
                'Rahasia tidak ditampilkan atau dicatat ke log.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
