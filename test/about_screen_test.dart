import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/screens/about_screen.dart';

void main() {
  testWidgets('AboutScreen displays background gradient, centered text, and back button in Stack',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
            child: const Text('Open About'),
          ),
        ),
      ),
    );

    // Open AboutScreen
    await tester.tap(find.text('Open About'));
    await tester.pumpAndSettle();

    // Verify Stack exists inside AboutScreen with Alignment.center
    final scaffoldWidget = tester.widget<Scaffold>(find.byType(Scaffold));
    final stackWidget = scaffoldWidget.body as Stack;
    expect(stackWidget.alignment, Alignment.center);

    // Verify text "Tentang Aplikasi"
    expect(find.text('Tentang Aplikasi'), findsOneWidget);

    // Verify Container with BoxDecoration and LinearGradient
    final containerFinder = find.byType(Container).first;
    final Container containerWidget = tester.widget(containerFinder);
    final BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
    expect(decoration.gradient, isA<LinearGradient>());

    // Verify Positioned widget exists with top and left defined
    final positionedFinder = find.byType(Positioned);
    expect(positionedFinder, findsOneWidget);
    final Positioned positionedWidget = tester.widget(positionedFinder);
    expect(positionedWidget.top, isNotNull);
    expect(positionedWidget.left, isNotNull);

    // Verify back button with label "Kembali"
    expect(find.text('Kembali'), findsOneWidget);

    // Tap back button and verify pop occurs
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    // Should return to previous screen
    expect(find.text('Open About'), findsOneWidget);
    expect(find.text('Tentang Aplikasi'), findsNothing);
  });
}
