import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bind vendor profile from API
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: const [
          ListTile(title: Text('Vendor Name'), subtitle: Text('Your Business')),
          ListTile(title: Text('Email'), subtitle: Text('vendor@example.com')),
          ListTile(title: Text('Phone'), subtitle: Text('+234 000 000 0000')),
        ],
      ),
    );
  }
}
