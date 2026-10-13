import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/widgets/social_media_row.dart';

void main() {
  testWidgets('SocialMediaRow displays icons and shows SnackBar when clicked',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SocialMediaRow(),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(3));
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.byIcon(Icons.work), findsOneWidget);
    expect(find.byIcon(Icons.code), findsOneWidget);

    // Tap Instagram icon
    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pump();
    expect(find.text('Instagram'), findsOneWidget);

    // Tap LinkedIn icon
    await tester.tap(find.byIcon(Icons.work));
    await tester.pump();
    expect(find.text('LinkedIn'), findsOneWidget);

    // Tap GitHub icon
    await tester.tap(find.byIcon(Icons.code));
    await tester.pump();
    expect(find.text('GitHub'), findsOneWidget);
  });
}
