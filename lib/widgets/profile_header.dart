import 'package:flutter/material.dart';
import 'profile_photo.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String nim;
  final String? imageUrl;
  final double radius;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.nim,
    this.imageUrl,
    this.radius = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfilePhoto(
          imageUrl: imageUrl,
          radius: radius,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'NIM: $nim',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
