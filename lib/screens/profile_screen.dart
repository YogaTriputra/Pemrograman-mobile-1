import 'package:flutter/material.dart';
import '../widgets/profile_photo.dart';
import '../widgets/profile_info.dart';
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
body: SingleChildScrollView(
child: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
const SizedBox(height: 24),
const ProfilePhoto(radius: 60),
const SizedBox(height: 24),
const ProfileInfo(
name: 'Yoga Setia Triputra',
nim: '25.11.6394',
programStudi: 'S1 Informatika',
email: 'y.setia@students.amikom.ac.id',
lokasi: 'Yogyakarta, Indonesia',
),
const SizedBox(height: 24),
// Tombol aksi
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
ElevatedButton.icon(
onPressed: () {},
icon: const Icon(Icons.edit),
label: const Text('Edit'),
),
ElevatedButton.icon(
onPressed: () {},
icon: const Icon(Icons.share),
label: const Text('Bagikan'),
),
],
),
],
),
),
),
);
}
}