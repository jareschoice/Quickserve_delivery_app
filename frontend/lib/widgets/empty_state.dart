// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: Colors.grey.shade600)),
      ]),
    );
  }
}