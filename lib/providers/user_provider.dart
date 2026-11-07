import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends InheritedWidget {
  final User user;
  final Future<void> Function(User) updateUser;
  final Future<void> Function() logout;
  final bool isLoading;
  final bool isDarkMode;
  final int visitCount;
  final List<String> favorites;
  final Future<void> Function() toggleTheme;
  final Future<void> Function(String) addFavorite;
  final Future<void> Function(String) removeFavorite;

  const UserProvider({
    super.key,
    required this.user,
    required this.updateUser,
    required this.logout,
    required this.isLoading,
    required this.isDarkMode,
    required this.visitCount,
    required this.favorites,
    required this.toggleTheme,
    required this.addFavorite,
    required this.removeFavorite,
    required super.child,
  });

  static UserProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<UserProvider>();
    assert(provider != null, 'UserProvider tidak ditemukan di context');
    return provider!;
  }

  @override
  bool updateShouldNotify(UserProvider oldWidget) {
    return oldWidget.user != user ||
        oldWidget.isLoading != isLoading ||
        oldWidget.isDarkMode != isDarkMode ||
        oldWidget.visitCount != visitCount ||
        oldWidget.favorites != favorites;
  }
}

class UserProviderWrapper extends StatefulWidget {
  final Widget child;

  const UserProviderWrapper({super.key, required this.child});

  @override
  State<UserProviderWrapper> createState() => _UserProviderWrapperState();
}

class _UserProviderWrapperState extends State<UserProviderWrapper> {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;
  int _visitCount = 0;
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    final visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    final favorites = prefs.getStringList('favorites') ?? [];
    await prefs.setInt('visit_count', visitCount);
    if (!mounted) return;
    setState(() {
      _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
      _isDarkMode = isDarkMode;
      _visitCount = visitCount;
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _updateUser(User newUser) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newUser.name);
      await prefs.setString('user_email', newUser.email);
      await prefs.setBool('is_logged_in', newUser.isLoggedIn);
      final emails = prefs.getStringList('registered_emails') ?? [];
      if (!emails.contains(newUser.email)) {
        await prefs.setStringList('registered_emails', [
          ...emails,
          newUser.email,
        ]);
      }
      if (!mounted) return;
      setState(() {
        _user = newUser;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    if (!mounted) return;
    setState(() {
      _user = _user.copyWith(name: '', isLoggedIn: false);
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = !_isDarkMode;
    await prefs.setBool('is_dark_mode', value);
    if (!mounted) return;
    setState(() {
      _isDarkMode = value;
    });
  }

  Future<void> _addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty || _favorites.contains(value)) return;
    final favorites = [..._favorites, value];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites);
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
    });
  }

  Future<void> _removeFavorite(String item) async {
    final favorites = _favorites.where((value) => value != item).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites);
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserProvider(
      user: _user,
      updateUser: _updateUser,
      logout: _logout,
      isLoading: _isLoading,
      isDarkMode: _isDarkMode,
      visitCount: _visitCount,
      favorites: _favorites,
      toggleTheme: _toggleTheme,
      addFavorite: _addFavorite,
      removeFavorite: _removeFavorite,
      child: widget.child,
    );
  }
}
