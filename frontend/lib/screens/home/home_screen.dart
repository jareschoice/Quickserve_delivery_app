import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _promoController = PageController();
  int _currentPromoIndex = 0;
  Timer? _autoScrollTimer;

  final List<String> _promoImages = [
    'https://images.unsplash.com/photo-1551218808-94e220e084d2?w=800',
    'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=800',
    'https://images.unsplash.com/photo-1551782450-a2132b4ba21d?w=800',
  ];

  @override
  void initState() {
    super.initState();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_promoController.hasClients) {
        _currentPromoIndex = (_currentPromoIndex + 1) % _promoImages.length;
        _promoController.animateToPage(
          _currentPromoIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text('QuickServe'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildPromoCarousel(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildSectionTitle('Explore'),
          _buildHorizontalList(['Pizza Hub', 'Shawarma King', 'Amala Spot']),
          const SizedBox(height: 24),
          _buildSectionTitle('Featured'),
          _buildHorizontalList(['Local Dishes', 'Pastries', 'Smoothies']),
          const SizedBox(height: 24),
          _buildSectionTitle('Food Court'),
          _buildFoodCourt(),
          const SizedBox(height: 24),
          _buildSpecialMealCard(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _promoController,
        itemCount: _promoImages.length,
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(_promoImages[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.restaurant, 'label': 'Restaurants'},
      {'icon': Icons.store, 'label': 'Shops'},
      {'icon': Icons.local_pharmacy, 'label': 'Pharmacy'},
      {'icon': Icons.local_shipping, 'label': 'Send Package'},
      {'icon': Icons.shopping_basket, 'label': 'Local Market'},
      {'icon': Icons.more_horiz, 'label': 'More'},
    ];

    return GridView.count(
      crossAxisCount: 3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: actions.map((a) {
        return InkWell(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: Colors.green, size: 30),
                const SizedBox(height: 6),
                Text(a['label'] as String,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(onPressed: () {}, child: const Text('See all')),
      ],
    );
  }

  Widget _buildHorizontalList(List<String> items) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.network(
                      'https://source.unsplash.com/random/400x200?food,$index',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(items[index],
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodCourt() {
    final restaurants = List.generate(4, (i) => 'Food Court ${i + 1}');
    return Column(
      children: restaurants.map((r) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://source.unsplash.com/random/200x200?restaurant,$r',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(r),
            subtitle: const Text('Open • 25–35 min • 4.5 ★'),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Order'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialMealCard() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/special-meals'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Special Meals Plan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Subscribe to Basic, Standard, or Premium meal plans.'),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}