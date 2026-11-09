import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_http/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Home menampilkan form penyimpanan token', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Secure HTTP'), findsOneWidget);
    expect(find.text('Token: belum tersimpan'), findsOneWidget);
    expect(find.text('Simpan token'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).obscureText,
      isTrue,
    );
  });

  testWidgets('Token pendek disimpan, dimuat ulang, dan dihapus dengan aman', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('Simpan token'));
    await tester.pumpAndSettle();
    expect(find.text('Token: •••••• (tersimpan)'), findsOneWidget);
    expect(find.text('abc'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Token: •••••• (tersimpan)'), findsOneWidget);
    await tester.tap(find.text('Hapus token'));
    await tester.pumpAndSettle();
    expect(find.text('Token: belum tersimpan'), findsOneWidget);
  });
}
