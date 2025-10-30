import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../categories/pharmacy_page.dart';
import '../categories/shops_page.dart';
import '../orders/order_page.dart';
import '../location/location_selection_page.dart';
import '../vendor/vendor_detail_page.dart';

class ConsumerHome extends StatefulWidget {
  const ConsumerHome({super.key});

  @override
  State<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends State<ConsumerHome> {
  final PageController _promoController = PageController();
  final PageController _exploreController = PageController();
  final PageController _featuredController = PageController();
  int _currentPromoIndex = 0;
  int _currentExploreIndex = 0;
  int _currentFeaturedIndex = 0;
  String _selectedLocation = 'Lagos';

  Timer? _promoTimer;
  Timer? _exploreTimer;
  Timer? _featuredTimer;
  Timer? _orderTimer;
  String? _lastShownOrderId;
  String? _lastShownStatus;

  final List<Map<String, dynamic>> _promoOffers = [
    {
      'title': 'Get the Chow\nCombo now',
      'price': '₦2,200',
      'subtitle': 'Only',
      'image':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800',
      'color': Color(0xFFFFB366),
    },
    {
      'title': 'Special\nPizza Deal',
      'price': '₦3,500',
      'subtitle': 'From',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Burger\nCombo Meal',
      'price': '₦1,800',
      'subtitle': 'Only',
      'image':
          'https://images.unsplash.com/photo-1571091655789-405eb7a3a3a8?w=800',
      'color': Color(0xFFFF6B6B),
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Restaurants', 'icon': '🏪', 'color': Color(0xFF4CAF50)},
    {'title': 'Shops', 'icon': '🛍️', 'color': Color(0xFFFFB366)},
    {'title': 'Pharmacies', 'icon': '💊', 'color': Color(0xFF2196F3)},
    {'title': 'Send Packages', 'icon': '📦', 'color': Color(0xFF9C27B0)},
    {'title': 'Local Markets', 'icon': '🥬', 'color': Color(0xFF4CAF50)},
    {'title': 'More', 'icon': '➕', 'color': Color(0xFFFF9800)},
  ];

  final List<Map<String, dynamic>> _exploreVendors = [
    {
      'name': 'Iplus Pharmacy',
      'image':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=200',
    },
    {
      'name': 'HNH Restaurant',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200',
    },
    {
      'name': 'Gourmet Twist',
      'image':
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
    },
    {
      'name': 'Market Square',
      'image':
          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=200',
    },
    {
      'name': 'Bukka Hut',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200',
    },
    {
      'name': 'Chicken Republic',
      'image':
          'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=200',
    },
    {
      'name': 'Dominos Pizza',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=200',
    },
    {
      'name': 'Mr Biggs',
      'image':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=200',
    },
    {
      'name': 'Shoprite',
      'image':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200',
    },
    {
      'name': 'Cold Stone',
      'image':
          'https://images.unsplash.com/photo-1567206563064-6f60f40a2b57?w=200',
    },
    {
      'name': 'Tantalizers',
      'image':
          'https://images.unsplash.com/photo-1571091655789-405eb7a3a3a8?w=200',
    },
    {
      'name': 'HealthPlus',
      'image':
          'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=200',
    },
    {
      'name': 'Sweet Sensation',
      'image':
          'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=200',
    },
    {
      'name': 'Game Stores',
      'image':
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=200',
    },
    {
      'name': 'Ebeano Supermarket',
      'image':
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=200',
    },
  ];

  final List<Map<String, dynamic>> _foodCourts = [
    {
      'name': 'Victoria Island Food Court',
      'image':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=300',
      'rating': 4.2,
      'vendors': 12,
      'time': '15-25 min',
    },
    {
      'name': 'Ikeja City Mall Food Court',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
      'rating': 4.4,
      'vendors': 15,
      'time': '20-30 min',
    },
    {
      'name': 'Palms Shopping Mall Court',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300',
      'rating': 4.3,
      'vendors': 10,
      'time': '20-30 min',
    },
    {
      'name': 'Lekki Phase 1 Food Hub',
      'image':
          'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=300',
      'rating': 4.5,
      'vendors': 8,
      'time': '15-25 min',
    },
    {
      'name': 'Maryland Mall Food Court',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300',
      'rating': 4.1,
      'vendors': 11,
      'time': '25-35 min',
    },
    {
      'name': 'Surulere Food Plaza',
      'image':
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300',
      'rating': 4.0,
      'vendors': 9,
      'time': '20-30 min',
    },
    {
      'name': 'Ajah Food Court',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
      'rating': 4.2,
      'vendors': 7,
      'time': '30-40 min',
    },
    {
      'name': 'Yaba Food Hub',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300',
      'rating': 4.3,
      'vendors': 13,
      'time': '20-30 min',
    },
    {
      'name': 'Gbagada Express Food Court',
      'image':
          'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=300',
      'rating': 4.1,
      'vendors': 6,
      'time': '25-35 min',
    },
    {
      'name': 'Festac Food Plaza',
      'image':
          'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?w=300',
      'rating': 4.4,
      'vendors': 14,
      'time': '30-40 min',
    },
  ];

  // Featured restaurants to show in the featured carousel (limit to 5)
  final List<Map<String, dynamic>> _featuredRestaurants = [
    {
      'name': 'KFC - Nigerian Fried Chicken',
      'image':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
      'rating': 4.5,
      'time': '25-35 min',
      'category': 'Fast Food',
    },
    {
      'name': 'Nkoyo Restaurant',
      'image':
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      'rating': 4.5,
      'time': '30-40 min',
      'category': 'Nigerian',
    },
    {
      'name': 'Suya Palace',
      'image':
          'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=800',
      'rating': 4.7,
      'time': '10-20 min',
      'category': 'Nigerian',
    },
    {
      'name': 'Chopsticks Asian Cuisine',
      'image':
          'https://images.unsplash.com/photo-1563379091139-d5d7e6ec9c80?w=800',
      'rating': 4.3,
      'time': '30-40 min',
      'category': 'Asian',
    },
    {
      'name': 'Terra Kulture Restaurant',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      'rating': 4.6,
      'time': '45-55 min',
      'category': 'Nigerian',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startPromoAutoScroll();
    _startExploreAutoScroll();
    _startFeaturedAutoScroll();
    _startOrderWatcher();
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _exploreTimer?.cancel();
    _featuredTimer?.cancel();
    _orderTimer?.cancel();
    _promoController.dispose();
    _exploreController.dispose();
    _featuredController.dispose();
    super.dispose();
  }

  void _startPromoAutoScroll() {
    _promoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_promoController.hasClients) {
        setState(() {
          _currentPromoIndex = (_currentPromoIndex + 1) % _promoOffers.length;
        });

        // Special meal (index 0) should have 5 second delay
        if (_currentPromoIndex == 0) {
          timer.cancel();
          Timer(const Duration(seconds: 5), () {
            if (mounted) _startPromoAutoScroll();
          });
        }

        _promoController.animateToPage(
          _currentPromoIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startOrderWatcher() {
    _orderTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final data = await ApiClient().getJson('/api/orders/mine');
        final items = (data['items'] as List?) ?? [];
        if (items.isEmpty) return;
        final o = items.first as Map<String, dynamic>;
        final id = (o['_id'] ?? '').toString();
        final status = (o['status'] ?? '').toString();
        if (_lastShownOrderId == id && _lastShownStatus == status) return;
        _lastShownOrderId = id;
        _lastShownStatus = status;
        if (!mounted) return;
        final msg = _statusMessage(status);
        if (msg != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (_) {}
    });
  }

  String? _statusMessage(String status) {
    switch (status) {
      case 'pending':
      case 'placed':
        return 'Order is being placed, please wait to confirm your order.';
      case 'accepted':
        return 'Order received, wait while we complete your request.';
      case 'preparing':
      case 'waiting_pickup':
        return 'Order in queue/preparing.';
      case 'in_transit':
        return 'Order in transit.';
      case 'arrived_customer':
        return 'Rider arrives location — please scan the QR to confirm delivery.';
      case 'delivered':
        return 'Order delivery ✅';
    }
    return null;
  }

  void _startExploreAutoScroll() {
    _exploreTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_exploreController.hasClients) {
        setState(() {
          _currentExploreIndex =
              (_currentExploreIndex + 1) % _exploreVendors.length;
        });
        _exploreController.animateToPage(
          _currentExploreIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startFeaturedAutoScroll() {
    _featuredTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_featuredController.hasClients && _featuredRestaurants.isNotEmpty) {
        setState(() {
          _currentFeaturedIndex =
              (_currentFeaturedIndex + 1) % _featuredRestaurants.length;
        });
        _featuredController.animateToPage(
          _currentFeaturedIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _logout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with location and filter
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationSelectionPage(
                                  onLocationSelected: (loc) {
                                    setState(() {
                                      _selectedLocation = loc;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivering to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    _selectedLocation,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Filter',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  // Promotional carousel
                  Container(
                    height: 180,
                    margin: const EdgeInsets.all(16),
                    child: PageView.builder(
                      controller: _promoController,
                      onPageChanged: (index) {
                        setState(() => _currentPromoIndex = index);
                      },
                      itemCount: _promoOffers.length,
                      itemBuilder: (context, index) {
                        final offer = _promoOffers[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: offer['color'],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    offer['image'],
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                top: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offer['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.circle,
                                            color: Colors.orange,
                                            size: 8,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            offer['price'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            offer['subtitle'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Categories Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return GestureDetector(
                          onTap: () {
                            // Navigate to category
                            switch (category['title']) {
                              case 'Pharmacies':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PharmacyPage(),
                                  ),
                                );
                                break;
                              case 'Shops':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ShopsPage(),
                                  ),
                                );
                                break;
                              default:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${category['title']} coming soon!',
                                    ),
                                  ),
                                );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: category['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      category['icon'],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['title'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Explore Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 120,
                    child: PageView.builder(
                      controller: _exploreController,
                      itemCount: (_exploreVendors.length / 4).ceil(),
                      itemBuilder: (context, pageIndex) {
                        final startIndex = pageIndex * 4;
                        final endIndex = (startIndex + 4).clamp(
                          0,
                          _exploreVendors.length,
                        );
                        final pageVendors = _exploreVendors.sublist(
                          startIndex,
                          endIndex,
                        );

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: pageVendors.map((vendor) {
                            return SizedBox(
                              width: 80,
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        vendor['image'] ?? '',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.store,
                                                  size: 30,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vendor['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Featured Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Featured restaurant card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderPage(
                            restaurant:
                                _featuredRestaurants[0], // Using first featured restaurant
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.restaurant, size: 50),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'KFC - Nigerian Fried Chicken',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '4.5',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '25-35 min',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Food Courts Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'Food Courts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('🍽️', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Food Courts Grid (3 columns)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: _foodCourts.map((foodCourt) {
                        final cuisine = foodCourt['cuisine'] ?? 'Various';
                        final deliveryTime =
                            foodCourt['time'] ??
                            foodCourt['deliveryTime'] ??
                            'N/A';
                        final minPrice = foodCourt['minPrice'] ?? 500;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderPage(
                                  restaurant: {
                                    'name': foodCourt['name'],
                                    'image': foodCourt['image'],
                                  },
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    foodCourt['image'] ?? '',
                                    height: 80,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.restaurant,
                                                size: 28,
                                              ),
                                            ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        foodCourt['name'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cuisine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 12,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${foodCourt['rating'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            deliveryTime,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'From ₦$minPrice',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 140), // Bottom padding for navigation
                ], // end Column children
              ), // end Column
            ), // end SingleChildScrollView
          ], // end Stack children
        ), // end Stack
      ), // end SafeArea
    ); // end Scaffold
  }
}
