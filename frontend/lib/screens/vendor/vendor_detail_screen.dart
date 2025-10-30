// lib/screens/vendors/vendor_detail_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/product_tile.dart';
import '../../widgets/cart_badge.dart';

class VendorDetailScreen extends StatefulWidget {
  const VendorDetailScreen({super.key});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  late Map<String, dynamic> vendor;
  late List<Map<String, dynamic>> menu;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is Map<String, dynamic>) {
      vendor = args;
      menu = List<Map<String, dynamic>>.from(vendor['menu'] ?? []);
    } else {
      vendor = {'name': 'Unknown', 'image': '', 'menu': []};
      menu = [];
    }
  }

  void _addToCart(Map<String, dynamic> item) {
    // use a scaffold messenger to show feedback
    // We can't import provider without changing main; we'll just show a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add to cart'),
        content: Text('Add "${item['name']}" (₦${item['price']}) to cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // For now show success — integrate provider in main.dart to actually add
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart (demo).')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vendor['name'] ?? 'Vendor'),
        actions: [
          // Cart badge is demo; wiring to provider is recommended
          CartBadge(
            count: 0,
            onTap: () => Navigator.pushNamed(context, '/checkout'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              vendor['image'],
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            vendor['name'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Rating: ${vendor['rating']} • ${vendor['eta']}'),
          const SizedBox(height: 12),
          const Text(
            'Menu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (menu.isEmpty) const Text('No items yet'),
          ...menu.map((m) {
            return ProductTile(
              id: m['id'],
              name: m['name'],
              price: m['price'],
              image: m['image'],
              onAdd: () => _addToCart(m),
            );
          }),
        ],
      ),
    );
  }
}
