import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickServe — Admin'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(child: Text('Welcome, admin!')),
    );
  }
}
