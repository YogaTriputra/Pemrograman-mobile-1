import 'package:flutter/material.dart';

import '../models/user.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, required this.onTap});

  final User user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(user.initial),
        ),
        title: Text(user.name),
        subtitle: Text('@${user.username}\n${user.email}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
