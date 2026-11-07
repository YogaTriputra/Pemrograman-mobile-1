import 'package:flutter/material.dart';

import 'providers/user_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const UserProviderWrapper(child: PreferencesApp());
  }
}

class PreferencesApp extends StatelessWidget {
  const PreferencesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = UserProvider.of(context);
    return MaterialApp(
      title: 'State & Preferences',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
