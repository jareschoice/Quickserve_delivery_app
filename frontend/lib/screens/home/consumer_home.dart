import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/animated_clock_banner.dart';
import 'vendor_detail_screen.dart';
import '../orders/checkout_page.dart';
import 'discover_page.dart';

/// ConsumerHome - Mirrors event-frontend/home.html exactly
/// Structure: NavBar �� Hero with Stats & Promo �� Categories �� Popular Vendors �� Featured Deals �� Food Court
class ConsumerHome extends StatefulWidget {
  const ConsumerHome({super.key});

  @override
  State<ConsumerHome> createState() => _ConsumerHomeState();
}

class _ConsumerHomeState extends State<ConsumerHome> {
  String _currentLocation = 'Detecting...';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _products = [];
  int _cartCount = 0;
  int _promoIndex = 0;
  Timer? _promoTimer;
  final ScrollController _exploreScrollController = ScrollController();
  final ScrollController _featuredScrollController = ScrollController();
  Timer? _exploreAutoScrollTimer;
  Timer? _featuredAutoScrollTimer;
  bool _exploreAutoScrollPaused = false;
  bool _featuredAutoScrollPaused = false;
  String _userInitials = '';
  bool _isLoggedIn = false;
  String _backendBaseUrl = AppConfig.backendBaseUrl; // Will be updated on init

