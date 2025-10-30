import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openConsumerApp() async {
    // Try app scheme first; fallback to website/store
    const scheme = 'quickserve://home';
    final uri = Uri.parse(scheme);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // TODO: replace with actual store link
      final web = Uri.parse('https://getquickserves.com');
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QuickVendor Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: const Text('Open Consumer App (QuickServe)')
              ,subtitle: const Text('Preview your storefront'),
              onTap: _openConsumerApp,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Add a product'),
              onTap: () => Navigator.of(context).pushNamed('/products/new'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('View incoming orders'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
