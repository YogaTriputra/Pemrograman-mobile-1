import 'package:flutter/material.dart';
class InfoRow extends StatelessWidget {
final IconData icon;
final String label;
final Color? iconColor;
const InfoRow({
super.key,
required this.icon,
required this.label,
this.iconColor,
});
@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Row(
children: [
Icon(
icon,
color: iconColor ?? Colors.blue,
size: 24,
),
const SizedBox(width: 12),
Expanded(
child: Text(
label,
style: const TextStyle(fontSize: 16),
),
),
],
),
);
}
}