  // Categories matching event-frontend exactly (7 categories for 3x3 grid with package options)
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Restaurants',
      'image':
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=1200&q=80',
      'icon': Icons.restaurant,
      'description': 'Food & drinks',
    },
    {
      'title': 'Shops',
      'image':
          'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=80',
      'icon': Icons.store_mall_directory,
      'description': 'Groceries & more',
    },
    {
      'title': 'Pharmacies',
      'image':
          'https://images.unsplash.com/photo-1580281657521-6a865da3c291?w=1200&q=80',
      'icon': Icons.medical_services_outlined,
      'description': 'Health essentials',
    },
    {
      'title': 'Send Package',
      'image':
          'https://images.unsplash.com/photo-1523475472560-d2df97ec485c?w=1200&q=80',
      'icon': Icons.local_shipping,
      'description': 'Deliver items',
    },
    {
      'title': 'Request Pickup',
      'image':
          'https://images.unsplash.com/photo-1566576912321-d58ddd7a6088?w=1200&q=80',
      'icon': Icons.call_received,
      'description': 'Collect packages',
    },
    {
      'title': 'Local Markets',
      'image':
          'https://images.unsplash.com/photo-1523475472560-135a04b4c10b?w=1200&q=80',
      'icon': Icons.shopping_basket_outlined,
      'description': 'Fresh produce',
    },
    {
      'title': 'More',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
      'icon': Icons.grid_view,
      'description': 'Explore all',
    },
  ];

  final SocketService _socketService = SocketService();
  final CartService _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _initBackendUrl();
    _loadUserInfo();
    _loadData();
    _startPromoSlider();
    _detectLocation();
    _loadCartCount();
    _setupSocketListeners();
    _cartService.addListener(_onCartChanged);
  }

  Future<void> _loadUserInfo() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        final authService = AuthService();
        final user = await authService.getCurrentUser();
        final fullName = user['fullName'] ?? '';
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _userInitials = _getInitials(fullName);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _userInitials = '';
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load user info: $e');
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  Future<void> _initBackendUrl() async {
    try {
      final url = await ApiClient.getCurrentBackendUrl();
      if (mounted) {
        setState(() {
          _backendBaseUrl = url;
        });
      }
    } catch (e) {
      debugPrint('Failed to get backend URL: $e');
    }
  }

  @override
  void dispose() {
    _promoTimer?.cancel();
    _exploreAutoScrollTimer?.cancel();
    _featuredAutoScrollTimer?.cancel();
    _exploreScrollController.dispose();
    _featuredScrollController.dispose();
    _removeSocketListeners();
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {
        _cartCount = _cartService.itemCount;
      });
    }
  }

  void _setupSocketListeners() {
    // Ensure socket is connected
    _socketService.connect();

    // Listen for new vendors in real-time
    _socketService.on('vendor:created', (data) {
      debugPrint('Real-time: New vendor created');
      if (mounted) {
        _loadData(); // Refresh vendors list
      }
    });

    _socketService.on('vendor:updated', (data) {
      debugPrint('Real-time: Vendor updated');
      if (mounted) {
        _loadData();
      }
    });

    // Listen for new products
    _socketService.on('product:created', (data) {
      debugPrint('Real-time: New product created');
      if (mounted) {
        _loadData();
      }
    });

    _socketService.on('product:updated', (data) {
      debugPrint('Real-time: Product updated');
      if (mounted) {
        _loadData();
      }
    });
  }

  void _removeSocketListeners() {
    _socketService.off('vendor:created');
    _socketService.off('vendor:updated');
    _socketService.off('product:created');
    _socketService.off('product:updated');
  }

  void _startPromoSlider() {
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _promoIndex = _promoIndex == 0 ? 1 : 0);
      }
    });
  }

  Future<void> _detectLocation() async {
    try {
      debugPrint('🌍 Starting location detection...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        if (mounted) {
          setState(() => _currentLocation = 'Enable Location');
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          if (mounted) {
            setState(() => _currentLocation = 'Location Denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        if (mounted) {
          setState(() => _currentLocation = 'Location Disabled');
        }
        return;
      }

      // Get current position
      debugPrint('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      debugPrint(
        '📍 Got position: ${position.latitude}, ${position.longitude}',
      );

      // Reverse geocode to get address
      String locationText = '';

      // For web, use backend API for reliable geocoding
      if (kIsWeb) {
        locationText = await _reverseGeocodeViaBackend(
          position.latitude,
          position.longitude,
        );
      } else {
        // For mobile, use the geocoding package
        locationText = await _reverseGeocodeNative(
          position.latitude,
          position.longitude,
        );
      }

      if (locationText.isEmpty) {
        locationText = 'Current Location';
      }

      debugPrint('📍 Location resolved: $locationText');

      if (mounted) {
        setState(() => _currentLocation = locationText);
      }

      // Emit location to socket for real-time tracking
      _socketService.emit('location:update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'address': locationText,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Location error: $e');
      if (mounted) {
        setState(() => _currentLocation = 'Location unavailable');
      }
    }
  }

  /// Reverse geocode using backend API (reliable for web)
  Future<String> _reverseGeocodeViaBackend(double lat, double lng) async {
    try {
      debugPrint('🌐 Reverse geocoding via backend: $lat, $lng');
      final response = await http
          .get(
            Uri.parse('$_backendBaseUrl/api/geocode/reverse?lat=$lat&lng=$lng'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? data['formatted_address'] ?? '';
        debugPrint('✅ Backend geocode result: $address');
        return address;
      }
    } catch (e) {
      debugPrint('⚠️ Backend geocoding failed: $e, falling back to native');
    }

    // Fallback to native geocoding
    return _reverseGeocodeNative(lat, lng);
  }

  /// Reverse geocode using native geocoding package
  Future<String> _reverseGeocodeNative(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        debugPrint(
          '📍 Placemark: name=${place.name}, subLocality=${place.subLocality}, locality=${place.locality}, street=${place.street}',
        );

        // Build location string - try multiple fields for best result
        final parts = <String>[];

        // Try street first for most specific
        if (place.street?.isNotEmpty == true &&
            !place.street!.contains(RegExp(r'^[\d\s,.-]+$'))) {
          parts.add(place.street!);
        }

        // Try to get the most specific location
        if (parts.isEmpty &&
            place.name?.isNotEmpty == true &&
            place.name != place.locality &&
            place.name != place.administrativeArea &&
            !place.name!.contains(RegExp(r'^[\d\s,.-]+$'))) {
          parts.add(place.name!);
        }
        if (place.subLocality?.isNotEmpty == true &&
            !parts.contains(place.subLocality)) {
          parts.add(place.subLocality!);
        }
        if (place.locality?.isNotEmpty == true &&
            !parts.contains(place.locality)) {
          parts.add(place.locality!);
        }
        if (parts.isEmpty && place.subAdministrativeArea?.isNotEmpty == true) {
          parts.add(place.subAdministrativeArea!);
        }
        if (parts.isEmpty && place.administrativeArea?.isNotEmpty == true) {
          parts.add(place.administrativeArea!);
        }

        // Take first 2 parts for concise display
        return parts.take(2).join(', ');
      }
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('Unexpected null value')) {
        debugPrint('⚠️ Native geocoding error: $msg');
      }
    }
    return '';
  }

  Future<void> _loadCartCount() async {
    await _cartService.init();
    setState(() => _cartCount = _cartService.itemCount);
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load vendors first (public endpoint)
      final vendorData = await ApiClient().getVendors();
      final vendors =
          (vendorData['vendors'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _vendors = vendors;
        _loading = false;
      });

      // Try to load products (may require auth - fail silently)
      try {
        final productData = await ApiClient().getJson(
          '/api/products?limit=200',
        );
        final products =
            (productData['items'] ?? productData['products'] ?? productData)
                as List?;
        if (products != null && mounted) {
          setState(() {
            _products = products.cast<Map<String, dynamic>>();
          });
        }
      } catch (e) {
        // Products require auth - that's OK for guest browsing
        debugPrint('Products not loaded (auth required): $e');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load vendors: $e';
        _loading = false;
      });
      return;
    }

    if (mounted) {
      _setupAutoScroll();
    }
  }

  List<Map<String, dynamic>> get _exploreVendorsList {
    final exploreTags = {'explore', 'popular', 'bestseller'};
    final ids = <String>{};
    for (final product in _products) {
      final tags = (product['tags'] as List?) ?? [];
      if (tags.any((t) => exploreTags.contains(t.toString().toLowerCase()))) {
        final vendorId = _extractVendorId(product['vendorId']);
        if (vendorId != null) ids.add(vendorId);
      }
    }

    final results = _vendors
        .where((vendor) => ids.contains(vendor['_id']?.toString()))
        .toList();

    if (results.isNotEmpty) return results;
    return _vendors;
  }

  List<_FeaturedVendorItem> get _featuredVendorItems {
    final featuredTags = {'featured'};
    final map = <String, _FeaturedVendorItem>{};

    for (final product in _products) {
      final tags = (product['tags'] as List?) ?? [];
      if (!tags.any((t) => featuredTags.contains(t.toString().toLowerCase()))) {
        continue;
      }
      final vendorId = _extractVendorId(product['vendorId']);
      if (vendorId == null) continue;
      if (map.containsKey(vendorId)) continue;
      final vendor = _vendors.firstWhere(
        (v) => v['_id']?.toString() == vendorId,
        orElse: () => <String, dynamic>{},
      );
      if (vendor.isNotEmpty) {
        map[vendorId] = _FeaturedVendorItem(vendor: vendor, product: product);
      }
    }

    if (map.isEmpty) {
      return _vendors
          .take(8)
          .map(
            (v) => _FeaturedVendorItem(
              vendor: v,
              product: const <String, dynamic>{},
            ),
          )
          .toList();
    }

    return map.values.toList();
  }

  List<Map<String, dynamic>> get _popularCategoryProducts {
    final popularTags = {'foodcourt', 'categoryspotlight'};
    final products = _products.where((product) {
      final tags = (product['tags'] as List?) ?? [];
      return tags.any(
            (t) => popularTags.contains(t.toString().toLowerCase()),
          ) ||
          (product['category']?.toString().toLowerCase() == 'foodcourt');
    }).toList();

    return products.isNotEmpty ? products : _products.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFFF6B00),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildPromoBanners()),
              SliverToBoxAdapter(child: _buildCategoriesSection()),

              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(child: _buildError())
              else if (_vendors.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else ...[
                SliverToBoxAdapter(child: _buildExploreVendors()),
                SliverToBoxAdapter(child: _buildFeaturedDeals()),
                SliverToBoxAdapter(child: _buildFoodCourtSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildWordmark(fontSize: 24),
              const Spacer(),
              _buildCartButton(),
              const SizedBox(width: 12),
              _buildProfileButton(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _buildLocationChip()),
              const SizedBox(width: 12),
              _buildDealsButton(),
              const SizedBox(width: 10),
              _buildFilterButton(),
            ],
          ),
        ],
      ),
    );
  }

  RichText _buildWordmark({double fontSize = 24}) {
    const palette = [
      Color(0xFF4285F4),
      Color(0xFFDB4437),
      Color(0xFFF4B400),
      Color(0xFF4285F4),
      Color(0xFF0F9D58),
      Color(0xFFDB4437),
      Color(0xFF4285F4),
      Color(0xFFF4B400),
      Color(0xFF0F9D58),
      Color(0xFFDB4437),
    ];

    const word = 'QuickServe';
    final spans = <TextSpan>[];
    for (var i = 0; i < word.length; i++) {
      spans.add(
        TextSpan(
          text: word[i],
          style: TextStyle(
            color: palette[i % palette.length],
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildCartButton() {
    return GestureDetector(
      onTap: () {
        if (_cartCount > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CheckoutPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your cart is empty'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF0F9D58),
              size: 22,
            ),
          ),
          if (_cartCount > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        if (_isLoggedIn) {
          Navigator.pushNamed(context, '/profile');
        } else {
          Navigator.pushNamed(context, '/auth');
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: _userInitials.isNotEmpty
              ? Text(
                  _userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : const Icon(Icons.person_outline, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLocationChip() {
    return GestureDetector(
      onTap: _detectLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Color(0xFFDB4437)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentLocation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15212B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF15212B)),
          ],
        ),
      ),
    );
  }

  Widget _buildDealsButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscoverPage(
              vendors: _vendors,
              products: _products,
              initialSection: DiscoverSection.featured,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.local_offer_outlined,
          color: Color(0xFFFF6B00),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DiscoverPage(
              vendors: _vendors,
              products: _products,
              initialSection: DiscoverSection.explore,
            ),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0F9D58),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: const Text('Filter'),
    );
  }

  Widget _buildPromoBanners() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: AnimatedClockBanner(
        onTap: () => Navigator.pushNamed(context, '/special-meals'),
      ),
    );
  }

  void _setupAutoScroll() {
    _exploreAutoScrollTimer?.cancel();
    _featuredAutoScrollTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_exploreVendorsList.length > 5) {
        _exploreAutoScrollTimer = Timer.periodic(
          const Duration(milliseconds: 30),
          (timer) {
            if (_exploreAutoScrollPaused) return;
            if (!_exploreScrollController.hasClients) return;
            final max = _exploreScrollController.position.maxScrollExtent;
            if (max <= 0) return;
            final next = _exploreScrollController.offset + 0.9;
            try {
              if (next >= max) {
                _exploreScrollController.jumpTo(0);
              } else {
                _exploreScrollController.jumpTo(next);
              }
            } catch (_) {}
          },
        );
      }

      if (_featuredVendorItems.length > 3) {
        _featuredAutoScrollTimer = Timer.periodic(
          const Duration(milliseconds: 35),
          (timer) {
            if (_featuredAutoScrollPaused) return;
            if (!_featuredScrollController.hasClients) return;
            final max = _featuredScrollController.position.maxScrollExtent;
            if (max <= 0) return;
            final next = _featuredScrollController.offset + 1.1;
            try {
              if (next >= max) {
                _featuredScrollController.jumpTo(0);
              } else {
                _featuredScrollController.jumpTo(next);
              }
            } catch (_) {}
          },
        );
      }
    });
  }

  void _onCategoryTap(String category) {
    // Handle category navigation - navigate to search with category filter
    switch (category.toLowerCase()) {
      case 'restaurants':
        Navigator.pushNamed(
          context,
          '/search',
          arguments: {'category': 'restaurants'},
        );
        break;
      case 'shops':
        Navigator.pushNamed(
          context,
          '/search',
          arguments: {'category': 'shops'},
        );
        break;
      case 'pharmacies':
        Navigator.pushNamed(
          context,
          '/search',
          arguments: {'category': 'pharmacies'},
        );
        break;
      case 'send package':
        // Navigate to package delivery page (send mode)
        Navigator.pushNamed(
          context,
          '/place-order',
          arguments: {'mode': 'send'},
        );
        break;
      case 'request pickup':
        // Navigate to package delivery page (pickup mode)
        Navigator.pushNamed(
          context,
          '/place-order',
          arguments: {'mode': 'pickup'},
        );
        break;
      case 'send packages':
        // Legacy fallback - Navigate to package delivery page
        Navigator.pushNamed(context, '/place-order');
        break;
      case 'local markets':
        Navigator.pushNamed(
          context,
          '/search',
          arguments: {'category': 'local markets'},
        );
        break;
      case 'more':
        // Navigate to search page to explore all
        Navigator.pushNamed(context, '/search');
        break;
      default:
        Navigator.pushNamed(
          context,
          '/search',
          arguments: {'category': category.toLowerCase()},
        );
    }
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'What do you need?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscoverPage(
                        vendors: _vendors,
                        products: _products,
                        initialSection: DiscoverSection.categories,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F9D58),
                ),
                icon: const Icon(Icons.arrow_outward, size: 16),
                label: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return GestureDetector(
                onTap: () => _onCategoryTap(cat['title'].toString()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        cat['image'] as String,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loading) {
                          if (loading == null) return child;
                          return Container(color: Colors.grey.shade200);
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            cat['icon'] as IconData,
                            color: const Color(0xFF0F9D58),
                            size: 32,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.15),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                cat['icon'] as IconData,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              cat['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cat['description'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExploreVendors() {
    final vendors = _exploreVendorsList.take(60).toList();
    if (vendors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Explore',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.explore, size: 20, color: Color(0xFFFF6B00)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiscoverPage(
                          vendors: _vendors,
                          products: _products,
                          initialSection: DiscoverSection.explore,
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Listener(
            onPointerDown: (_) => _exploreAutoScrollPaused = true,
            onPointerUp: (_) => _exploreAutoScrollPaused = false,
            onPointerCancel: (_) => _exploreAutoScrollPaused = false,
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                controller: _exploreScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: vendors.length,
                itemBuilder: (context, index) =>
                    _buildVendorCircle(vendors[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCircle(Map<String, dynamic> vendor) {
    final name = vendor['businessName'] ?? vendor['storeName'] ?? 'Vendor';
    final logo = vendor['logo'];
    final rating = (vendor['averageRating'] ?? 0).toDouble();
    final isOpen =
        (vendor['availabilityStatus'] ?? vendor['isOpen'] ?? 'open') == 'open';
    return GestureDetector(
      onTap: () => _openVendor(vendor),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                    border: Border.all(
                      color: isOpen ? const Color(0xFFFF6B00) : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: logo != null
                        ? Image.network(
                            _resolveImageUrl(logo.toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildInitial(name),
                          )
                        : _buildInitial(name),
                  ),
                ),
                // Open/Closed indicator dot
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (rating > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 10, color: Colors.amber),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B00),
        ),
      ),
    );
  }

  Widget _buildFeaturedDeals() {
    final featured = _featuredVendorItems;
    if (featured.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Featured',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 20, color: Color(0xFFFF6B00)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DiscoverPage(
                          vendors: _vendors,
                          products: _products,
                          initialSection: DiscoverSection.featured,
                        ),
                      ),
                    );
                  },
                  child: const Text('View all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Listener(
            onPointerDown: (_) => _featuredAutoScrollPaused = true,
            onPointerUp: (_) => _featuredAutoScrollPaused = false,
            onPointerCancel: (_) => _featuredAutoScrollPaused = false,
            child: SizedBox(
              height: 200,
              child: ListView.builder(
                controller: _featuredScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: featured.length,
                itemBuilder: (context, index) => _buildFeaturedCard(
                  featured[index].vendor,
                  featured[index].product,
                  index,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(
    Map<String, dynamic> vendor,
    Map<String, dynamic> product,
    int index,
  ) {
    final name = vendor['businessName'] ?? vendor['storeName'] ?? 'Vendor';
    final minOrder = vendor['minimumOrder'] ?? 1000;
    final productImage =
        product['imageUrl'] ?? product['image'] ?? product['images']?.first;
    final productName = product['name'] ?? 'Top pick';
    final productPrice = product['price'];
    final emojis = ['��', '��', '��', '��', '��', '��', '��', '��'];

    return GestureDetector(
      onTap: () => _openVendor(vendor),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: productImage != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        _resolveImageUrl(productImage.toString()),
                        width: double.infinity,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            emojis[index % emojis.length],
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        emojis[index % emojis.length],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productPrice != null
                        ? '��${_formatNumber(productPrice)}'
                        : 'From ��${_formatNumber(minOrder)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B00),
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
  }

  Widget _buildFoodCourtSection() {
    final products = _popularCategoryProducts;
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Popular Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.local_fire_department,
                size: 20,
                color: Color(0xFFFF6B00),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscoverPage(
                        vendors: _vendors,
                        products: _products,
                        initialSection: DiscoverSection.categories,
                      ),
                    ),
                  );
                },
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length > 12 ? 12 : products.length,
            itemBuilder: (context, index) => _buildProductCard(products[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Product';
    final price = product['price'] ?? 0;
    final imageUrl = product['imageUrl'] ?? product['image'];
    final rating = (product['averageRating'] ?? 0).toDouble();
    final prepTime = product['prepDurationMins'] ?? 0;
    final vendorId = (product['vendorId'] is Map)
        ? product['vendorId']['_id']?.toString()
        : product['vendorId']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        final vendor = _vendors.firstWhere(
          (v) => v['_id']?.toString() == vendorId,
          orElse: () => <String, dynamic>{},
        );
        if (vendor.isNotEmpty) _openVendor(vendor);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            _resolveImageUrl(imageUrl.toString()),
                            width: double.infinity,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.fastfood,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                // Prep time badge
                if (prepTime > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 10,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${prepTime}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '?${_formatNumber(price)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unable to load data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Vendors Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for delicious options!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVendor(Map<String, dynamic> vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorDetailScreen(vendor: vendor),
      ),
    );
  }

  String? _extractVendorId(dynamic vendorRef) {
    if (vendorRef == null) return null;
    if (vendorRef is String && vendorRef.isNotEmpty) return vendorRef;
    if (vendorRef is Map) {
      final value = vendorRef['_id'] ?? vendorRef['id'];
      if (value != null) return value.toString();
    }
    return null;
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) {
      // Fix for old IP addresses in database
      if (url.contains('192.168.') ||
          url.contains('127.0.0.1') ||
          url.contains('localhost')) {
        try {
          final uri = Uri.parse(url);
          return '$_backendBaseUrl${uri.path}';
        } catch (_) {
          return url;
        }
      }
      return url;
    }
    if (url.startsWith('/')) return '$_backendBaseUrl$url';
    return '$_backendBaseUrl/$url';
  }

  String _formatNumber(dynamic number) {
    final n = number is int ? number : int.tryParse(number.toString()) ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _FeaturedVendorItem {
  final Map<String, dynamic> vendor;
  final Map<String, dynamic> product;

  const _FeaturedVendorItem({required this.vendor, required this.product});
}
