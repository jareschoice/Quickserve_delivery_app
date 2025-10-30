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
  final Set<String> _seenPending = {};
  bool _showingDialog = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _load();
    // Poll for new pending orders every 10 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return false;
      await _load(silent: true);
      return mounted;
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _api.setToken(token);
    try {
      final data = await _api.getJson('/api/orders/mine');
      final list = (data['items'] as List?) ?? [];
      if (!mounted) return;
      setState(() => _orders = list);
      _maybeNotifyPending(list);
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  void _maybeNotifyPending(List list) {
    if (_showingDialog) return;
    for (final it in list) {
      final m = it as Map<String, dynamic>;
      final id = (m['_id'] ?? '').toString();
      final status = (m['status'] ?? '').toString();
      if (status == 'placed' && !_seenPending.contains(id)) {
        _seenPending.add(id);
        _showAcceptDialog(id);
        break;
      }
    }
  }

  void _showAcceptDialog(String id) {
    _showingDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('New order'),
        content: Text('Order $id received. Accept now?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _showingDialog = false;
              try {
                await _api.post('/api/orders/$id/reject', {});
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Order rejected')));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
              }
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showingDialog = false;
              try {
                await _api.post('/api/orders/$id/accept', {});
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Order accepted')));
                _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Accept failed: $e')));
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Future<void> _pack(String id) async {
    String? choice;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(builder: (context, setSt) {
          return AlertDialog(
            title: const Text('Select packaging'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final opt in const ['big','small','ordinary','customized'])
                  RadioListTile<String>(
                    title: Text(opt.toUpperCase()),
                    value: opt,
                    groupValue: choice,
                    onChanged: (v) => setSt(() => choice = v),
                  )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: choice == null ? null : () async {
                  try {
                    await _api.post('/api/orders/$id/pack', {
                      'packagingChoice': choice,
                    });
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order packed, waiting pickup')),
                    );
                    _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pack failed: $e')),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        });
      },
    );
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
                    'Status: ${o['status']} • Items: ${(o['items'] as List).length} • Total ₦${o['total']}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await _api.post('/api/orders/$id/accept', {});
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order accepted')),
                            );
                            _load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Accept failed: $e')),
                            );
                          }
                        },
                        child: const Text('Accept'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pack(id),
                        child: const Text('Pack'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
