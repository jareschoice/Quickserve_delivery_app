import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/event/event_service.dart';
import '../../services/socket_service.dart';

/// Order tracking screen with real-time status updates
class EventTrackingScreen extends StatefulWidget {
  final String orderId;

  const EventTrackingScreen({super.key, required this.orderId});

  @override
  State<EventTrackingScreen> createState() => _EventTrackingScreenState();
}

class _EventTrackingScreenState extends State<EventTrackingScreen> {
  final EventService _eventService = EventService();
  EventOrder? _order;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _startAutoRefresh();
    _listenToSocket();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _cleanupSocketListeners();
    super.dispose();
  }

  void _cleanupSocketListeners() {
    final socket = SocketService().socket;
    if (socket == null) return;

    // Leave order rooms
    socket.emit('leave', 'order:${widget.orderId}');
    socket.emit('leave', 'order_${widget.orderId}');

    // Remove all order event listeners
    final orderEvents = [
      'order:placed',
      'order:accepted',
      'order:preparing',
      'order:ready',
      'order:assigned',
      'order:delivered',
      'order:in_transit',
      'order:arrived',
      'order:vendor_ready',
    ];

    for (final event in orderEvents) {
      socket.off(event);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOrder();
    });
  }

  void _listenToSocket() {
    final socket = SocketService().socket;
    if (socket == null) return;

    // Join order room
    socket.emit('join', 'order:${widget.orderId}');
    socket.emit('join', 'order_${widget.orderId}');

    // Listen for all order status events from backend
    final orderEvents = [
      'order:placed',
      'order:accepted',
      'order:preparing',
      'order:ready',
      'order:assigned',
      'order:delivered',
      'order:in_transit',
      'order:arrived',
      'order:vendor_ready',
    ];

    for (final event in orderEvents) {
      socket.on(event, (data) {
        debugPrint('Socket event: $event - $data');
        final orderId = data['orderId']?.toString() ?? data['_id']?.toString();
        if (orderId == widget.orderId) {
          _loadOrder();
        }
      });
    }
  }

  Future<void> _loadOrder() async {
    final order = await _eventService.trackOrder(widget.orderId);

    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
        _error = order == null ? 'Order not found' : null;
      });
    }
  }

  int get _statusStep {
    switch (_order?.status) {
      case 'pending':
        return 0;
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'out_for_delivery':
        return 4;
      case 'delivered':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrder),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : _buildTrackingContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadOrder,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingContent() {
    final order = _order!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  order.statusColor,
                  order.statusColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.statusDisplay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(order.id.length - 6)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status Timeline
          const Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          _StatusTimeline(currentStep: _statusStep),

          const SizedBox(height: 24),

          // QR Code (for delivery confirmation)
          if (order.status != 'delivered' && order.status != 'cancelled') ...[
            const Text(
              'Delivery QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Show this to the dispatcher to confirm delivery',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: '${order.id}:${order.seatNumber}',
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  embeddedImage: null,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Order Details
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Seat/Location',
                  value: order.seatNumber,
                ),
                const Divider(height: 24),
                _DetailRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: order.phone,
                ),
                if (order.vendorName != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.store,
                    label: 'Vendor',
                    value: order.vendorName!,
                  ),
                ],
                if (order.dispatcherName != null) ...[
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.delivery_dining,
                    label: 'Dispatcher',
                    value: order.dispatcherName!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Order Items
          const Text(
            'Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${item.quantity}x',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '₦${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₦${order.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Charge',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      '₦${order.serviceCharge.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₦${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Payment Status
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: order.paid
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  order.paid ? Icons.check_circle : Icons.pending,
                  color: order.paid ? const Color(0xFF4CAF50) : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  order.paid ? 'Payment Confirmed' : 'Payment Pending',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: order.paid ? const Color(0xFF4CAF50) : Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.thumb_up;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.check_circle;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}

class _StatusTimeline extends StatelessWidget {
  final int currentStep;

  const _StatusTimeline({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Pending', Icons.hourglass_empty),
      ('Accepted', Icons.thumb_up),
      ('Preparing', Icons.restaurant),
      ('Ready', Icons.check_circle),
      ('Delivering', Icons.delivery_dining),
      ('Delivered', Icons.done_all),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFFFF6B00)
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    steps[index].$2,
                    color: isCompleted ? Colors.white : Colors.grey[500],
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted
                        ? const Color(0xFFFF6B00)
                        : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps[index].$1,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompleted
                            ? const Color(0xFF333333)
                            : Colors.grey[500],
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        'Current status',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    SizedBox(height: isLast ? 0 : 24),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF6B00)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
