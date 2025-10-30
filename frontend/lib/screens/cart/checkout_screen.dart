// lib/screens/cart/checkout_screen.dart
import 'package:flutter/material.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/empty_state.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // For demo: we will create a fake cart list here (replace with provider)
  List<CartItem> demoItems = [
    CartItem(id: 'i1', name: 'Spicy Jollof', price: 1200, qty: 2, vendorId: 'vendor_1'),
    CartItem(id: 'i2', name: 'Small Chips', price: 500, qty: 1, vendorId: 'vendor_1'),
  ];

  int serviceCharge = 50;

  int get subtotal => demoItems.fold(0, (s, i) => s + i.total);
  int get total => subtotal + serviceCharge;

  void _payWithPaystack() {
    // Placeholder action — replace with real Paystack SDK flow later
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paystack (Demo)'),
        content: Text('Total to pay: ₦$total\n\nThis is a placeholder for Paystack integration.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment simulated (demo).')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Proceed'),
          )
        ],
      ),
    );
  }

  Widget _buildItem(CartItem item) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('₦${item.price} • x${item.qty}'),
      trailing: Text('₦${item.total}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (demoItems.isEmpty) {
      return const Scaffold(appBar: AppBar(title: Text('Checkout')), body: EmptyState(message: 'Your cart is empty'));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Expanded(
            child: ListView(
              children: [
                ...demoItems.map(_buildItem),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('₦$subtotal')]),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Service charge'), Text('₦$serviceCharge')]),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('₦$total', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Delivery details (mock)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const TextField(decoration: InputDecoration(labelText: 'Delivery address')),
              ],
            ),
          ),
          PrimaryButton(label: 'Pay with Paystack', onPressed: _payWithPaystack),
        ]),
      ),
    );
  }
}