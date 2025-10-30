import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Future<Map<String, dynamic>> _fetchWallet() async {
    final res = await ApiClient.I.get('/api/vendors/wallet', auth: true);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data;
  }

  Future<String?> _withdraw(num amount) async {
    final res = await ApiClient.I.post('/api/vendors/wallet/withdraw', {
      'amount': amount,
    }, auth: true);
    if (res.statusCode == 200) return null;
    try {
      final e = jsonDecode(res.body) as Map<String, dynamic>;
      return e['error']?.toString();
    } catch (_) {
      return 'Withdrawal failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₦');
    final dateFmt = DateFormat.yMMMd().add_jm();
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Wallet")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchWallet(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data ?? {};
          final balance = (data['balance'] ?? 0) as num;
          final canWithdraw = data['canWithdraw'] == true;
          final nextEligibleAtStr = data['nextEligibleAt']?.toString();
          final nextEligibleAt = nextEligibleAtStr != null
              ? DateTime.tryParse(nextEligibleAtStr)
              : null;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: const Text('Current Balance'),
                    subtitle: Text(fmt.format(balance)),
                  ),
                ),
                const SizedBox(height: 12),
                if (!canWithdraw && nextEligibleAt != null)
                  Card(
                    color: Colors.amber.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: const Text('Weekly hold in effect'),
                      subtitle: Text(
                        'Next eligible: ${dateFmt.format(nextEligibleAt)}',
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payments),
                    label: const Text('Withdraw ₦1,000'),
                    onPressed: canWithdraw
                        ? () async {
                            final err = await _withdraw(1000);
                            if (err != null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(err)));
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Withdrawal requested'),
                                ),
                              );
                              setState(() {});
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
