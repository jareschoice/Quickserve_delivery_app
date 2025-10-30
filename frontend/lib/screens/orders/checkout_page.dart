import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  const CheckoutPage({super.key, required this.cartItems});

  double get subtotal => cartItems.fold(
    0.0,
    (p, e) => p + ((e['price'] ?? 0) * (e['quantity'] ?? 1)),
  );

  @override
  Widget build(BuildContext context) {
    final svcCharge = double.parse(
      (subtotal * 0.025).toStringAsFixed(2),
    ); // 2.5%
    final deliveryFee = 200.0;
    final total = subtotal + svcCharge + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, idx) {
                  final item = cartItems[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['name'] ?? 'Item'),
                    subtitle: Text('Qty: ${item['quantity'] ?? 1}'),
                    trailing: Text(
                      '₦${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₦${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service charge (2.5%)'),
                Text('₦${svcCharge.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text('₦${deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₦${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Integrate real payment provider
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment flow not implemented yet'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Pay Now', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
