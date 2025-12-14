// lib/screens/qr/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_client.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool processed = false;
  MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) async {
    if (processed) return;
    processed = true;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      processed = false;
      return;
    }
    final raw = barcodes.first.rawValue ?? '';
    final uri = Uri.tryParse(raw);
    String orderId = '';
    String token = '';
    if (uri != null && uri.queryParameters.isNotEmpty) {
      orderId = uri.queryParameters['orderId'] ?? '';
      token = uri.queryParameters['token'] ?? '';
    } else {
      final parts = raw.split(RegExp(r'[:;,]'));
      if (parts.isNotEmpty) token = parts.last;
    }
    if (orderId.isEmpty && token.isEmpty) {
      await _showResult('Scanned', raw);
      processed = false;
      return;
    }
    try {
      final res = await ApiClient().confirmDelivery(orderId, token);
      final ok = res['ok'] == true;
      await _showResult(
        ok ? 'Delivery confirmed' : 'Confirm failed',
        res.toString(),
      );
    } catch (e) {
      await _showResult('Error', e.toString());
    } finally {
      processed = false;
    }
  }

  Future<void> _showResult(String title, String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(controller: controller, onDetect: _onDetect),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Point the camera at the order QR to confirm delivery',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
