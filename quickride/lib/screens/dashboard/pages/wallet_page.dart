import 'package:flutter/material.dart';
import 'package:quickride/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late final ApiClient _api;
  double _balance = 0;
  DateTime? _next;
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
    _api.setToken(prefs.getString('auth_token'));
    try {
      final data = await _api.getJson('/api/vendors/wallet');
      if (!mounted) return;
      setState(() {
        _balance = (data['balance'] as num? ?? 0).toDouble();
        _next = DateTime.tryParse(data['nextEligibleAt']?.toString() ?? '');
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _withdraw() async {
    try {
      await _api.post('/api/vendors/wallet/withdraw', { 'amount': 1000 });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Withdrawal requested')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Withdraw failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
  final eligible = _next == null ? false : DateTime.now().isAfter(_next!);
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet),
                      title: const Text('Balance'),
                      subtitle: Text('₦${_balance.toStringAsFixed(2)}'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: const Text('Withdrawal schedule'),
                      subtitle: Text(
                        _next == null
                            ? 'Scheduling...'
                            : 'Next eligible: $_next',
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: eligible ? _withdraw : null,
                      icon: const Icon(Icons.outbond),
                      label: const Text('Withdraw (weekly)'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
