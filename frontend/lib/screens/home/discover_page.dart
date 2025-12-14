import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../services/api_client.dart';
import 'vendor_detail_screen.dart';

enum DiscoverSection { explore, featured, categories }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    required this.vendors,
    required this.products,
    this.initialSection = DiscoverSection.explore,
  });

  final List<Map<String, dynamic>> vendors;
  final List<Map<String, dynamic>> products;
  final DiscoverSection initialSection;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  String? _error;
  String _searchQuery = '';
  late List<Map<String, dynamic>> _vendors;
  late List<Map<String, dynamic>> _products;
  String _backendBaseUrl = AppConfig.backendBaseUrl;

  @override
  void initState() {
    super.initState();
    _vendors = List<Map<String, dynamic>>.from(widget.vendors);
    _products = List<Map<String, dynamic>>.from(widget.products);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialSection.index,
    );
    _initBackendUrl();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vendorData = await ApiClient().getVendors();
      final vendors =
          (vendorData['vendors'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final productData = await ApiClient().getJson('/api/products?limit=200');
      final products =
          (productData['items'] ?? productData['products'] ?? productData)
              as List?;

      setState(() {
        _vendors = vendors;
        _products = products?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (e) {
      setState(() => _error = 'Refresh failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initBackendUrl() async {
    try {
      final url = await ApiClient.getCurrentBackendUrl();
      if (mounted) {
        setState(() => _backendBaseUrl = url);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: _buildWordmark(fontSize: 22),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F9D58),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0F9D58),
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'Featured'),
            Tab(text: 'Popular Categories'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              width: double.infinity,
              color: const Color(0x1AF44336),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search vendors or products',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.trim()),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(height: 2, child: LinearProgressIndicator()),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF0F9D58),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExploreTab(),
                  _buildFeaturedTab(),
                  _buildCategoriesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    final vendors = _filteredExploreVendors;
    if (vendors.isEmpty) {
      return _buildEmptyState('No vendors match your filters');
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: vendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final vendor = vendors[index];
        final name = (vendor['businessName'] ?? vendor['storeName'] ?? 'Vendor')
            .toString();
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'Q';
        final logo = vendor['logo'];
        final category = (vendor['category'] ?? 'General').toString();
        final minimum = vendor['minimumOrder'] ?? 1000;

        return ListTile(
          onTap: () => _openVendor(vendor),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: logo != null
                ? Image.network(
                    _resolveImageUrl(logo.toString()),
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFFFFF4E6),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('$category • From ₦${_formatNumber(minimum)}'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildFeaturedTab() {
    final featured = _filteredFeaturedEntries;
    if (featured.isEmpty) {
      return _buildEmptyState('No featured products yet');
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: featured.length,
      itemBuilder: (_, index) {
        final entry = featured[index];
        final vendor = entry.vendor;
        final product = entry.product;
        final name = vendor['businessName'] ?? vendor['storeName'] ?? 'Vendor';
        final productName = product['name'] ?? 'Product';
        final image =
            product['imageUrl'] ?? product['image'] ?? product['images']?.first;
        final price = product['price'];

        return GestureDetector(
          onTap: () => _openVendor(vendor),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: image != null
                      ? Image.network(
                          _resolveImageUrl(image.toString()),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 180,
                          color: const Color(0xFFFFF4E6),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fastfood,
                            size: 48,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(name, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(
                        price != null
                            ? '₦${_formatNumber(price)}'
                            : 'From ₦${_formatNumber(vendor['minimumOrder'] ?? 1000)}',
                        style: const TextStyle(
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildCategoriesTab() {
    final products = _filteredCategoryProducts;
    if (products.isEmpty) {
      return _buildEmptyState('No spotlight products yet');
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.7, // Made taller to prevent overflow
      ),
      itemCount: products.length,
      itemBuilder: (_, index) {
        final product = products[index];
        final vendorId = _extractVendorId(product['vendorId']);
        final vendor = _vendors.firstWhere(
          (v) => v['_id']?.toString() == vendorId,
          orElse: () => <String, dynamic>{},
        );
        final image =
            product['imageUrl'] ?? product['image'] ?? product['images']?.first;
        final productName = product['name'] ?? 'Product';
        final price = product['price'];

        return GestureDetector(
          onTap: () {
            if (vendor.isNotEmpty) _openVendor(vendor);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: image != null
                      ? Image.network(
                          _resolveImageUrl(image.toString()),
                          height: 120, // Slightly reduced image height
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          color: const Color(0xFFF4F6F8),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fastfood,
                            size: 36,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                ),
                Expanded(
                  // Use Expanded to fill remaining space
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // Distribute space
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          price != null
                              ? '₦${_formatNumber(price)}'
                              : '₦${_formatNumber(vendor['minimumOrder'] ?? 1000)}',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
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
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredExploreVendors {
    final exploreTags = {'explore', 'popular', 'bestseller'};
    final ids = <String>{};
    for (final product in _products) {
      final tags = (product['tags'] as List?) ?? [];
      if (tags.any((t) => exploreTags.contains(t.toString().toLowerCase()))) {
        final id = _extractVendorId(product['vendorId']);
        if (id != null) ids.add(id);
      }
    }

    final list = _vendors
        .where((vendor) => ids.contains(vendor['_id']?.toString()))
        .toList();
    final source = list.isNotEmpty ? list : _vendors;

    if (_searchQuery.isEmpty) return source;
    final query = _searchQuery.toLowerCase();
    return source
        .where(
          (v) =>
              (v['businessName'] ?? v['storeName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              (v['category'] ?? '').toString().toLowerCase().contains(query),
        )
        .toList();
  }

  List<_DiscoverFeaturedEntry> get _filteredFeaturedEntries {
    final featuredTags = {'featured'};
    final map = <String, _DiscoverFeaturedEntry>{};

    for (final product in _products) {
      final tags = (product['tags'] as List?) ?? [];
      if (!tags.any((t) => featuredTags.contains(t.toString().toLowerCase()))) {
        continue;
      }
      final vendorId = _extractVendorId(product['vendorId']);
      if (vendorId == null || map.containsKey(vendorId)) continue;
      final vendor = _vendors.firstWhere(
        (v) => v['_id']?.toString() == vendorId,
        orElse: () => <String, dynamic>{},
      );
      if (vendor.isNotEmpty) {
        map[vendorId] = _DiscoverFeaturedEntry(
          vendor: vendor,
          product: product,
        );
      }
    }

    final entries = map.isNotEmpty
        ? map.values.toList()
        : _vendors
              .take(8)
              .map(
                (v) => _DiscoverFeaturedEntry(
                  vendor: v,
                  product: const <String, dynamic>{},
                ),
              )
              .toList();

    if (_searchQuery.isEmpty) return entries;
    final query = _searchQuery.toLowerCase();
    return entries
        .where(
          (entry) =>
              (entry.vendor['businessName'] ?? entry.vendor['storeName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              (entry.product['name'] ?? '').toString().toLowerCase().contains(
                query,
              ),
        )
        .toList();
  }

  List<Map<String, dynamic>> get _filteredCategoryProducts {
    final tags = {'foodcourt', 'categoryspotlight'};
    final products = _products.where((product) {
      final tagList = (product['tags'] as List?) ?? [];
      return tagList.any((t) => tags.contains(t.toString().toLowerCase())) ||
          (product['category']?.toString().toLowerCase() == 'foodcourt');
    }).toList();

    final source = products.isNotEmpty ? products : _products;
    if (_searchQuery.isEmpty) return source;
    final query = _searchQuery.toLowerCase();
    return source
        .where(
          (p) =>
              (p['name'] ?? '').toString().toLowerCase().contains(query) ||
              (p['category'] ?? '').toString().toLowerCase().contains(query),
        )
        .toList();
  }

  void _openVendor(Map<String, dynamic> vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: vendor)),
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
    if (url.startsWith('/')) {
      return '$_backendBaseUrl$url';
    }
    return '$_backendBaseUrl/$url';
  }

  String _formatNumber(dynamic number) {
    num value;
    if (number is num) {
      value = number;
    } else {
      value = double.tryParse(number.toString()) ?? 0;
    }
    final intValue = value.round();
    return intValue.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
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
}

class _DiscoverFeaturedEntry {
  const _DiscoverFeaturedEntry({required this.vendor, required this.product});
  final Map<String, dynamic> vendor;
  final Map<String, dynamic> product;
}
