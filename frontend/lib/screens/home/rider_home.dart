import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RiderHome extends StatelessWidget {
  const RiderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/auth');
            },
          )
        ],
      ),
      body: const Center(child: Text('Welcome, Rider!')),
    );
  }
}
