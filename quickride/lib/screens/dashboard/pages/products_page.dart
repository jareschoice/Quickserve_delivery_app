import 'package:flutter/material.dart';
import 'package:quickride/screens/products/product_form_page.dart';
import 'package:quickride/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ApiClient _api;
  List<dynamic> _products = const [];
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
      final data = await _api.getJson('/api/products/mine');
      final items = (data['items'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _products = items;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormPage()),
          );
          if (!mounted) return;
          _load();
        },
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('No products yet'))
          : ListView.separated(
              itemCount: _products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _products[i] as Map<String, dynamic>;
                return ListTile(
                  leading: p['imageUrl'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            '${_api.baseUrl}${p['imageUrl']}',
                          ),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.image_not_supported),
                        ),
                  title: Text(p['name'] ?? ''),
                  subtitle: Text(
                    '₦${p['price'] ?? ''} • Qty ${p['quantity'] ?? p['stock'] ?? ''}',
                  ),
                );
              },
            ),
    );
  }
}
