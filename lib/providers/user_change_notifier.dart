import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'user_provider.dart';

class UserChangeNotifier extends ChangeNotifier {
  User user = User(name: '', email: '');
  bool isLoading = true;
  bool isDarkMode = false;
  int visitCount = 0;
  List<String> favorites = [];

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    user = User(
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      isLoggedIn: prefs.getBool('is_logged_in') ?? false,
    );
    isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visitCount);
    favorites = prefs.getStringList('favorites') ?? [];
    isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(User newUser) async {
    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList('registered_emails') ?? [];
    if (emails.contains(newUser.email) &&
        prefs.getString('user_email') != newUser.email) {
      throw Exception('Email sudah digunakan');
    }
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);
    if (!emails.contains(newUser.email)) {
      await prefs.setStringList('registered_emails', [
        ...emails,
        newUser.email,
      ]);
    }
    user = newUser;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);
    user = user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', !isDarkMode);
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  Future<void> addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty || favorites.contains(value)) return;
    final updated = [...favorites, value];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);
    favorites = updated;
    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    final updated = favorites.where((value) => value != item).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updated);
    favorites = updated;
    notifyListeners();
  }
}

class ProviderExerciseWrapper extends StatelessWidget {
  final Widget child;

  const ProviderExerciseWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => UserChangeNotifier()..loadUser(),
    child: Consumer<UserChangeNotifier>(
      builder: (context, state, child) => UserProvider(
        user: state.user,
        updateUser: state.updateUser,
        logout: state.logout,
        isLoading: state.isLoading,
        isDarkMode: state.isDarkMode,
        visitCount: state.visitCount,
        favorites: state.favorites,
        toggleTheme: state.toggleTheme,
        addFavorite: state.addFavorite,
        removeFavorite: state.removeFavorite,
        child: child!,
      ),
      child: child,
    ),
  );
}
