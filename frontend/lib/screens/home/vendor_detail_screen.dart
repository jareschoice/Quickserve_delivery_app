import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../services/api_client.dart';
import '../../services/cart_service.dart';
import '../orders/checkout_page.dart';

class VendorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> vendor;

  const VendorDetailScreen({super.key, required this.vendor});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  final CartService _cartService = CartService();
  String _backendBaseUrl = AppConfig.backendBaseUrl;

  @override
  void initState() {
    super.initState();
    _initBackendUrl();
    _initCart();
    _loadProducts();
  }

  Future<void> _initBackendUrl() async {
    try {
      final url = await ApiClient.getCurrentBackendUrl();
      if (mounted) {
        setState(() => _backendBaseUrl = url);
      }
    } catch (_) {}
  }

  String _resolveImageUrl(String? url) {
    if (url == null) return '';
    if (url.startsWith('http')) {
      // Fix for old IP addresses in database
      if (url.contains('192.168.') ||
          url.contains('127.0.0.1') ||
          url.contains('localhost')) {
        // Extract the path part (e.g., /uploads/...)
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

  Future<void> _initCart() async {
    await _cartService.init();
    _cartService.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final vendorId = widget.vendor['_id']?.toString() ?? '';
      final data = await ApiClient().getJson(
        '/api/products?vendorId=$vendorId',
      );
      final products =
          (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _loading = false;
      });
    }
  }

  void _addToCart(Map<String, dynamic> product, int quantity) async {
    final vendorId = widget.vendor['_id']?.toString() ?? '';
    final vendorUserId = widget.vendor['userId']?.toString() ?? vendorId;
    final vendorName =
        widget.vendor['businessName'] ?? widget.vendor['storeName'] ?? 'Vendor';

    // Extract add-ons and special instructions if present
    final selectedAddOns =
        (product['selectedAddOns'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final specialInstructions =
        product['specialInstructions']?.toString() ?? '';
    final imageUrl =
        product['imageUrl']?.toString() ?? product['image']?.toString();

    await _cartService.addItem(
      productId: product['_id']?.toString() ?? '',
      name: product['name'] ?? 'Product',
      price: (product['price'] ?? 0).toDouble(),
      qty: quantity,
      vendorId: vendorId,
      vendorUserId: vendorUserId,
      vendorName: vendorName,
      addOns: selectedAddOns,
      specialInstructions: specialInstructions,
      imageUrl: imageUrl,
    );

    // Only show snackbar if no customizations (customization has its own feedback)
    if (mounted && selectedAddOns.isEmpty && specialInstructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} added to cart!'),
          backgroundColor: const Color(0xFFFF6B00),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: _showCart,
          ),
        ),
      );
    }
  }

  int get _cartItemCount => _cartService.itemCount;

  double get _cartTotal => _cartService.subtotal;

  @override
  Widget build(BuildContext context) {
    final name =
        widget.vendor['businessName'] ?? widget.vendor['storeName'] ?? 'Vendor';
    final category = widget.vendor['category'] ?? 'General';
    final logo = widget.vendor['logo'];
    final rating = (widget.vendor['averageRating'] ?? 0).toDouble();
    final isOpen =
        (widget.vendor['availabilityStatus'] ??
            widget.vendor['isOpen'] ??
            'open') ==
        'open';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Vendor Info
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Logo/Initial
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: logo != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  logo.toString().startsWith('http')
                                      ? logo
                                      : '$_backendBaseUrl$logo',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'V',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6B00),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B00),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rating and Open/Closed badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (rating > 0) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpen ? 'Open' : 'Closed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Cart button
              Stack(
                children: [
                  IconButton(
                    onPressed: _showCart,
                    icon: const Icon(Icons.shopping_cart),
                  ),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartItemCount',
                          style: const TextStyle(
                            color: Color(0xFFFF6B00),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Products Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_products.length} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // Products List
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(child: _buildError())
          else if (_products.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductGridCard(_products[index]),
                  childCount: _products.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // Floating cart bar
      bottomNavigationBar: _cartService.items.isNotEmpty
          ? _buildCartBar()
          : null,
    );
  }

  // Product list item is deprecated - using grid view instead
  // ignore: unused_element
  Widget _buildProductListItem(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Product';
    final price = (product['price'] ?? 0).toDouble();
    final description = product['description'] ?? '';
    final imageUrl = product['imageUrl'] ?? product['image'];
    final rating = (product['averageRating'] ?? 0).toDouble();
    final prepTime = product['prepDurationMins'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _showProductDialog(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image (Left side) with prep time badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      child: imageUrl != null
                          ? Image.network(
                              _resolveImageUrl(imageUrl.toString()),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  color: Color(0xFFFF6B00),
                                  size: 32,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.fastfood,
                                color: Color(0xFFFF6B00),
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  // Prep time badge
                  if (prepTime > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 8,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${prepTime}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                    if (description.isNotEmpty)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₦${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                        // Add button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B00),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _addToCart(product, 1),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kept for reference but not used in list view
  Widget _buildProductGridCard(Map<String, dynamic> product) {
    final name = product['name'] ?? 'Product';
    final price = (product['price'] ?? 0).toDouble();
    final imageUrl = product['imageUrl'] ?? product['image'];
    final rating = (product['averageRating'] ?? 0).toDouble();
    final prepTime = product['prepDurationMins'] ?? 0;
    final vendorName =
        widget.vendor['businessName'] ?? widget.vendor['storeName'] ?? 'Vendor';

    return Container(
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
      child: InkWell(
        onTap: () => _showProductDialog(product),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with prep time badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            _resolveImageUrl(imageUrl.toString()),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.fastfood,
                                  color: Color(0xFFFF6B00),
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.fastfood,
                                color: Color(0xFFFF6B00),
                                size: 32,
                              ),
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
            // Product Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
                  Text(
                    'Fresh item from $vendorName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₦${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                      // Add button
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _addToCart(product, 1),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
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

  void _showProductDialog(Map<String, dynamic> product) {
    int quantity = 1;
    final name = product['name'] ?? 'Product';
    final price = (product['price'] ?? 0).toDouble();
    final description = product['description'] ?? '';
    final imageUrl = product['imageUrl'] ?? product['image'];
    final List<dynamic> addOns = product['addOns'] ?? [];

    // Track selected add-ons and special instructions
    List<Map<String, dynamic>> selectedAddOns = [];
    String specialInstructions = '';
    final instructionsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Calculate total with add-ons
            double addOnsTotal = selectedAddOns.fold(
              0.0,
              (sum, addon) => sum + ((addon['price'] ?? 0) as num).toDouble(),
            );
            double totalPrice = (price + addOnsTotal) * quantity;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _resolveImageUrl(imageUrl.toString()),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              color: Color(0xFFFF6B00),
                                              size: 60,
                                            ),
                                          ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      color: Color(0xFFFF6B00),
                                      size: 60,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: Text(
                                  description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              '\u20A6${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),

                          // Add-ons section
                          if (addOns.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: Color(0xFFFF6B00),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Add-ons',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Optional',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[200]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: addOns.asMap().entries.map((entry) {
                                  final addon =
                                      entry.value as Map<String, dynamic>;
                                  final addonName = addon['name'] ?? 'Extra';
                                  final addonPrice =
                                      ((addon['price'] ?? 0) as num).toDouble();
                                  final isSelected = selectedAddOns.any(
                                    (a) => a['name'] == addonName,
                                  );

                                  return Column(
                                    children: [
                                      if (entry.key > 0)
                                        Divider(
                                          height: 1,
                                          color: Colors.grey[200],
                                        ),
                                      CheckboxListTile(
                                        value: isSelected,
                                        onChanged: (checked) {
                                          setDialogState(() {
                                            if (checked == true) {
                                              selectedAddOns.add({
                                                'name': addonName,
                                                'price': addonPrice,
                                              });
                                            } else {
                                              selectedAddOns.removeWhere(
                                                (a) => a['name'] == addonName,
                                              );
                                            }
                                          });
                                        },
                                        title: Text(
                                          addonName,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        secondary: Text(
                                          '+\u20A6${addonPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFFFF6B00)
                                                : Colors.grey[600],
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        activeColor: const Color(0xFFFF6B00),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 0,
                                            ),
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        dense: true,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Special instructions
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: Color(0xFFFF6B00),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Special Instructions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Optional',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: instructionsController,
                            maxLines: 2,
                            maxLength: 200,
                            decoration: InputDecoration(
                              hintText: 'E.g., No onions, extra spicy, etc.',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF6B00),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              specialInstructions = value;
                            },
                          ),

                          const SizedBox(height: 20),
                          // Quantity selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: quantity > 1
                                          ? () =>
                                                setDialogState(() => quantity--)
                                          : null,
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          setDialogState(() => quantity++),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Selected add-ons summary
                          if (selectedAddOns.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF6B00,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your customizations:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...selectedAddOns.map(
                                    (addon) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '+ ${addon['name']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            '\u20A6${(addon['price'] as num).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Fixed bottom button
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _addToCartWithCustomization(
                            product,
                            quantity,
                            selectedAddOns,
                            specialInstructions,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add to Cart - \u20A6${totalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addToCartWithCustomization(
    Map<String, dynamic> product,
    int quantity,
    List<Map<String, dynamic>> selectedAddOns,
    String specialInstructions,
  ) {
    // Create enhanced product with customization
    final enhancedProduct = Map<String, dynamic>.from(product);
    enhancedProduct['selectedAddOns'] = selectedAddOns;
    enhancedProduct['specialInstructions'] = specialInstructions;

    // Calculate add-ons total
    double addOnsTotal = selectedAddOns.fold(
      0.0,
      (sum, addon) => sum + ((addon['price'] ?? 0) as num).toDouble(),
    );
    enhancedProduct['addOnsTotal'] = addOnsTotal;

    // Use existing cart logic with enhanced product
    _addToCart(enhancedProduct, quantity);

    // Show feedback with customization details
    String message = '$quantity x ${product['name']} added to cart';
    if (selectedAddOns.isNotEmpty) {
      message += ' with ${selectedAddOns.length} add-on(s)';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFFF6B00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_cartItemCount items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  'â‚¦${_cartTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _showCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Cart',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final items = _cartService.items;
            final isMultiVendor = _cartService.isMultiVendor;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Text(
                          'Your Cart',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isMultiVendor)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_cartService.itemsByVendor.keys.length} vendors',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                        Text(
                          '${_cartService.itemCount} items',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (items.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              await _cartService.clear();
                              setSheetState(() {});
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Cart Items grouped by vendor
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyCart()
                        : ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: _buildCartItemsByVendor(setSheetState),
                          ),
                  ),
                  // Checkout button
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'â‚¦${_cartService.subtotal.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Service Fee:',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'â‚¦${_cartService.serviceFeeTotal.toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'â‚¦${_cartService.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B00),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutPage(
                                      cartItems: _cartService.toMapList(),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B00),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCartItemsByVendor(StateSetter setSheetState) {
    final widgets = <Widget>[];
    final itemsByVendor = _cartService.itemsByVendor;

    for (final entry in itemsByVendor.entries) {
      final vendorName = entry.value.first.vendorName ?? 'Vendor';
      // Vendor header
      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFFFF6B00), size: 18),
              const SizedBox(width: 8),
              Text(
                vendorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
        ),
      );
      // Items for this vendor
      for (final item in entry.value) {
        widgets.add(_buildCartItemWidget(item, setSheetState));
      }
    }
    return widgets;
  }

  Widget _buildCartItemWidget(CartItem item, StateSetter setSheetState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'â‚¦${item.price.toStringAsFixed(0)} x ${item.qty}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            'â‚¦${item.total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF6B00),
            ),
          ),
          IconButton(
            onPressed: () async {
              await _cartService.removeItem(item.productId);
              setSheetState(() {});
              setState(() {});
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Add some delicious items!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
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
              'Failed to load menu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
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
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This vendor hasn\'t added any products',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
