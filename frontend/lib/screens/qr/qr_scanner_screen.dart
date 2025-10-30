// lib/screens/qr/qr_scanner_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../services/api_client.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool processed = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController ctrl) {
    controller = ctrl;
    ctrl.scannedDataStream.listen((scanData) async {
      if (processed) return;
      processed = true;
      final raw = scanData.code ?? '';
      // Raw is encoded query string from generator (eg: ?orderId=...&token=...)
      // Parse basic form:
      final uri = Uri.tryParse(raw);
      String orderId = '';
      String token = '';
      if (uri != null && uri.queryParameters.isNotEmpty) {
        orderId = uri.queryParameters['orderId'] ?? '';
        token = uri.queryParameters['token'] ?? '';
      } else {
        // try splitting by delimiters
        final parts = raw.split(RegExp(r'[:;,]'));
        if (parts.isNotEmpty) token = parts.last;
      }

      if (orderId.isEmpty && token.isEmpty) {
        // show raw
        await _showResult('Scanned', raw);
        processed = false;
        return;
      }

      // call API to confirm delivery (real) or simulate (mock)
      try {
        final res = await ApiClient().confirmDelivery(orderId, token);
        final ok = res['ok'] == true;
        await _showResult(ok ? 'Delivery confirmed' : 'Confirm failed', res.toString());
      } catch (e) {
        await _showResult('Error', e.toString());
      } finally {
        processed = false;
      }
    });
  }

  Future<void> _showResult(String title, String message) async {
    if (!mounted) return;
    await showDialog(context: context, builder: (_) => AlertDialog(title: Text(title), content: Text(message), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Column(children: [
        Expanded(flex: 4, child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated)),
        Expanded(flex: 1, child: Center(child: Text('Point the camera at the order QR to confirm delivery')))
      ]),
    );
  }
}