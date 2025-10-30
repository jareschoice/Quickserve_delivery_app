import 'package:flutter/material.dart';
import 'package:quickride/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final ApiClient _api;
  List<dynamic> _orders = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _api.setToken(token);
    try {
      final list = await _api.getList('/orders/mine');
      if (!mounted) return;
      setState(() => _orders = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pack(String id) async {
    try {
      await _api.post('/vendors/orders/$id/pack', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order packed (₦50 fee charged to admin)')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Pack failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final o = _orders[i] as Map<String, dynamic>;
                    final id = o['_id']?.toString() ?? '';
                    final start = id.length > 6 ? id.length - 6 : 0;
                    return ListTile(
                      title: Text('Order ${id.substring(start)}'),
                      subtitle: Text(
                          'Status: ${o['status']} • Items: ${(o['items'] as List).length} • Total ₦${o['total']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _pack(id),
                        child: const Text('Pack'),
                      ),
                    );
                  },
                ),
    );
  }
}
