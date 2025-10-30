import 'package:flutter/material.dart';
import '../orders/order_page.dart';

class VendorDetailPage extends StatelessWidget {
  final Map<String, dynamic> vendor;
  const VendorDetailPage({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final name = vendor['name'] ?? 'Vendor';
    final image = vendor['image'] ?? '';
    final rating = vendor['rating'] ?? '-';
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          if (image.isNotEmpty)
            Image.network(
              image,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.store, size: 48),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text('$rating'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Short description about this vendor or shop. Menu and items are available below.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderPage(restaurant: vendor),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('View Menu & Order'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
