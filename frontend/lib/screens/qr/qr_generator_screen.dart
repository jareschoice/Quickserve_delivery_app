// lib/screens/qr/qr_generator_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatelessWidget {
  const QRGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    String orderId = '';
    String qrToken = '';
    if (args is Map<String, dynamic>) {
      orderId = args['orderId']?.toString() ?? '';
      qrToken = args['qrToken']?.toString() ?? '';
    } else {
      // demo token if none provided
      orderId = 'order_demo_${DateTime.now().millisecondsSinceEpoch}';
      qrToken = 'demo_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    }

    final payload = {'orderId': orderId, 'token': qrToken};
    final qrData = Uri(queryParameters: payload.map((k, v) => MapEntry(k, v.toString()))).toString(); // small encoded payload

    return Scaffold(
      appBar: AppBar(title: const Text('Order QR')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('Order ID: $orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(
            padding: const EdgeInsets.all(20),
            child: QrImageView(data: qrData, size: 240),
          )),
          const SizedBox(height: 12),
          const Text('Show this QR to the rider for delivery confirmation'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // copy to clipboard or share - kept simple
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR ready (demo)')));
            },
            child: const Text('Done'),
          )
        ]),
      ),
    );
  }
}