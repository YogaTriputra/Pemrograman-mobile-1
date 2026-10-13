import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/screens/profile_screen.dart';
import 'package:profil_mahasiswa/widgets/action_buttons.dart';
import 'package:profil_mahasiswa/widgets/profile_header.dart';
import 'package:profil_mahasiswa/widgets/profile_info.dart';
import 'package:profil_mahasiswa/widgets/social_media_row.dart';

void main() {
  testWidgets('ProfileScreen incorporates Expanded, Flexible, ProfileHeader, and ActionButtons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );

    // Verify Expanded is used for scrollable profile content
    final expandedFinder = find.ancestor(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Expanded),
    );
    expect(expandedFinder, findsOneWidget);

    // Verify ProfileHeader widget exists with photo, name, and NIM
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.text('Yoga Setia Triputra'), findsOneWidget);
    expect(find.text('NIM: 25.11.6394'), findsOneWidget);

    // Verify ProfileInfo and SocialMediaRow
    expect(find.byType(ProfileInfo), findsOneWidget);
    expect(find.byType(SocialMediaRow), findsOneWidget);

    // Verify ActionButtons widget exists
    expect(find.byType(ActionButtons), findsOneWidget);

    // Verify Flexible with flex: 1 is used for action buttons in ActionButtons Row
    final actionRow = tester.widget<Row>(
      find.descendant(
        of: find.byType(ActionButtons),
        matching: find.byType(Row),
      ).first,
    );
    final directFlexibles = actionRow.children.whereType<Flexible>().toList();
    expect(directFlexibles.length, 2);
    for (final flex in directFlexibles) {
      expect(flex.flex, 1);
    }

    // Verify action buttons exist
    expect(find.widgetWithText(ElevatedButton, 'Edit'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Bagikan'), findsOneWidget);
  });
}
