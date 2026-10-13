import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info.dart';
import '../widgets/social_media_row.dart';
import '../widgets/action_buttons.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Mahasiswa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // a) Bagian foto profil dan informasi menggunakan Expanded
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    ProfileHeader(
                      name: 'Yoga Setia Triputra',
                      nim: '25.11.6394',
                    ),
                    SizedBox(height: 16),
                    ProfileInfo(
                      programStudi: 'S1 Informatika',
                      email: 'y.setia@students.amikom.ac.id',
                      lokasi: 'Yogyakarta, Indonesia',
                    ),
                    SizedBox(height: 16),
                    SocialMediaRow(),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // b) Tombol aksi di bagian bawah menggunakan Flexible
            SizedBox(height: 16),
            ActionButtons(),
          ],
        ),
      ),
    );
  }
}