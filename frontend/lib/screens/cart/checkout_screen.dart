// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/empty_state.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import '../../utils/constants.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Service charge: Consumer pays â‚¦50 only
  static const int serviceCharge = AppConfig.serviceCharge; // â‚¦50

  List<CartItem> cartItems = [];
  bool _loading = true;
  bool _isLoggedIn = false;
  String _selectedPaymentMethod = 'paystack';
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  Map<String, dynamic>? _userLocation;
  String? _userEmail;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadCartAndCheckLogin();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.connect();

    _socketService.on('order:created', (data) {
      debugPrint('Order created: $data');
    });

    _socketService.on('payment:success', (data) {
      debugPrint('Payment success: $data');
    });

    _socketService.on('payment:failed', (data) {
      debugPrint('Payment failed: $data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${data['message'] ?? 'Unknown error'}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _removeSocketListeners() {
    _socketService.off('order:created');
    _socketService.off('payment:success');
    _socketService.off('payment:failed');
  }

  Future<void> _loadCartAndCheckLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _userEmail = prefs.getString('user_email');
    _userName = prefs.getString('user_name');

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
    });

    // Load cart from local storage or API
    await _loadCart();

    // Load saved addresses if logged in
    if (_isLoggedIn) {
      await _loadAddresses();
      await _loadUserProfile();
    }

    setState(() => _loading = false);
  }

  Future<void> _loadUserProfile() async {
    try {
      final data = await ApiClient().getJson('/api/users/profile');
      setState(() {
        _userEmail = data['email'];
        _userName = data['name'];
        _phoneController.text = data['phone'] ?? '';
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> _loadCart() async {
    // For now, use demo items - replace with actual cart provider
    setState(() {
      cartItems = [
        CartItem(
          id: 'i1',
          name: 'Spicy Jollof Rice',
          price: 1500,
          qty: 2,
          vendorId: 'vendor_1',
        ),
        CartItem(
          id: 'i2',
          name: 'Grilled Chicken',
          price: 2000,
          qty: 1,
          vendorId: 'vendor_1',
        ),
      ];
    });
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await ApiClient().getJson('/api/users/addresses');
      setState(() {
        _savedAddresses =
            (data['addresses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (_savedAddresses.isNotEmpty) {
          final defaultAddr = _savedAddresses.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => _savedAddresses.first,
          );
          _selectedAddressId = defaultAddr['_id'];
          _addressController.text =
              defaultAddr['fullAddress'] ?? defaultAddr['address'] ?? '';
        }
      });
    } catch (e) {
      debugPrint('Failed to load addresses: $e');
    }
  }

  int get subtotal => cartItems.fold<int>(0, (s, i) => s + i.total);
  int get total => subtotal + serviceCharge;

  Future<void> _payWithPaystack() async {
    if (!_isLoggedIn) {
      // Redirect to login
      final result = await Navigator.pushNamed(context, '/auth');
      if (result == true) {
        _loadCartAndCheckLogin();
      }
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address')),
      );
      return;
    }

    // Show payment confirmation
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtotal: â‚¦${_formatNumber(subtotal)}'),
            Text('Service Charge: â‚¦${_formatNumber(serviceCharge)}'),
            const Divider(),
            Text(
              'Total: â‚¦${_formatNumber(total)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text('Delivery: ${_addressController.text}'),
            const SizedBox(height: 8),
            Text(
              'Payment: ${_selectedPaymentMethod == 'paystack' ? 'Paystack' : 'Cash on Delivery'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processPayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
      ),
    );

    try {
      // Get delivery location coordinates for live map
      final deliveryLocation =
          _userLocation ??
          {
            'lat': 6.5244, // Default Lagos coordinates
            'lng': 3.3792,
          };

      // Create order via API with all checkout data
      final orderData = {
        'items': cartItems
            .map(
              (item) => {
                'productId': item.id,
                'name': item.name,
                'quantity': item.qty,
                'price': item.price,
              },
            )
            .toList(),
        'subtotal': subtotal,
        'serviceCharge': serviceCharge, // â‚¦50 only
        'total': total,
        'deliveryAddress': {
          'fullAddress': _addressController.text,
          'coordinates': deliveryLocation,
        },
        'deliveryLocation': deliveryLocation, // For live map tracking
        'customerPhone': _phoneController.text,
        'customerEmail': _userEmail,
        'customerName': _userName,
        'notes': _notesController.text,
        'paymentMethod': _selectedPaymentMethod,
      };

      // If Paystack selected, initiate payment first
      if (_selectedPaymentMethod == 'paystack') {
        // Initialize Paystack payment via backend
        final paymentInit = await ApiClient().postJson(
          '/api/payments/initialize',
          {
            'amount': total * 100, // Paystack uses kobo
            'email': _userEmail ?? 'customer@quickserve.ng',
            'metadata': {
              'items': cartItems.length,
              'subtotal': subtotal,
              'serviceCharge': serviceCharge,
            },
          },
        );

        // Emit payment initialization
        _socketService.emit('payment:initialized', {
          'reference': paymentInit['reference'],
          'amount': total,
        });

        // TODO: Open Paystack webview with authorization_url
        // For now, proceed with order creation (test mode)
        debugPrint('Paystack auth URL: ${paymentInit['authorization_url']}');
      }

      // Create the order
      final response = await ApiClient().postJson('/api/orders', orderData);

      if (!mounted) return;

      Navigator.pop(context); // Close loading

      // Emit order created event to all listeners
      _socketService.emit('order:created', {
        'orderId': response['order']?['_id'],
        'total': total,
        'items': cartItems.length,
        'deliveryAddress': _addressController.text,
        'deliveryLocation': deliveryLocation,
        'paymentMethod': _selectedPaymentMethod,
      });

      // Also emit to vendor
      _socketService.emit('order:new', {
        'orderId': response['order']?['_id'],
        'vendorId': cartItems.first.vendorId,
        'total': total,
        'items': cartItems.map((i) => {'name': i.name, 'qty': i.qty}).toList(),
      });

      // Show success
      final orderId = response['order']?['_id']?.toString() ?? '';
      final shortId = orderId.length > 6
          ? orderId.substring(orderId.length - 6).toUpperCase()
          : orderId.toUpperCase();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
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
              Text('Your order has been placed successfully.'),
              const SizedBox(height: 8),
              Text(
                'Order ID: $shortId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Total: â‚¦${_formatNumber(total)}'),
              const SizedBox(height: 8),
              const Text(
                'You can track your order in real-time!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back from checkout
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/orders');
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
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Widget _buildItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fastfood, color: Color(0xFFFF6B00)),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('â‚¦${_formatNumber(item.price)} Ã— ${item.qty}'),
        trailing: Text(
          'â‚¦${_formatNumber(item.total)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B00),
          ),
        ),
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

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
        ),
        body: const EmptyState(message: 'Your cart is empty'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Items
                  const Text(
                    'Order Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...cartItems.map(_buildItem),

                  const SizedBox(height: 24),

                  // Order Summary
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal'),
                              Text('â‚¦${_formatNumber(subtotal)}'),
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
                                    message:
                                        'Platform fee for order processing and delivery coordination',
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              Text('â‚¦${_formatNumber(serviceCharge)}'),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'â‚¦${_formatNumber(total)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFFFF6B00),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Address
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_savedAddresses.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAddressId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                      items: _savedAddresses.map((addr) {
                        return DropdownMenuItem(
                          value: addr['_id'] as String?,
                          child: Text(addr['label'] ?? 'Address'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAddressId = value;
                          final addr = _savedAddresses.firstWhere(
                            (a) => a['_id'] == value,
                          );
                          _addressController.text =
                              addr['fullAddress'] ?? addr['address'] ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'Enter your delivery address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.edit_location,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Phone Number
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
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

                  // Delivery Notes
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Delivery Notes (Optional)',
                      hintText: 'E.g., Ring the bell, call on arrival',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(
                        Icons.note,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Payment Method
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    'paystack',
                    Icons.credit_card,
                    'Paystack',
                    'Cards, Bank Transfer, USSD',
                  ),
                  _buildPaymentOption(
                    'cash',
                    Icons.money,
                    'Cash on Delivery',
                    'Pay when your order arrives',
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),

          // Bottom Pay Button
          Container(
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
                  onPressed: _payWithPaystack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isLoggedIn
                        ? 'Pay â‚¦${_formatNumber(total)}'
                        : 'Sign In to Checkout',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
