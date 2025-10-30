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
  bool _loading = false;
  String? _msg;
  String? _error;
  static const double _adminFee = 50.0;

  @override
  void dispose() {
    _notes.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final t = _amountController.text.trim();
    if (t.isEmpty) return 0.0;
    return double.tryParse(t.replaceAll(',', '')) ?? 0.0;
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
    final amount = _parseAmount();
    final total = amount + _adminFee;
    return Scaffold(
      appBar: AppBar(title: Text('Order from $name')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Order amount'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
        ),
      ),
    );
  }
}
