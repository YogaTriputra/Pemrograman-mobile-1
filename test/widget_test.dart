import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_http/main.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('Home menampilkan bagian modul dan menangani token pendek', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('RPL & Keamanan'), findsOneWidget);
    expect(find.text('Secure Storage'), findsOneWidget);
    expect(find.text('Belum ada token tersimpan'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'abc');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Token tersimpan: ••••••••'), findsOneWidget);
    expect(find.text('abc'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada token tersimpan'), findsOneWidget);
  });

  testWidgets('Token persisten terbaca tanpa ditampilkan', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'secret'});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Token tersimpan: ••••••••'), findsOneWidget);
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('Login simulasi dan konfirmasi logout', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Login'));
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'dummy@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'DummyPassword1!');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(
      find.text('Sudah login (simulasi berbasis keberadaan token)'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Logout'));
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Logout'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(
      find.text('Sudah login (simulasi berbasis keberadaan token)'),
      findsOneWidget,
    );
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Logout'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Simulasi Login'), findsOneWidget);
    expect(await const FlutterSecureStorage().read(key: 'auth_token'), isNull);
  });
}
