import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import '../../services/cart_service.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>>?
  cartItems; // Optional - use CartService if null
  const CheckoutPage({super.key, this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final SocketService _socketService = SocketService();
  final CartService _cartService = CartService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();

  bool _isLoggedIn = false;
  bool _loading = true;
  bool _processingPayment = false;
  bool _validatingPromo = false;
  String _selectedPaymentMethod = 'paystack';
  String? _userEmail;

  // Promo code state
  String? _appliedPromoCode;
  double _promoDiscount = 0;
  String? _promoError;
  String? _promoSuccess;

  List<Map<String, dynamic>> _cartItems = [];

  // Service charge: â‚¦50 per vendor (matching backend commission)
  static const int serviceCharge = 50;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _checkLoginStatus();
    _setupSocketListeners();
  }

  Future<void> _loadCart() async {
    await _cartService.init();
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      // Use passed cart items if provided (legacy support)
      setState(() {
        _cartItems = widget.cartItems!;
      });
    } else {
      // Use CartService (global cart)
      setState(() {
        _cartItems = _cartService.items
            .map(
              (item) => {
                'id': item.productId,
                'productId': item.productId,
                'name': item.name,
                'price': item.price,
                'quantity': item.qty,
                'vendorId': item.vendorId,
                'vendorUserId': item.vendorUserId,
                'vendorName': item.vendorName,
              },
            )
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _promoController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.connect();

    _socketService.on('payment:success', (data) {
      debugPrint('Payment success: $data');
      if (mounted && _processingPayment) {
        setState(() => _processingPayment = false);
        _showOrderSuccess(data['orderId']?.toString());
      }
    });

    _socketService.on('payment:failed', (data) {
      debugPrint('Payment failed: $data');
      if (mounted) {
        setState(() => _processingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment failed: ${data['message'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _removeSocketListeners() {
    _socketService.off('payment:success');
    _socketService.off('payment:failed');
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _loading = false;
    });

    if (loggedIn) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await ApiClient().getJson('/api/users/profile');
      setState(() {
        _userEmail = data['email'];
        _phoneController.text = data['phone'] ?? '';
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  double get subtotal => _cartItems.fold(
    0.0,
    (p, e) => p + ((e['price'] ?? 0) * (e['quantity'] ?? 1)),
  );

  int get vendorCount => itemsByVendor.keys.length;

  double get serviceFeeTotal => serviceCharge * vendorCount.toDouble();

  double get total => subtotal + serviceFeeTotal - _promoDiscount;

  // Check if cart has items from multiple vendors
  bool get isMultiVendor {
    final vendors = _cartItems.map((item) => item['vendorId']).toSet();
    return vendors.length > 1;
  }

  // Group cart items by vendor
  Map<String, List<Map<String, dynamic>>> get itemsByVendor {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final item in _cartItems) {
      final vendorId = item['vendorId']?.toString() ?? 'unknown';
      if (!groups.containsKey(vendorId)) {
        groups[vendorId] = [];
      }
      groups[vendorId]!.add(item);
    }
    return groups;
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  /// Validate and apply promo code
  Future<void> _validatePromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoError = 'Enter a promo code';
        _promoSuccess = null;
      });
      return;
    }

    setState(() {
      _validatingPromo = true;
      _promoError = null;
      _promoSuccess = null;
    });

    try {
      final api = ApiClient();
      final response = await api.postJson('/api/promo/validate', {
        'code': code,
        'orderAmount': subtotal,
      });

      if (response['success'] == true) {
        setState(() {
          _appliedPromoCode = code;
          _promoDiscount = (response['promo']['calculatedDiscount'] ?? 0)
              .toDouble();
          _promoSuccess = response['message'];
          _promoError = null;
        });
      } else {
        setState(() {
          _promoError = response['message'] ?? 'Invalid promo code';
          _promoSuccess = null;
          _promoDiscount = 0;
          _appliedPromoCode = null;
        });
      }
    } catch (e) {
      setState(() {
        _promoError = e.toString().replaceAll('Exception: ', '');
        _promoSuccess = null;
        _promoDiscount = 0;
        _appliedPromoCode = null;
      });
    } finally {
      setState(() => _validatingPromo = false);
    }
  }

  /// Remove applied promo code
  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0;
      _promoError = null;
      _promoSuccess = null;
      _promoController.clear();
    });
  }

  void _handlePayment() async {
    if (!_isLoggedIn) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFFFF6B00),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Sign In Required'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To complete your order, please sign in.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 12),
              Text(
                'â€¢ Your cart will be saved',
                style: TextStyle(fontSize: 13),
              ),
              Text(
                'â€¢ Track your orders easily',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        await Navigator.pushNamed(context, '/auth');
        await _checkLoginStatus();
        if (_isLoggedIn) _processPayment();
      }
    } else {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a delivery address')),
        );
        return;
      }
      _processPayment();
    }
  }

  Future<void> _processPayment() async {
    setState(() => _processingPayment = true);

    try {
      final deliveryAddress = {'fullAddress': _addressController.text};
      final customerPhone = _phoneController.text;
      final customerEmail = _userEmail;

      // Get current URL for redirect (works on web)
      String redirectUrl = '';
      try {
        redirectUrl = Uri.base.origin; // e.g. http://localhost:64077
      } catch (_) {}

      dynamic response;

      if (isMultiVendor) {
        // Multi-vendor order - use init-multi-vendor-payment (like event-frontend checkout.js)
        final orders = itemsByVendor.entries.map((entry) {
          final vendorId = entry.key;
          final items = entry.value;
          final vendorName = items.first['vendorName'] ?? 'Vendor';
          final vendorUserId = items.first['vendorUserId'] ?? vendorId;

          return {
            'vendorId': vendorUserId,
            'vendorUserId': vendorUserId,
            'vendorName': vendorName,
            'items': items
                .map(
                  (item) => {
                    'name': item['name'],
                    'price': item['price'],
                    'qty': item['quantity'] ?? 1,
                  },
                )
                .toList(),
          };
        }).toList();

        final paymentData = {
          'orders': orders,
          'deliveryAddress': deliveryAddress,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'serviceCharge': serviceFeeTotal,
          'total': total,
          'paymentMethod': _selectedPaymentMethod,
          'redirectUrl': redirectUrl, // Send redirect URL
        };

        debugPrint('Multi-vendor payment: $paymentData');
        response = await ApiClient().postJson(
          '/api/payments/init-multi-vendor-payment',
          paymentData,
        );
      } else {
        // Single vendor order - use init-order-payment
        final items = _cartItems
            .map(
              (item) => {
                'productId': item['id'] ?? item['_id'] ?? item['productId'],
                'name': item['name'],
                'quantity': item['quantity'] ?? 1,
                'price': item['price'],
                'vendorId': item['vendorId'],
              },
            )
            .toList();

        final vendorId =
            _cartItems.first['vendorUserId'] ?? _cartItems.first['vendorId'];

        final paymentData = {
          'items': items,
          'vendorId': vendorId,
          'subtotal': subtotal,
          'serviceCharge': serviceFeeTotal,
          'total': total,
          'deliveryAddress': deliveryAddress,
          'customerPhone': customerPhone,
          'customerEmail': customerEmail,
          'paymentMethod': _selectedPaymentMethod,
          'redirectUrl': redirectUrl, // Send redirect URL
        };

        debugPrint('Single-vendor payment: $paymentData');
        response = await ApiClient().postJson(
          '/api/payments/init-order-payment',
          paymentData,
        );
      }

      debugPrint('Payment response: $response');

      if (response['authorization_url'] != null) {
        final url = Uri.parse(response['authorization_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          final reference = response['reference'] ?? response['orderGroupId'];
          if (mounted) _showPaymentWaitingDialog(reference);
        } else {
          throw Exception('Could not launch payment URL');
        }
      } else if (response['orderId'] != null ||
          response['orderGroupId'] != null) {
        // Clear cart on success
        await _cartService.clear();
        if (mounted) {
          setState(() => _processingPayment = false);
          _showOrderSuccess(
            response['orderId']?.toString() ??
                response['orderGroupId']?.toString(),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Payment initialization failed');
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      setState(() => _processingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentWaitingDialog(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Completing Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF6B00)),
            const SizedBox(height: 16),
            const Text('Complete the payment in your browser.'),
            const SizedBox(height: 8),
            Text(
              'Reference: $reference',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _processingPayment = false);
              _verifyPayment(reference);
            },
            child: const Text('I\'ve completed payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _processingPayment = false);
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(String reference) async {
    setState(() => _processingPayment = true);
    try {
      final response = await ApiClient().getJson(
        '/api/payments/verify?reference=$reference',
      );
      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          setState(() => _processingPayment = false);
          _showOrderSuccess(response['orderId']?.toString());
        }
      } else {
        throw Exception('Payment not verified');
      }
    } catch (e) {
      setState(() => _processingPayment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showOrderSuccess(String? orderId) {
    final shortId = orderId != null && orderId.length > 6
        ? orderId.substring(orderId.length - 6).toUpperCase()
        : orderId?.toUpperCase() ?? '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Order Placed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order has been placed successfully!'),
            const SizedBox(height: 8),
            Text(
              'Order ID: $shortId',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Total: â‚¦${_formatNumber(total.toInt())}'),
            const SizedBox(height: 8),
            const Text(
              'Track your order in the Orders tab.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    // Show empty cart message if no items
    if (_cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Your cart is empty',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add items from vendors to start your order',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Browse Vendors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isLoggedIn)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFFF6B00),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Sign in required to complete payment',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/auth'),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFFFF6B00),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF6B00,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item['quantity'] ?? 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6B00),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'] ?? 'Item'),
                                      if (isMultiVendor &&
                                          item['vendorName'] != null)
                                        Text(
                                          item['vendorName'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'â‚¦${_formatNumber((item['price'] ?? 0) * (item['quantity'] ?? 1))}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text('â‚¦${_formatNumber(subtotal.toInt())}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text('Service Charge'),
                                const SizedBox(width: 4),
                                Tooltip(
                                  message: 'Platform fee - â‚¦50',
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'â‚¦${_formatNumber(serviceFeeTotal.toInt())}',
                            ),
                          ],
                        ),

                        // Promo Code Section
                        const SizedBox(height: 16),
                        if (_appliedPromoCode == null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _promoController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter promo code',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.local_offer,
                                      size: 18,
                                    ),
                                  ),
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _validatingPromo
                                    ? null
                                    : _validatePromoCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _validatingPromo
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Apply'),
                              ),
                            ],
                          ),
                          if (_promoError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _promoError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Promo: $_appliedPromoCode',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        _promoSuccess ?? 'Discount applied',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _removePromoCode,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Promo Discount',
                                style: TextStyle(color: Colors.green),
                              ),
                              Text(
                                '-â‚¦${_formatNumber(_promoDiscount.toInt())}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'â‚¦${_formatNumber(total.toInt())}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isLoggedIn) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'Enter your delivery address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    'paystack',
                    Icons.credit_card,
                    'Online Payment',
                    'Card, Bank Transfer, USSD',
                  ),
                  _buildPaymentOption(
                    'wallet',
                    Icons.account_balance_wallet,
                    'Wallet',
                    'Pay from your QuickServe wallet',
                  ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),

          if (_processingPayment)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF6B00)),
                    SizedBox(height: 16),
                    Text(
                      'Processing payment...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
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
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processingPayment ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                _isLoggedIn
                    ? 'Pay â‚¦${_formatNumber(total.toInt())}'
                    : 'Sign In & Pay',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6B00).withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? const Color(0xFFFF6B00) : Colors.grey,
        ),
        onTap: () => setState(() => _selectedPaymentMethod = value),
      ),
    );
  }
}
