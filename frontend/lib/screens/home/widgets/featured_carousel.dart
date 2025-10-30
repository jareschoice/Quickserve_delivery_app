import 'package:flutter/material.dart';

class FeaturedCarousel extends StatelessWidget {
  const FeaturedCarousel({super.key});

  final List<Map<String, String>> items = const [
    {
      "name": "Spicy Jollof",
      "image": "https://images.unsplash.com/photo-1600891964599-f61ba0e24092",
      "price": "₦2500",
    },
    {
      "name": "Grilled Chicken",
      "image": "https://images.unsplash.com/photo-1606755962773-0e49f55a3e7a",
      "price": "₦4500",
    },
    {
      "name": "Veggie Burger",
      "image": "https://images.unsplash.com/photo-1550547660-d9450f859349",
      "price": "₦3000",
    },
    {
      "name": "Fruit Smoothie",
      "image": "https://images.unsplash.com/photo-1542444459-db63f49ef4e7",
      "price": "₦1500",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) => _FeaturedCard(item: items[i]),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Map<String, String> item;

  const _FeaturedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              item['image']!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              item['price']!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
