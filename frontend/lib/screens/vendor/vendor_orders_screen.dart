import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> {
  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final res = await ApiClient.I.get('/api/orders/mine', auth: true);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items;
  }

  Future<void> _accept(String id) async {
    await ApiClient.I.post('/api/orders/$id/accept', {}, auth: true);
    setState(() {});
  }

  Future<void> _pack(String id) async {
    String? selected;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select packaging'),
          content: StatefulBuilder(
            builder: (context, setSt) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final opt in const [
                    'big',
                    'small',
                    'ordinary',
                    'customized',
                  ])
                    RadioListTile<String>(
                      title: Text(opt.toUpperCase()),
                      value: opt,
                      groupValue: selected,
                      onChanged: (v) => setSt(() => selected = v),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      await ApiClient.I.post('/api/orders/$id/pack', {
                        'packagingChoice': selected,
                      }, auth: true);
                      if (mounted) Navigator.pop(ctx);
                    },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Orders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final orders = snap.data ?? const [];
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final o = orders[i];
              final id = o['_id']?.toString() ?? '';
              final status = o['status']?.toString() ?? '';
              final total = o['total']?.toString() ?? '';
              return ListTile(
                title: Text('Order $id'),
                subtitle: Text('Status: $status  •  Total: ₦$total'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'placed')
                      TextButton(
                        onPressed: () => _accept(id),
                        child: const Text('Accept'),
                      ),
                    if (status == 'accepted' || status == 'preparing')
                      ElevatedButton(
                        onPressed: () => _pack(id),
                        child: const Text('Pack'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
