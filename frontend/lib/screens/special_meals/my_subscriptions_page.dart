import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';

/// My Subscriptions Page - Shows user's subscription history
class MySubscriptionsPage extends StatefulWidget {
  const MySubscriptionsPage({super.key});

  @override
  State<MySubscriptionsPage> createState() => _MySubscriptionsPageState();
}

class _MySubscriptionsPageState extends State<MySubscriptionsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _subscriptions = [];
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiClient().getJson('/api/subscriptions/mine');
      final items = (data['items'] as List?) ?? [];
      setState(() {
        _subscriptions = items
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'paused':
        return Colors.blue;
      case 'cancelled':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'paused':
        return Icons.pause_circle;
      case 'cancelled':
      case 'expired':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatPlanName(Map<String, dynamic> sub) {
    final plan = sub['plan'] ?? sub['planType'] ?? 'Basic';
    final category = sub['category'] ?? 'corporate';
    return '${category.toString().toUpperCase()} - ${plan.toString().toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubscriptions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_subscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No subscriptions yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to a meal plan to get started!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/special-meals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Meal Plans'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubscriptions,
      color: const Color(0xFFFF6B00),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _subscriptions.length,
        itemBuilder: (context, index) {
          final sub = _subscriptions[index];
          return _buildSubscriptionCard(sub);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final status = (sub['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final amount = (sub['amount'] ?? 0).toDouble();
    final billingCycle = sub['billingCycle'] ?? 'monthly';
    final periodStart = sub['periodStart'] != null
        ? DateTime.tryParse(sub['periodStart'].toString())
        : null;
    final periodEnd = sub['periodEnd'] != null
        ? DateTime.tryParse(sub['periodEnd'].toString())
        : null;
    final deliveryAddress = sub['deliveryAddress'] ?? 'Not specified';
    final selectedSessions = (sub['selectedSessions'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewSubscriptionDetails(sub),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with plan name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatPlanName(sub),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Amount and billing cycle
              Row(
                children: [
                  Icon(Icons.payments, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'NGN ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  Text(
                    ' / $billingCycle',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Period
              if (periodStart != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_dateFormat.format(periodStart)} - ${periodEnd != null ? _dateFormat.format(periodEnd) : 'Ongoing'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Sessions
              if (selectedSessions.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: selectedSessions.map((session) {
                          return Chip(
                            label: Text(
                              session.toString().toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.1),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),

              // Delivery address
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliveryAddress.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewSubscriptionDetails(sub),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B00),
                    ),
                  ),
                  if (status == 'active')
                    TextButton.icon(
                      onPressed: () => _downloadSchedule(sub),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewSubscriptionDetails(Map<String, dynamic> sub) {
    // Convert backend subscription to SubscriptionOrder model if possible
    // For now, just show a details dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailsSheet(sub),
    );
  }

  Widget _buildDetailsSheet(Map<String, dynamic> sub) {
    final status = (sub['status'] ?? 'pending').toString();
    final statusColor = _getStatusColor(status);
    final amount = (sub['amount'] ?? 0).toDouble();
    final billingCycle = sub['billingCycle'] ?? 'monthly';
    final deliveryAddress = sub['deliveryAddress'] ?? 'Not specified';
    final selectedMeals = (sub['selectedMeals'] as List?) ?? [];
    final mealSchedule = sub['mealSchedule'] as Map<String, dynamic>? ?? {};
    final autoRenew = sub['autoRenew'] == true;
    final createdAt = sub['createdAt'] != null
        ? DateTime.tryParse(sub['createdAt'].toString())
        : null;
    final periodStart = sub['periodStart'] != null
        ? DateTime.tryParse(sub['periodStart'].toString())
        : null;
    final periodEnd = sub['periodEnd'] != null
        ? DateTime.tryParse(sub['periodEnd'].toString())
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subscription Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Plan info
              _buildDetailRow('Plan', _formatPlanName(sub)),
              _buildDetailRow(
                'Amount',
                'NGN ${amount.toStringAsFixed(0)} / $billingCycle',
              ),
              _buildDetailRow('Auto Renew', autoRenew ? 'Yes' : 'No'),
              if (createdAt != null)
                _buildDetailRow('Created', _dateFormat.format(createdAt)),
              if (periodStart != null)
                _buildDetailRow('Start Date', _dateFormat.format(periodStart)),
              if (periodEnd != null)
                _buildDetailRow('End Date', _dateFormat.format(periodEnd)),
              _buildDetailRow('Delivery Address', deliveryAddress.toString()),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Meal Schedule
              const Text(
                'Meal Schedule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...mealSchedule.entries.map((entry) {
                final session = entry.key;
                final data = entry.value as Map<String, dynamic>? ?? {};
                final enabled = data['enabled'] == true;
                final time = data['time'] ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        enabled ? Icons.check_circle : Icons.cancel,
                        color: enabled ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${session.toString().toUpperCase()}${enabled ? " - $time" : ""}',
                        style: TextStyle(
                          color: enabled ? Colors.black : Colors.grey,
                          decoration: enabled
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              if (selectedMeals.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Selected Meals
                const Text(
                  'Selected Meals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...selectedMeals.map((meal) {
                  final menuItem = meal['menuItem'] ?? 'Unknown';
                  final protein = meal['protein'] ?? '';
                  final session = meal['session'] ?? '';
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.restaurant,
                        color: Color(0xFFFF6B00),
                      ),
                      title: Text(menuItem.toString()),
                      subtitle: Text(
                        '$session${protein.isNotEmpty ? " • $protein" : ""}',
                      ),
                    ),
                  );
                }),
              ],

              // Delivery History section
              _buildDeliveryHistorySection(sub),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadSchedule(sub),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B00),
                        side: const BorderSide(color: Color(0xFFFF6B00)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _emailSchedule(sub),
                      icon: const Icon(Icons.email),
                      label: const Text('Email'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHistorySection(Map<String, dynamic> sub) {
    final deliveryHistory = (sub['deliveryHistory'] as List?) ?? [];

    if (deliveryHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort by date descending (most recent first)
    final sortedHistory =
        List<Map<String, dynamic>>.from(
          deliveryHistory.map((e) => Map<String, dynamic>.from(e)),
        )..sort((a, b) {
          final dateA = a['deliveredAt'] ?? a['date'] ?? '';
          final dateB = b['deliveredAt'] ?? b['date'] ?? '';
          return dateB.toString().compareTo(dateA.toString());
        });

    // Group by date
    final groupedByDate = <String, List<Map<String, dynamic>>>{};
    for (final delivery in sortedHistory) {
      final date =
          delivery['date'] ??
          (delivery['deliveredAt'] != null
              ? DateTime.tryParse(
                  delivery['deliveredAt'].toString(),
                )?.toIso8601String().split('T')[0]
              : 'Unknown');
      groupedByDate.putIfAbsent(date, () => []).add(delivery);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Delivery History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${deliveryHistory.length} deliveries',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Show last 10 deliveries
        ...groupedByDate.entries.take(5).map((entry) {
          final date = entry.key;
          final deliveries = entry.value;

          DateTime? parsedDate;
          try {
            parsedDate = DateTime.parse(date);
          } catch (_) {}

          final formattedDate = parsedDate != null
              ? _dateFormat.format(parsedDate)
              : date;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ...deliveries.map((delivery) {
                final session = delivery['session'] ?? 'meal';
                final scheduledTime = delivery['scheduledTime'] ?? '';
                final status = delivery['status'] ?? 'delivered';
                final deliveredAt = delivery['deliveredAt'] != null
                    ? DateTime.tryParse(delivery['deliveredAt'].toString())
                    : null;

                final timeString = deliveredAt != null
                    ? DateFormat('h:mm a').format(deliveredAt)
                    : scheduledTime;

                IconData sessionIcon;
                switch (session.toString().toLowerCase()) {
                  case 'breakfast':
                    sessionIcon = Icons.free_breakfast;
                    break;
                  case 'lunch':
                    sessionIcon = Icons.lunch_dining;
                    break;
                  case 'dinner':
                    sessionIcon = Icons.dinner_dining;
                    break;
                  default:
                    sessionIcon = Icons.restaurant;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'delivered'
                        ? Colors.green.withValues(alpha: 0.05)
                        : Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: status == 'delivered'
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sessionIcon,
                        size: 20,
                        color: const Color(0xFFFF6B00),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session.toString().toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        timeString,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        status == 'delivered'
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 16,
                        color: status == 'delivered'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),

        if (deliveryHistory.length > 15)
          Center(
            child: TextButton(
              onPressed: () {
                // Show all deliveries in a bottom sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.7,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) => Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Full Delivery History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: deliveryHistory.length,
                            itemBuilder: (context, index) {
                              final delivery =
                                  deliveryHistory[index]
                                      as Map<String, dynamic>;
                              final date = DateTime.tryParse(
                                delivery['deliveredAt']?.toString() ?? '',
                              );
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFFFF6B00,
                                  ).withValues(alpha: 0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B00),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(delivery['mealName'] ?? 'Meal'),
                                subtitle: Text(
                                  date != null
                                      ? '${date.day}/${date.month}/${date.year}'
                                      : 'Date N/A',
                                ),
                                trailing: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Text(
                'View all ${deliveryHistory.length} deliveries',
                style: const TextStyle(color: Color(0xFFFF6B00)),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _downloadSchedule(Map<String, dynamic> sub) async {
    // Generate text summary and copy to clipboard
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('   QUICKSERVE MEAL SUBSCRIPTION');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('PLAN: ${_formatPlanName(sub)}');
    buffer.writeln(
      'STATUS: ${sub['status']?.toString().toUpperCase() ?? "N/A"}',
    );
    buffer.writeln('AMOUNT: NGN ${sub['amount']} / ${sub['billingCycle']}');
    buffer.writeln('DELIVERY: ${sub['deliveryAddress']}');
    buffer.writeln();
    buffer.writeln('MEAL SCHEDULE:');

    final mealSchedule = sub['mealSchedule'] as Map<String, dynamic>? ?? {};
    for (final entry in mealSchedule.entries) {
      final data = entry.value as Map<String, dynamic>? ?? {};
      if (data['enabled'] == true) {
        buffer.writeln('  • ${entry.key.toUpperCase()}: ${data['time']}');
      }
    }

    final selectedMeals = (sub['selectedMeals'] as List?) ?? [];
    if (selectedMeals.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('SELECTED MEALS:');
      for (final meal in selectedMeals) {
        final menuItem = meal['menuItem'] ?? 'Unknown';
        final protein = meal['protein'] ?? '';
        final session = meal['session'] ?? '';
        buffer.writeln(
          '  • $menuItem ($session)${protein.isNotEmpty ? " - $protein" : ""}',
        );
      }
    }

    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Thank you for choosing QuickServe!');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.content_copy, color: Colors.white),
              SizedBox(width: 12),
              Text('Schedule copied to clipboard'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _emailSchedule(Map<String, dynamic> sub) async {
    try {
      await ApiClient().postJson('/api/subscriptions/email-summary', {
        'subscriptionId': sub['_id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.email, color: Colors.white),
                SizedBox(width: 12),
                Text('Schedule sent to your email'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
