import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_preferences/main.dart';
import 'package:state_preferences/models/user.dart';
import 'package:state_preferences/providers/user_change_notifier.dart';
import 'package:state_preferences/providers/user_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Model User sesuai modul', () {
    final user = User(name: 'Budi', email: 'budi@example.com');
    final copy = User.fromMap(user.toMap()).copyWith(isLoggedIn: true);
    expect(copy.name, 'Budi');
    expect(copy.email, user.email);
    expect(copy.isLoggedIn, isTrue);
  });

  for (final providerExercise in [false, true]) {
    testWidgets('Profil dan latihan dengan Provider: $providerExercise', (
      tester,
    ) async {
      Future<void> openApp() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          providerExercise
              ? const ProviderExerciseWrapper(child: PreferencesApp())
              : const MyApp(),
        );
        await tester.pumpAndSettle();
      }

      await openApp();
      expect(find.text('Selamat datang, Tamu!'), findsOneWidget);
      expect(find.text('Jumlah kunjungan: 1'), findsOneWidget);
      await tester.tap(find.byTooltip('Ubah Tema'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.tap(find.text('Login / Daftar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Budi');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'budi@example.com',
      );
      await tester.ensureVisible(find.text('Simpan Profil'));
      await tester.tap(find.text('Simpan Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Profil berhasil disimpan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField).last);
      await tester.enterText(find.byType(TextField).last, 'Membaca');
      await tester.ensureVisible(find.text('Tambah favorit'));
      await tester.tap(find.text('Tambah favorit'));
      await tester.pumpAndSettle();
      expect(find.text('Membaca'), findsOneWidget);
      await openApp();
      expect(find.text('Selamat datang, Budi!'), findsOneWidget);
      expect(find.text('Jumlah kunjungan: 2'), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.tap(find.text('Lihat Profil'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Membaca'));
      expect(find.text('Membaca'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus Membaca'));
      await tester.pumpAndSettle();
      expect(find.text('Membaca'), findsNothing);
      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Apakah Anda yakin ingin logout?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Selamat datang, Tamu!'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_email'), 'budi@example.com');
      expect(prefs.getString('user_name'), isNull);
      expect(prefs.getBool('is_logged_in'), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Validasi keamanan pada saveProfile', (tester) async {
    SharedPreferences.setMockInitialValues({
      'registered_emails': ['used@example.com'],
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login / Daftar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '<script>');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'used@example.com',
    );
    await tester.ensureVisible(find.text('Simpan Profil'));
    await tester.tap(find.text('Simpan Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nama mengandung karakter berbahaya.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Budi');
    await tester.tap(find.text('Simpan Profil'));
    await tester.pumpAndSettle();
    expect(
      find.text('Email sudah digunakan pada profil simulasi lain.'),
      findsOneWidget,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_name'), isNull);
  });

  test('updateShouldNotify memeriksa state', () {
    Future<void> action() async {}
    Future<void> itemAction(String value) async {}
    Future<void> update(User user) async {}
    final user = User(name: '', email: '');
    final favorites = <String>[];
    UserProvider scope(bool dark) => UserProvider(
      user: user,
      updateUser: update,
      logout: action,
      isLoading: false,
      isDarkMode: dark,
      visitCount: 1,
      favorites: favorites,
      toggleTheme: action,
      addFavorite: itemAction,
      removeFavorite: itemAction,
      child: const SizedBox(),
    );
    expect(scope(false).updateShouldNotify(scope(false)), isFalse);
    expect(scope(true).updateShouldNotify(scope(false)), isTrue);
  });
}
