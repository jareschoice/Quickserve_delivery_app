import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, String>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AuthService().getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, String>>(
        future: _userFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snap.data ?? {'fullName': '', 'email': '', 'role': ''};
          final name = user['fullName'] ?? '';
          final email = user['email'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.green[100],
                      child: Text(
                        (name.isNotEmpty ? name[0] : 'U'),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'Guest User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty ? email : 'No email saved',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Account Settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Order History'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      await AuthService().logout();
                      if (mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/login', (r) => false);
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
