import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _favoriteController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _favoriteBusy = false;
  bool _loggingOut = false;

  bool get _busy => _saving || _favoriteBusy || _loggingOut;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = UserProvider.of(context).user;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    final userProvider = UserProvider.of(context);
    if (_busy || userProvider.isLoading || !_formKey.currentState!.validate()) {
      return;
    }
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (RegExp(r'[<>\x00-\x1F]').hasMatch(_nameController.text)) {
      _message('Nama mengandung karakter berbahaya.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final currentEmail = prefs.getString('user_email')?.trim().toLowerCase();
      final registeredEmails = prefs.getStringList('registered_emails') ?? [];
      final normalizedEmail = email.toLowerCase();
      if (normalizedEmail != currentEmail &&
          registeredEmails.any(
            (registered) => registered.trim().toLowerCase() == normalizedEmail,
          )) {
        _message('Email sudah digunakan pada profil simulasi lain.');
        return;
      }
      final updatedUser = userProvider.user.copyWith(
        name: name,
        email: email,
        isLoggedIn: true,
      );
      await userProvider.updateUser(updatedUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _message('Gagal menyimpan profil: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeFavorite({String? remove}) async {
    final userProvider = UserProvider.of(context);
    if (_busy || userProvider.isLoading) return;
    final value = remove ?? _favoriteController.text.trim();
    if (value.isEmpty) {
      _message('Isi favorit terlebih dahulu.');
      return;
    }
    setState(() => _favoriteBusy = true);
    try {
      if (remove == null) {
        await userProvider.addFavorite(value);
      } else {
        await userProvider.removeFavorite(value);
      }
      if (!mounted) return;
      if (remove == null) _favoriteController.clear();
      _message(remove == null ? 'Favorit ditambahkan.' : 'Favorit dihapus.');
    } catch (error) {
      if (!mounted) return;
      _message('Gagal mengubah favorit: $error');
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _logout() async {
    final userProvider = UserProvider.of(context);
    if (_busy || userProvider.isLoading) return;
    setState(() => _loggingOut = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await userProvider.logout();
      if (!mounted) return;
      _message('Berhasil logout!');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      _message('Gagal logout: $error');
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = UserProvider.of(context);
    final disabled = userProvider.isLoading || _busy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (userProvider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: disabled ? null : _logout,
            ),
        ],
      ),
      body: userProvider.isLoading || _saving || _favoriteBusy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: disabled ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _favoriteController,
                      decoration: const InputDecoration(
                        labelText: 'Favorit baru',
                        prefixIcon: Icon(Icons.favorite),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _changeFavorite(),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _changeFavorite(),
                      child: const Text('Tambah favorit'),
                    ),
                    if (userProvider.favorites.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Belum ada favorit.'),
                      ),
                    for (final favorite in userProvider.favorites)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(favorite),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Hapus $favorite',
                          onPressed: () => _changeFavorite(remove: favorite),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.amber[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.amber[800]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Catatan Keamanan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Data disimpan di SharedPreferences (plaintext). '
                              'Jangan simpan password atau data sensitif di sini. '
                              'Gunakan secure storage untuk data sensitif.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
