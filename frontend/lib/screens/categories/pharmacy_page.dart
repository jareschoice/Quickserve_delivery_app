import 'package:flutter/material.dart';
import '../vendor/vendor_detail_page.dart';

class PharmacyPage extends StatefulWidget {
  const PharmacyPage({super.key});

  @override
  State<PharmacyPage> createState() => _PharmacyPageState();
}

class _PharmacyPageState extends State<PharmacyPage> {
  final List<Map<String, dynamic>> _pharmacies = [
    {
      'name': 'Medplus Pharmacy - Oba Akinjobi',
      'image':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
      'rating': 4.9,
      'reviews': 42,
      'minPrice': 600,
      'deliveryTime': '14 - 24 min',
      'hasOffer': true,
      'offerText': 'ENJOY 20% OFF',
    },
    {
      'name': 'Medplus Pharmacy - Simbiat',
      'image':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
      'rating': 4.7,
      'reviews': 38,
      'minPrice': 600,
      'deliveryTime': '16 - 26 min',
      'hasOffer': true,
      'offerText': 'ENJOY 20% OFF',
    },
    {
      'name': 'HealthPlus Pharmacy - Ikeja',
      'image':
          'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400',
      'rating': 4.5,
      'reviews': 67,
      'minPrice': 500,
      'deliveryTime': '18 - 28 min',
      'hasOffer': false,
    },
    {
      'name': 'Alpha Pharmacy - Victoria Island',
      'image':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400',
      'rating': 4.8,
      'reviews': 55,
      'minPrice': 700,
      'deliveryTime': '12 - 22 min',
      'hasOffer': true,
      'offerText': 'Buy 2 Get 1 Free',
    },
    {
      'name': 'Orange Drugs - Lekki',
      'image':
          'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400',
      'rating': 4.3,
      'reviews': 29,
      'minPrice': 650,
      'deliveryTime': '20 - 30 min',
      'hasOffer': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pharmacies'),
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
        itemCount: _pharmacies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pharmacy = _pharmacies[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                pharmacy['image'] ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  width: 56,
                  height: 56,
                  child: const Icon(Icons.local_pharmacy),
                ),
              ),
            ),
            title: Text(pharmacy['name'] ?? ''),
            subtitle: Text(
              'From ₦${pharmacy['minPrice']} • ${pharmacy['deliveryTime']}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VendorDetailPage(vendor: pharmacy),
              ),
            ),
          );
        },
      ),
    );
  }
}
