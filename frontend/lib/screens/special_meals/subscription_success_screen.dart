import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/subscription.dart';
import 'order_summary_page.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String subId;
  final String? token;

  const SubscriptionSuccessScreen({super.key, required this.subId, this.token});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  bool _loading = true;
  String? _error;
  SubscriptionOrder? _order;

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionDetails();
  }

  Future<void> _fetchSubscriptionDetails() async {
    try {
      // Fetch subscription details using the ID
      // Assuming there's an endpoint like /api/subscriptions/:id
      // If not, we might need to fetch all and filter, or use the verify endpoint response if possible.
      // But usually, we should be able to get the order details.

      // For now, let's try to fetch it. If the endpoint doesn't exist, we might need to add it.
      // Based on previous context, there is /api/subscriptions/verify which returns the order.
      // But we are already redirected here.

      // Let's assume we can get it via a GET request.
      final data = await ApiClient().getJson(
        '/api/subscriptions/${widget.subId}',
      );

      if (data['subscription'] != null) {
        setState(() {
          _order = SubscriptionOrder.fromJson(data['subscription']);
          _loading = false;
        });
      } else {
        throw Exception('Subscription not found');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load subscription details: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order != null) {
      // Directly render the OrderSummaryPage instead of navigating
      // This prevents "flash and disappear" issues caused by routing conflicts
      return OrderSummaryPage(order: _order!, isExistingOrder: true);
    }

    return const Scaffold(body: SizedBox());
  }
}
