import 'package:flutter/material.dart';

class SocialMediaRow extends StatelessWidget {
  const SocialMediaRow({super.key});

  void _showSnackBar(BuildContext context, String socialMediaName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(socialMediaName),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.camera_alt),
          color: Colors.pink,
          tooltip: 'Instagram',
          onPressed: () => _showSnackBar(context, 'Instagram'),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.work),
          color: Colors.blue[700],
          tooltip: 'LinkedIn',
          onPressed: () => _showSnackBar(context, 'LinkedIn'),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.code),
          color: Colors.black87,
          tooltip: 'GitHub',
          onPressed: () => _showSnackBar(context, 'GitHub'),
        ),
      ],
    );
  }
}
