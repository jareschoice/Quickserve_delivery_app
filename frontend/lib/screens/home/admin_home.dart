// lib/screens/home/admin_home.dart
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../auth/login_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quickserve — Admin'),
        actions: [
          IconButton(
            onPressed: () async {
              await ApiClient().clearAuth();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (r) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(child: Text('Admin Console — placeholder')),
    );
  }
}
