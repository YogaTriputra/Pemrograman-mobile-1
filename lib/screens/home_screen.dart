import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/secure_storage_service.dart';
import '../utils/validators.dart';
import '../widgets/validation_card.dart';
import 'login_screen.dart';
import 'post_list_screen.dart';
import 'user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = SecureStorageService();
  final _tokenController = TextEditingController();
  final _pinController = TextEditingController();
  bool _hasToken = false;
  bool _hasPin = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _readStatus() async {
    final hasToken = await _storageService.hasToken();
    final token = await _storageService.getToken();
    final pin = await _storageService.getPin();
    if (!mounted) return;
    setState(() {
      _hasToken = hasToken && token != null && token.isNotEmpty;
      _hasPin = pin != null && pin.isNotEmpty;
    });
  }

  Future<void> _checkStorage() async {
    try {
      await _readStatus();
    } catch (_) {
      _message('Gagal membaca secure storage. Coba periksa kembali.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runStorage(
    Future<void> Function() operation,
    String success,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await operation();
      await _readStatus();
      _message(success);
    } catch (_) {
      _message('Operasi secure storage gagal. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    final error = Validators.validateText(
      token,
      fieldName: 'Token',
      maxLength: 4096,
    );
    if (error != null) {
      _message(error);
      return;
    }
    await _runStorage(() async {
      await _storageService.saveToken(token);
      _tokenController.clear();
    }, 'Token berhasil disimpan di secure storage');
  }

  Future<void> _savePin() async {
    final pin = _pinController.text;
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      _message('PIN harus terdiri dari 4–6 angka');
      return;
    }
    await _runStorage(() async {
      await _storageService.savePin(pin);
      _pinController.clear();
    }, 'PIN berhasil disimpan');
  }

  Future<void> _openLogin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    setState(() => _busy = true);
    await _checkStorage();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Hapus token dan keluar dari sesi simulasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    bool deleted = false;
    await _runStorage(() async {
      await _storageService.deleteToken();
      deleted = true;
    }, 'Logout berhasil');
    if (deleted && mounted) await _openLogin();
  }

  Widget _section(IconData icon, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
      appBar: AppBar(title: const Text('RPL & Keamanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_busy) const LinearProgressIndicator(),
            _section(Icons.lock, 'Secure Storage', [
              const Text(
                'Simpan token atau PIN di penyimpanan terenkripsi. Nilainya tidak ditampilkan atau dicetak ke log.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                enabled: !_busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Token',
                  hintText: 'Masukkan token dummy',
                  prefixIcon: Icon(Icons.vpn_key),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _saveToken,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_busy && _hasToken
                          ? () => _runStorage(
                              _storageService.deleteToken,
                              'Token berhasil dihapus',
                            )
                          : null,
                      icon: const Icon(Icons.delete),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _hasToken ? Icons.check_circle : Icons.cancel,
                  color: _hasToken ? Colors.green : Colors.red,
                ),
                title: Text(
                  _hasToken
                      ? 'Token tersimpan: ••••••••'
                      : 'Belum ada token tersimpan',
                ),
              ),
              const Divider(),
              TextField(
                controller: _pinController,
                enabled: !_busy,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'PIN (4–6 angka)',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _savePin,
                icon: const Icon(Icons.save),
                label: const Text('Simpan PIN'),
              ),
              Text(
                _hasPin ? 'PIN tersimpan: ••••••' : 'Belum ada PIN tersimpan',
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _runStorage(
                        _storageService.deleteAll,
                        'Semua data berhasil dihapus',
                      ),
                child: const Text('Hapus semua data aman'),
              ),
            ]),
            const SizedBox(height: 16),
            _section(Icons.person, 'Status Login', [
              Text(
                _hasToken
                    ? 'Sudah login (simulasi berbasis keberadaan token)'
                    : 'Belum login',
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : (_hasToken ? _logout : _openLogin),
                icon: Icon(_hasToken ? Icons.logout : Icons.login),
                label: Text(_hasToken ? 'Logout' : 'Login'),
              ),
            ]),
            const SizedBox(height: 16),
            _section(Icons.cloud, 'HTTP Request', [
              const Text(
                'Ambil data dari REST API JSONPlaceholder menggunakan GET melalui HTTPS.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserListScreen()),
                ),
                icon: const Icon(Icons.people),
                label: const Text('Lihat Daftar Pengguna'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostListScreen()),
                ),
                icon: const Icon(Icons.article),
                label: const Text('Lihat Daftar Posts'),
              ),
            ]),
            const SizedBox(height: 16),
            const ValidationCard(),
            const SizedBox(height: 16),
            _section(Icons.security, 'Catatan Keamanan', [
              const Text(
                '1. Token dan PIN disimpan terenkripsi di secure storage.\n2. Jangan mencetak token, PIN, password, atau email ke log.\n3. Gunakan HTTPS untuk komunikasi API.\n4. Tangani error dengan pesan yang ramah pengguna.\n5. Login di aplikasi ini hanya simulasi, bukan autentikasi nyata.',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
