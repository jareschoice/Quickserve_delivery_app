// lib/screens/vendors/vendor_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/vendor_card.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  late final List<Map<String, dynamic>> _vendors;

  @override
  void initState() {
    super.initState();
    // use demo list for now
    _vendors = ApiClient.demoVendors();
  }

  void _openVendor(Map<String, dynamic> vendor) {
    Navigator.pushNamed(context, '/vendor-detail', arguments: vendor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _vendors.length,
        itemBuilder: (ctx, i) {
          final v = _vendors[i];
          return VendorCard(
            id: v['id'],
            name: v['name'],
            image: v['image'],
            eta: v['eta'] ?? '25-35 min',
            rating: (v['rating'] as num).toDouble(),
            onTap: () => _openVendor(v),
          );
        },
      ),
    );
  }
}