import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/config.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import '../home/vendor_detail_screen.dart';

/// SearchScreen - Real-time search for vendors and products
/// Mirrors event-frontend search functionality with Socket.IO updates
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredVendors = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  Timer? _debounceTimer;

  // Advanced filters
  double _minRating = 0;
  RangeValues _priceRange = const RangeValues(0, 50000);
  String _sortBy = 'relevance';
  bool _showFilters = false;

  // Pagination/expansion state
  bool _showAllVendors = false;
  bool _showAllProducts = false;
  static const int _initialVendorCount = 10;
  static const int _initialProductCount = 12;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'All', 'emoji': 'ðŸ”'},
    {'title': 'Restaurants', 'emoji': 'ðŸ½ï¸'},
    {'title': 'Shops', 'emoji': 'ðŸ›’'},
    {'title': 'Pharmacies', 'emoji': 'ðŸ’Š'},
    {'title': 'Food', 'emoji': 'ðŸ”'},
    {'title': 'Drinks', 'emoji': 'ðŸ¥¤'},
  ];

  String _backendBaseUrl = AppConfig.backendBaseUrl;

  @override
  void initState() {
    super.initState();
    _initBackendUrl();
    _loadData();
    _setupSocketListeners();

    // Handle initial query from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? query = widget.initialQuery;
      String? category;

      if (args is Map) {
        if (args['query'] != null) {
          query = args['query'].toString();
        }
        if (args['category'] != null) {
          category = args['category'].toString().toLowerCase();
        }
      }

      if (category != null && category.isNotEmpty) {
        setState(() {
          _selectedCategory = category!;
          _applyFilters();
        });
      }

      if (query != null && query.isNotEmpty) {
        _searchController.text = query;
        _onSearchChanged(query);
      }
    });
  }

  Future<void> _initBackendUrl() async {
    try {
      final url = await ApiClient.getCurrentBackendUrl();
      if (mounted) {
        setState(() => _backendBaseUrl = url);
      }
    } catch (e) {
      debugPrint('Failed to get backend URL: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _setupSocketListeners() {
    final socket = SocketService().socket;
    if (socket != null) {
      // Listen for new vendors
      socket.on('vendor:created', (data) {
        if (mounted) {
          final vendor = data['vendor'] ?? data;
          setState(() {
            _vendors.insert(0, Map<String, dynamic>.from(vendor));
            _applyFilters();
          });
        }
      });

      // Listen for new products
      socket.on('product:created', (data) {
        if (mounted) {
          final product = data['product'] ?? data;
          setState(() {
            _products.insert(0, Map<String, dynamic>.from(product));
            _applyFilters();
          });
        }
      });

      // Listen for product updates
      socket.on('product:updated', (data) {
        if (mounted) {
          final product = data['product'] ?? data;
          final id = product['_id']?.toString();
          setState(() {
            final idx = _products.indexWhere((p) => p['_id']?.toString() == id);
            if (idx >= 0) {
              _products[idx] = Map<String, dynamic>.from(product);
              _applyFilters();
            }
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Load vendors and products in parallel
      final vendorData = await ApiClient().getVendors();
      _vendors =
          (vendorData['vendors'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      try {
        final productData = await ApiClient().getJson(
          '/api/products?limit=200',
        );
        final products =
            productData['items'] ?? productData['products'] ?? productData;
        if (products is List) {
          _products = products.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Products load failed: $e');
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Load error: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase().trim();
        _applyFilters();
      });
    });
  }

  // Map consumer-facing categories to vendor categories
  List<String> _getVendorCategoriesFor(String consumerCategory) {
    switch (consumerCategory.toLowerCase()) {
      case 'restaurants':
        return ['restaurant', 'fast food', 'bakery', 'general', 'food'];
      case 'shops':
        return ['grocery', 'supermarket', 'general', 'shop', 'store'];
      case 'pharmacies':
        return ['pharmacy', 'health', 'medical'];
      case 'local markets':
        return ['grocery', 'supermarket', 'market', 'fresh'];
      case 'food':
        return ['food', 'restaurant', 'fast food', 'bakery'];
      case 'drinks':
        return ['drinks', 'beverage', 'bar', 'juice'];
      default:
        return [consumerCategory.toLowerCase()];
    }
  }

  bool _matchesCategory(String vendorCategory, String selectedCategory) {
    if (selectedCategory == 'all') return true;
    final vendorCat = vendorCategory.toLowerCase();
    final mappedCategories = _getVendorCategoriesFor(selectedCategory);
    return mappedCategories.any(
      (cat) => vendorCat.contains(cat) || cat.contains(vendorCat),
    );
  }

  void _applyFilters() {
    // Filter vendors
    _filteredVendors = _vendors.where((v) {
      final name = (v['businessName'] ?? v['storeName'] ?? '')
          .toString()
          .toLowerCase();
      final category = (v['category'] ?? '').toString().toLowerCase();
      final rating = (v['rating'] ?? 0).toDouble();

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          category.contains(_searchQuery);

      final matchesCategory = _matchesCategory(category, _selectedCategory);
      final matchesRating = rating >= _minRating;

      return matchesSearch && matchesCategory && matchesRating;
    }).toList();

    // Filter products
    _filteredProducts = _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final category = (p['category'] ?? '').toString().toLowerCase();
      final description = (p['description'] ?? '').toString().toLowerCase();
      final price = (p['price'] ?? 0).toDouble();

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          category.contains(_searchQuery) ||
          description.contains(_searchQuery);

      final matchesCategory = _matchesCategory(category, _selectedCategory);
      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;

      return matchesSearch && matchesCategory && matchesPrice;
    }).toList();

    // Apply sorting
    _sortResults();
  }

  void _sortResults() {
    switch (_sortBy) {
      case 'rating':
        _filteredVendors.sort(
          (a, b) =>
              ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num),
        );
        break;
      case 'price_low':
        _filteredProducts.sort(
          (a, b) =>
              ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num),
        );
        break;
      case 'price_high':
        _filteredProducts.sort(
          (a, b) =>
              ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num),
        );
        break;
      case 'delivery_time':
        _filteredVendors.sort((a, b) {
          final aTime = _parseDeliveryTime(a['deliveryTime']);
          final bTime = _parseDeliveryTime(b['deliveryTime']);
          return aTime.compareTo(bTime);
        });
        break;
      default: // relevance - no additional sorting
        break;
    }
  }

  int _parseDeliveryTime(dynamic time) {
    if (time == null) return 999;
    final str = time.toString();
    final match = RegExp(r'(\d+)').firstMatch(str);
    return match != null ? int.tryParse(match.group(1)!) ?? 999 : 999;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            _buildSearchHeader(),

            // Advanced Filters (collapsible)
            if (_showFilters) _buildAdvancedFilters(),

            // Category Pills
            _buildCategoryPills(),

            // Results
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B00),
                      ),
                    )
                  : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    final hasActiveFilters =
        _minRating > 0 ||
        _priceRange.start > 0 ||
        _priceRange.end < 50000 ||
        _sortBy != 'relevance';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Search',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Filter toggle button
              GestureDetector(
                onTap: () => setState(() => _showFilters = !_showFilters),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? const Color(0xFFFF6B00)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: hasActiveFilters
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        size: 18,
                        color: hasActiveFilters
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasActiveFilters
                              ? Colors.white
                              : Colors.grey[700],
                          fontWeight: hasActiveFilters
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (hasActiveFilters) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search vendors, products...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B00)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort By
          Row(
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Relevance', 'relevance'),
                      _buildSortChip('Rating', 'rating'),
                      _buildSortChip('Price: Low', 'price_low'),
                      _buildSortChip('Price: High', 'price_high'),
                      _buildSortChip('Delivery', 'delivery_time'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Minimum Rating
          Row(
            children: [
              const Text(
                'Min Rating:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              ...List.generate(5, (i) {
                final rating = (i + 1).toDouble();
                final isSelected = _minRating >= rating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _minRating = _minRating == rating ? 0 : rating;
                      _applyFilters();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Colors.amber : Colors.grey[400],
                      size: 28,
                    ),
                  ),
                );
              }),
              if (_minRating > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${_minRating.toInt()}+',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Price Range
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Price Range:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '₦${_priceRange.start.toInt()} - ₦${_priceRange.end.toInt()}',
                    style: const TextStyle(
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 50000,
                divisions: 100,
                activeColor: const Color(0xFFFF6B00),
                labels: RangeLabels(
                  '₦${_priceRange.start.toInt()}',
                  '₦${_priceRange.end.toInt()}',
                ),
                onChanged: (values) {
                  setState(() => _priceRange = values);
                },
                onChangeEnd: (_) => _applyFilters(),
              ),
            ],
          ),

          // Clear filters button
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _minRating = 0;
                  _priceRange = const RangeValues(0, 50000);
                  _sortBy = 'relevance';
                  _applyFilters();
                });
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected =
              _selectedCategory == cat['title'].toString().toLowerCase();
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['title'].toString().toLowerCase();
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B00)
                      : Colors.grey[300]!,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    cat['emoji'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    if (_filteredVendors.isEmpty && _filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFFF6B00),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Vendors Section
          if (_filteredVendors.isNotEmpty) ...[
            _buildSectionHeader('Vendors', '🏪', _filteredVendors.length),
            const SizedBox(height: 8),
            ...(_showAllVendors
                    ? _filteredVendors
                    : _filteredVendors.take(_initialVendorCount))
                .map((v) => _buildVendorCard(v)),
            if (_filteredVendors.length > _initialVendorCount &&
                !_showAllVendors)
              _buildShowMoreButton(
                'vendors',
                _filteredVendors.length - _initialVendorCount,
              ),
            if (_showAllVendors &&
                _filteredVendors.length > _initialVendorCount)
              _buildShowLessButton('vendors'),
          ],

          // Products Section
          if (_filteredProducts.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSectionHeader(
              'Products',
              'ðŸ½ï¸',
              _filteredProducts.length,
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _showAllProducts
                  ? _filteredProducts.length
                  : (_filteredProducts.length > _initialProductCount
                        ? _initialProductCount
                        : _filteredProducts.length),
              itemBuilder: (context, index) =>
                  _buildProductCard(_filteredProducts[index]),
            ),
            if (_filteredProducts.length > _initialProductCount &&
                !_showAllProducts)
              _buildShowMoreButton(
                'products',
                _filteredProducts.length - _initialProductCount,
              ),
            if (_showAllProducts &&
                _filteredProducts.length > _initialProductCount)
              _buildShowLessButton('products'),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String emoji, int count) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count found',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF6B00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final name = vendor['businessName'] ?? vendor['storeName'] ?? 'Vendor';
    final category = vendor['category'] ?? 'General';
    final logo = vendor['logo'];
    final rating = (vendor['averageRating'] ?? 0).toDouble();
    final isOpen =
        (vendor['availabilityStatus'] ?? vendor['isOpen'] ?? 'open') == 'open';

    return GestureDetector(
      onTap: () => _openVendor(vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo/Avatar with open/closed indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
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
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (rating > 0) ...[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
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
          borderRadius: BorderRadius.circular(12),
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
            // Image with prep time badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              _resolveImageUrl(imageUrl.toString()),
                              width: double.infinity,
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
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          '₦${_formatNumber(price)}',
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
                                  fontSize: 10,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowMoreButton(String type, int remaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              if (type == 'vendors') {
                _showAllVendors = true;
              } else if (type == 'products') {
                _showAllProducts = true;
              }
            });
          },
          child: Text(
            'Show $remaining more $type',
            style: const TextStyle(
              color: Color(0xFFFF6B00),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShowLessButton(String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              if (type == 'vendors') {
                _showAllVendors = false;
              } else if (type == 'products') {
                _showAllProducts = false;
              }
            });
          },
          child: const Text(
            'Show less',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Start searching' : 'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Search for vendors or products'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B00),
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
