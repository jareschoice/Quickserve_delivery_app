import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';

/// VendorOrdersScreen - Real-time order management with Socket.IO
class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  String _vendorId = '';
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorId();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _removeSocketListeners();
    super.dispose();
  }

  Future<void> _loadVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    _vendorId = prefs.getString('vendorId') ?? prefs.getString('userId') ?? '';

    if (_vendorId.isNotEmpty) {
      // Join vendor room for real-time updates
      _socketService.joinRoom('vendor:$_vendorId');
    }

    await _loadOrders();
  }

  void _setupSocketListeners() {
    _socketService.connect();

    // Listen for new orders
    _socketService.on('order:new', (data) {
      debugPrint('Vendor: New order received! Data: $data');
      if (mounted) _loadOrders();
    });

    _socketService.on('order:created', (data) {
      debugPrint('Vendor: Order created. Data: $data');
      if (mounted) _loadOrders();
    });

    // Listen for order updates
    _socketService.on('order:updated', (data) {
      debugPrint('Vendor: Order updated. Data: $data');
      if (mounted) _loadOrders();
    });

    _socketService.on('order:status', (data) {
      debugPrint('Vendor: Order status changed. Data: $data');
      if (mounted) _loadOrders();
    });

    // Listen for dispatch claims
    _socketService.on('order:claimed', (data) {
      debugPrint('Vendor: Order claimed by rider. Data: $data');
      if (mounted) _loadOrders();
    });

    _socketService.on('order:picked_up', (data) {
      debugPrint('Vendor: Order picked up. Data: $data');
      if (mounted) _loadOrders();
    });

    _socketService.on('order:delivered', (data) {
      debugPrint('Vendor: Order delivered. Data: $data');
      if (mounted) _loadOrders();
    });
  }

  void _removeSocketListeners() {
    _socketService.off('order:new');
    _socketService.off('order:created');
    _socketService.off('order:updated');
    _socketService.off('order:status');
    _socketService.off('order:claimed');
    _socketService.off('order:picked_up');
    _socketService.off('order:delivered');

    if (_vendorId.isNotEmpty) {
      _socketService.leaveRoom('vendor:$_vendorId');
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiClient().getJson('/api/orders/mine');
      final orders = (data['items'] ?? data['orders'] ?? []) as List;

      final pending = <Map<String, dynamic>>[];
      final active = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];

      for (var order in orders) {
        final o = order as Map<String, dynamic>;
        final status = (o['status'] ?? '').toString().toLowerCase();

        if (status == 'placed' || status == 'pending') {
          pending.add(o);
        } else if (['delivered', 'completed', 'cancelled'].contains(status)) {
          completed.add(o);
        } else {
          active.add(o);
        }
      }

      // Sort by date descending
      pending.sort(
        (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
      );
      active.sort(
        (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
      );
      completed.sort(
        (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
      );

      setState(() {
        _pendingOrders = pending;
        _activeOrders = active;
        _completedOrders = completed;
        _loading = false;
      });

      // Join order rooms for real-time updates
      for (var order in [...pending, ...active]) {
        final orderId = order['_id']?.toString();
        if (orderId != null) {
          _socketService.joinRoom('order:$orderId');
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await ApiClient().postJson('/api/orders/$orderId/accept', {});

      // Emit socket event
      _socketService.emit('order:accepted', {
        'orderId': orderId,
        'vendorId': _vendorId,
      });

      _showSnackBar('Order accepted!', Colors.green);
      await _loadOrders();
    } catch (e) {
      _showSnackBar('Failed to accept: $e', Colors.red);
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient().postJson('/api/orders/$orderId/reject', {});

        _socketService.emit('order:rejected', {
          'orderId': orderId,
          'vendorId': _vendorId,
        });

        _showSnackBar('Order rejected', Colors.orange);
        await _loadOrders();
      } catch (e) {
        _showSnackBar('Failed to reject: $e', Colors.red);
      }
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await ApiClient().postJson('/api/orders/$orderId/status', {
        'status': status,
      });

      _socketService.emit('order:status', {
        'orderId': orderId,
        'status': status,
        'vendorId': _vendorId,
      });

      _showSnackBar('Order status updated to $status', Colors.green);
      await _loadOrders();
    } catch (e) {
      _showSnackBar('Failed to update: $e', Colors.red);
    }
  }

  Future<void> _packOrder(String orderId) async {
    String? selectedPackaging;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select Packaging'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final opt in ['big', 'small', 'ordinary', 'customized'])
                ListTile(
                  onTap: () => setState(() => selectedPackaging = opt),
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text(opt[0].toUpperCase() + opt.substring(1)),
                  trailing: Icon(
                    selectedPackaging == opt
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedPackaging == opt
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedPackaging == null
                  ? null
                  : () async {
                      try {
                        await ApiClient().postJson(
                          '/api/orders/$orderId/pack',
                          {'packagingChoice': selectedPackaging},
                        );

                        _socketService.emit('order:packed', {
                          'orderId': orderId,
                          'vendorId': _vendorId,
                          'packagingChoice': selectedPackaging,
                        });

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pop(context);

                        if (!mounted) {
                          return;
                        }

                        _showSnackBar(
                          'Order packed and ready for pickup!',
                          Colors.green,
                        );
                        await _loadOrders();
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar('Failed: $e', Colors.red);
                        } else {
                          debugPrint('Pack order failed after dispose: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) {
      debugPrint('Skipped snackbar (widget disposed): $message');
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Orders'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'New (${_pendingOrders.length})'),
            Tab(text: 'Active (${_activeOrders.length})'),
            Tab(text: 'History (${_completedOrders.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(_pendingOrders, type: 'pending'),
                _buildOrderList(_activeOrders, type: 'active'),
                _buildOrderList(_completedOrders, type: 'completed'),
              ],
            ),
    );
  }

  Widget _buildOrderList(
    List<Map<String, dynamic>> orders, {
    required String type,
  }) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending'
                  ? Icons.inbox_outlined
                  : type == 'active'
                  ? Icons.local_shipping_outlined
                  : Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'pending'
                  ? 'No new orders'
                  : type == 'active'
                  ? 'No active orders'
                  : 'No order history',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index], type),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, String type) {
    final orderId = order['_id']?.toString() ?? '';
    final status = order['status'] ?? 'pending';
    final items = order['items'] as List? ?? [];
    final total = order['total'] ?? 0;
    final createdAt = order['createdAt']?.toString() ?? '';
    final customerName = order['consumerId']?['name'] ?? 'Customer';
    final customerPhone =
        order['consumerId']?['phone'] ?? order['phoneNumber'] ?? '';

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatStatus(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (customerPhone.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    customerPhone,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Items
            const Text('Items:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...items
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '${item['qty'] ?? item['quantity'] ?? 1}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item['name'] ?? 'Item')),
                        Text('â‚¦${_formatNumber(item['price'] ?? 0)}'),
                      ],
                    ),
                  ),
                ),
            if (items.length > 3)
              Text(
                '+${items.length - 3} more items',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),

            const SizedBox(height: 12),
            const Divider(),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'â‚¦${_formatNumber(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // Action buttons
            if (type == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectOrder(orderId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _acceptOrder(orderId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            if (type == 'active') ...[
              const SizedBox(height: 16),
              _buildActiveOrderActions(orderId, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderActions(String orderId, String status) {
    final lowerStatus = status.toString().toLowerCase();

    if (lowerStatus == 'accepted') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus(orderId, 'preparing'),
              icon: const Icon(Icons.restaurant),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (lowerStatus == 'preparing') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _packOrder(orderId),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Pack Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (lowerStatus == 'waiting_pickup' || lowerStatus == 'ready') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Waiting for rider pickup',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (lowerStatus == 'picked_up' || lowerStatus == 'in_transit') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_shipping, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Out for delivery',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'placed':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.amber;
      case 'waiting_pickup':
      case 'ready':
        return Colors.purple;
      case 'picked_up':
      case 'in_transit':
        return Colors.indigo;
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatNumber(dynamic number) {
    final n = number is int ? number : int.tryParse(number.toString()) ?? 0;
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
