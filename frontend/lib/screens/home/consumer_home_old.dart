import 'package:flutter/material.dart';
import 'package:quickserve/services/auth_service.dart';
import 'package:quickserve/services/socket_service.dart';
import '../../widgets/background_wrapper.dart';

class ConsumerHome extends StatefulWidget {
  const ConsumerHome({super.key});

  @override
  State<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends State<ConsumerHome> {
  @override
  void initState() {
    super.initState();
    // Subscribe to socket events
    final socket = SocketService();
    socket.connect(); // Important: ensure connection
    socket.on('order.created', (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ORDER PLACED — WAITING FOR VENDOR')),
        );
      }
    });
    socket.on('order.status.updated', (data) {
      final status = data['status'] ?? '';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Order update: $status')));
      }
    });
  }

  void _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('QuickServe - Explore'),
          backgroundColor: Colors.green.withOpacity(0.9),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Search box
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search for restaurants or dishes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSubmitted: (v) {},
          ),
          const SizedBox(height: 12),

          // Featured carousel
          SizedBox(
            height: 140,
            child: PageView(
              children: List.generate(
                3,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Featured ${i + 1}',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Categories
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategory('Promo', Icons.local_offer),
                _buildCategory('Pizza', Icons.local_pizza),
                _buildCategory('Sushi', Icons.rice_bowl),
                _buildCategory('Burgers', Icons.fastfood),
                _buildCategory('Dessert', Icons.icecream),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Food court / restaurants
          const Text(
            'Popular near you',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(5, (i) => _buildRestaurantTile(context, i)),
        ],
      ),
    ),
    );
  }

  Widget _buildCategory(String title, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.green.shade700),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRestaurantTile(BuildContext context, int index) {
    final name = 'Food Court ${index + 1}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Container(width: 64, color: Colors.grey.shade300),
        title: Text(name),
        subtitle: const Text('Open • 25-35 min • 4.5 ★'),
        trailing: ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).pushNamed('/place-order', arguments: {'name': name}),
          child: const Text('Order'),
        ),
      ),
    );
  }
}
