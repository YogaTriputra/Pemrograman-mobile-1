import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_registrasi/main.dart';
import 'package:form_registrasi/utils/form_validators.dart';

void main() {
  group('Validasi input', () {
    test('Nama wajib diisi dan minimal tiga karakter', () {
      expect(FormValidators.name('  '), isNotNull);
      expect(FormValidators.name('Al'), isNotNull);
      expect(FormValidators.name('Alya'), isNull);
    });

    test('Email menolak format salah dan spasi di dalam alamat', () {
      for (final email in ['', 'alamat', 'a@b', 'a b@c.com', 'a@b.com@c']) {
        expect(FormValidators.email(email), isNotNull);
      }
      expect(FormValidators.email(' alya@example.com '), isNull);
    });

    test('Telepon hanya angka dengan panjang 10 sampai 13 digit', () {
      for (final phone in ['', '08123abc45', '123456789', '12345678901234']) {
        expect(FormValidators.phone(phone), isNotNull);
      }
      expect(FormValidators.phone('0812345678'), isNull);
      expect(FormValidators.phone('0812345678901'), isNull);
    });

    test('Password wajib, panjang, kapital, angka dan konfirmasi', () {
      expect(FormValidators.password(''), 'Password wajib diisi');
      expect(FormValidators.password('Abc12'), 'Password minimal 8 karakter');
      expect(
        FormValidators.password('abcdefgh1'),
        'Password harus mengandung huruf kapital',
      );
      expect(
        FormValidators.password('Abcdefgh'),
        'Password harus mengandung angka',
      );
      expect(FormValidators.password('Abcdefg1'), isNull);
      expect(FormValidators.confirmPassword('', 'Abcdefg1'), isNotNull);
      expect(FormValidators.confirmPassword('beda', 'Abcdefg1'), isNotNull);
      expect(FormValidators.confirmPassword('Abcdefg1', 'Abcdefg1'), isNull);
    });

    test('Kekuatan password sesuai kriteria', () {
      expect(FormValidators.passwordStrength(''), 0);
      expect(FormValidators.passwordStrength('Ab1!'), 1);
      expect(FormValidators.passwordStrength('abcdefgh'), 1);
      expect(FormValidators.passwordStrength('abcdefg1'), 2);
      expect(FormValidators.passwordStrength('Abcdefg1!'), 3);
    });
  });

  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
  }

  Future<void> fillValidForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Alya Mahasiswa');
    await tester.enterText(fields.at(1), 'alya@example.com');
    await tester.enterText(fields.at(2), '081234567890');
    await tester.tap(fields.at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perempuan').last);
    await tester.pumpAndSettle();
    await tester.enterText(fields.at(4), 'Password123!');
    await tester.enterText(fields.at(5), 'Password123!');
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
  }

  testWidgets('Submit kosong menampilkan semua error required', (tester) async {
    await openForm(tester);
    await tester.tap(find.text('Daftar'));
    await tester.pump();
    for (final message in [
      'Nama wajib diisi',
      'Email wajib diisi',
      'Nomor telepon wajib diisi',
      'Tanggal lahir wajib diisi',
      'Jenis kelamin wajib dipilih',
      'Password wajib diisi',
      'Konfirmasi password wajib diisi',
      'Anda wajib menyetujui syarat dan ketentuan',
    ]) {
      expect(find.text(message), findsOneWidget);
    }
  });

  testWidgets('Registrasi sukses, loading, dan reset seluruh form', (
    tester,
  ) async {
    await openForm(tester);
    await fillValidForm(tester);
    expect(find.text('Kekuatan password: Kuat'), findsOneWidget);
    await tester.tap(find.text('Daftar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Registrasi Berhasil'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    expect(find.text('Kekuatan password: Belum diisi'), findsOneWidget);
    expect(find.text('Perempuan'), findsNothing);
    expect(find.text('Nama wajib diisi'), findsNothing);
  });

  testWidgets('Konfirmasi divalidasi ulang saat password berubah', (
    tester,
  ) async {
    await openForm(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), 'Password123');
    await tester.enterText(fields.at(5), 'Password123');
    await tester.enterText(fields.at(4), 'Password456');
    await tester.pump();
    expect(find.text('Password tidak cocok'), findsOneWidget);
  });

  testWidgets('Aman jika halaman ditutup ketika registrasi berjalan', (
    tester,
  ) async {
    await openForm(tester);
    await fillValidForm(tester);
    await tester.tap(find.text('Daftar'));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
