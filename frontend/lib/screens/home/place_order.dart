import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _notes = TextEditingController();
  final _amountController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _packageDescController = TextEditingController();
  bool _loading = false;
  String? _msg;
  String? _error;
  static const double _adminFee = 50.0;
  String _mode = 'send'; // 'send' or 'pickup'

  @override
  void dispose() {
    _notes.dispose();
    _amountController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _packageDescController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final t = _amountController.text.trim();
    if (t.isEmpty) return 0.0;
    return double.tryParse(t.replaceAll(',', '')) ?? 0.0;
  }

  Future<void> _placePackageOrder() async {
    if (_pickupAddressController.text.trim().isEmpty ||
        _deliveryAddressController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in pickup and delivery addresses');
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
      _error = null;
    });
    try {
      final data = await ApiClient().postJson('/api/orders/package', {
        'type': _mode,
        'pickupAddress': _pickupAddressController.text.trim(),
        'deliveryAddress': _deliveryAddressController.text.trim(),
        'packageDescription': _packageDescController.text.trim(),
        'notes': _notes.text.trim(),
      });
      if (data['order'] != null || data['ok'] == true) {
        setState(
          () => _msg = _mode == 'send'
              ? 'Package delivery request submitted!'
              : 'Pickup request submitted!',
        );
      } else {
        throw Exception(data['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _placeOrder(String restaurant) async {
    setState(() {
      _loading = true;
      _msg = null;
      _error = null;
    });
    try {
      final amount = _parseAmount();
      // For the real backend we must send vendorId and items
      final vendorId = restaurant.replaceAll(' ', '_').toLowerCase();
      final data = await ApiClient().postJson('/orders', {
        'vendorId': vendorId,
        'items': [
          {'name': 'Sample item', 'price': amount, 'qty': 1},
        ],
        'deliveryAddress': 'Demo address',
        'distanceKm': 2,
        'notes': _notes.text.trim(),
      });
      // Backend returns the created order object (and qrDataUrl). Accept both shapes.
      if (data['order'] != null) {
        setState(() => _msg = 'Order placed successfully');
      } else if (data['ok'] == true) {
        setState(() => _msg = 'Order placed successfully');
      } else {
        throw Exception(data['error'] ?? 'Failed to place order');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final name = args?['name'] as String? ?? 'Restaurant';
    final mode = args?['mode'] as String? ?? 'order';
    final isPackageMode = mode == 'send' || mode == 'pickup';

    // Set mode from route args
    if (isPackageMode && _mode != mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mode = mode);
      });
    }

    final amount = _parseAmount();
    final total = amount + _adminFee;

    final appBarTitle = isPackageMode
        ? (mode == 'send' ? 'Send Package' : 'Request Pickup')
        : 'Order from $name';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isPackageMode
            ? _buildPackageForm()
            : _buildOrderForm(name, amount, total),
      ),
    );
  }

  Widget _buildPackageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode indicator
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _mode == 'send' ? Icons.local_shipping : Icons.call_received,
                color: const Color(0xFFFF6B00),
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == 'send' ? 'Send a Package' : 'Request Pickup',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _mode == 'send'
                          ? 'Have your package delivered anywhere'
                          : 'We\'ll pick up your package',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pickup Address
        TextField(
          controller: _pickupAddressController,
          decoration: InputDecoration(
            labelText: _mode == 'send' ? 'Pickup Address' : 'Your Address',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Delivery Address
        TextField(
          controller: _deliveryAddressController,
          decoration: InputDecoration(
            labelText: _mode == 'send'
                ? 'Delivery Address'
                : 'Drop-off Location',
            prefixIcon: const Icon(Icons.flag, color: Color(0xFFFF6B00)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Package Description
        TextField(
          controller: _packageDescController,
          decoration: InputDecoration(
            labelText: 'Package Description',
            hintText: 'e.g., Small box, documents, food...',
            prefixIcon: const Icon(Icons.inventory_2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notes,
          decoration: InputDecoration(
            labelText: 'Special Instructions (optional)',
            hintText: 'e.g., Handle with care, call on arrival...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: 24),

        // Fee info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base Fee'),
                  Text('₦${_adminFee.toStringAsFixed(0)}'),
                ],
              ),
              const Divider(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance Fee', style: TextStyle(color: Colors.grey)),
                  Text(
                    'Calculated at pickup',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_msg != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_msg!, style: const TextStyle(color: Colors.green)),
          ),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _loading ? null : _placePackageOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _loading
                ? 'Processing...'
                : (_mode == 'send' ? 'Request Delivery' : 'Request Pickup'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderForm(String name, double amount, double total) {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Order amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(
            labelText: 'Notes (e.g., no onions)',
          ),
          minLines: 3,
          maxLines: 5,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Admin fee'),
            Text('₦${_adminFee.toStringAsFixed(2)}'),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total'),
            Text(
              '₦${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_msg != null)
          Text(_msg!, style: const TextStyle(color: Colors.green)),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : () => _placeOrder(name),
          child: Text(_loading ? 'Placing...' : 'Place order'),
        ),
      ],
    );
  }
}
