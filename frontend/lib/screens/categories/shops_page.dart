import 'package:flutter/material.dart';
import '../vendor/vendor_detail_page.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  final List<String> _categories = [
    'All',
    'Supermarkets',
    'Mini Marts',
    'Delis',
    'Kiosks',
  ];
  final int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _subCategories = [
    {'name': 'Bakery', 'icon': '🥖', 'color': Color(0xFFFF9800)},
    {'name': 'Cleaning', 'icon': '🧽', 'color': Color(0xFF2196F3)},
    {'name': 'Fruits', 'icon': '🥬', 'color': Color(0xFF4CAF50)},
    {'name': 'Frozen Food', 'icon': '🧊', 'color': Color(0xFF00BCD4)},
  ];

  final List<Map<String, dynamic>> _shops = [
    {
      'name': 'Naija Liquors - Ikeja',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
      'rating': 4.7,
      'reviews': 7,
      'minPrice': 600,
      'deliveryTime': '12 - 22 min',
      'hasOffer': true,
      'offerText': 'Buy A Jameson, Get 2 Free Cokes',
    },
    {
      'name': 'Shoprite - Ikeja City Mall',
      'image':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
      'rating': 4.5,
      'reviews': 89,
      'minPrice': 500,
      'deliveryTime': '20 - 30 min',
      'hasOffer': false,
    },
    {
      'name': 'Ebeano Supermarket - Lekki',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=400',
      'rating': 4.6,
      'reviews': 134,
      'minPrice': 800,
      'deliveryTime': '25 - 35 min',
      'hasOffer': true,
      'offerText': '15% Off on First Order',
    },
    {
      'name': 'Game Stores - Victoria Island',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
      'rating': 4.4,
      'reviews': 67,
      'minPrice': 700,
      'deliveryTime': '18 - 28 min',
      'hasOffer': false,
    },
    {
      'name': 'Park n Shop - Maryland',
      'image':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
      'rating': 4.3,
      'reviews': 45,
      'minPrice': 600,
      'deliveryTime': '22 - 32 min',
      'hasOffer': true,
      'offerText': 'Free Delivery on Orders Above ₦2000',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Shops'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 20),
              const SizedBox(width: 4),
              const Text(
                'Lagos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _shops.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final shop = _shops[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                shop['image'] ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  width: 56,
                  height: 56,
                  child: const Icon(Icons.store),
                ),
              ),
            ),
            title: Text(shop['name'] ?? ''),
            subtitle: Text(
              'From ₦${shop['minPrice']} • ${shop['deliveryTime']}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VendorDetailPage(vendor: shop)),
            ),
          );
        },
      ),
    );
  }
}
