import 'package:flutter/material.dart';
import 'dart:async';

/// 🕐 Estimated Delivery Time Widget
/// Shows estimated delivery countdown with live updates (Chowdeck/Glovo standard)
class EstimatedDeliveryWidget extends StatefulWidget {
  final DateTime? estimatedTime;
  final String? status;
  final int? prepMins;
  final int? deliveryMins;

  const EstimatedDeliveryWidget({
    super.key,
    this.estimatedTime,
    this.status,
    this.prepMins,
    this.deliveryMins,
  });

  @override
  State<EstimatedDeliveryWidget> createState() =>
      _EstimatedDeliveryWidgetState();
}

class _EstimatedDeliveryWidgetState extends State<EstimatedDeliveryWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (widget.estimatedTime != null) {
      final diff = widget.estimatedTime!.difference(DateTime.now());
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate ETA based on status and prep/delivery times
    final prepMins = widget.prepMins ?? 15;
    final deliveryMins = widget.deliveryMins ?? 20;
    final totalMins = prepMins + deliveryMins;

    String etaText;
    String statusText;
    IconData statusIcon;
    Color statusColor;

    switch (widget.status?.toLowerCase()) {
      case 'placed':
      case 'accepted':
        statusText = 'Order Confirmed';
        statusIcon = Icons.check_circle;
        statusColor = Colors.blue;
        etaText = '$totalMins-${totalMins + 10} mins';
        break;
      case 'preparing':
        statusText = 'Being Prepared';
        statusIcon = Icons.restaurant;
        statusColor = Colors.orange;
        etaText =
            '${prepMins + deliveryMins}-${prepMins + deliveryMins + 10} mins';
        break;
      case 'ready':
      case 'waiting_pickup':
        statusText = 'Ready for Pickup';
        statusIcon = Icons.inventory_2;
        statusColor = Colors.amber;
        etaText = '$deliveryMins-${deliveryMins + 5} mins';
        break;
      case 'assigned':
      case 'dispatch_requested':
        statusText = 'Rider Assigned';
        statusIcon = Icons.delivery_dining;
        statusColor = Colors.purple;
        etaText = '$deliveryMins-${deliveryMins + 10} mins';
        break;
      case 'in_transit':
        statusText = 'On the Way';
        statusIcon = Icons.directions_bike;
        statusColor = Colors.green;
        if (_remaining.inMinutes > 0) {
          etaText = '${_remaining.inMinutes} mins';
        } else {
          etaText = 'Arriving soon!';
        }
        break;
      case 'arrived_customer':
        statusText = 'Rider Arrived';
        statusIcon = Icons.location_on;
        statusColor = Colors.green;
        etaText = 'At your location';
        break;
      case 'delivered':
        statusText = 'Delivered';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        etaText = 'Completed';
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        etaText = 'Order cancelled';
        break;
      default:
        statusText = 'Processing';
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.grey;
        etaText = '$totalMins-${totalMins + 15} mins';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status icon with animation
              _AnimatedStatusIcon(icon: statusIcon, color: statusColor),
              const SizedBox(width: 12),

              // Status and ETA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Estimated: $etaText',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Large ETA display
              if (widget.status != 'delivered' && widget.status != 'cancelled')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    etaText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Progress bar
          if (widget.status != 'delivered' && widget.status != 'cancelled') ...[
            const SizedBox(height: 16),
            _DeliveryProgressBar(status: widget.status ?? 'placed'),
          ],
        ],
      ),
    );
  }
}

class _AnimatedStatusIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _AnimatedStatusIcon({required this.icon, required this.color});

  @override
  State<_AnimatedStatusIcon> createState() => _AnimatedStatusIconState();
}

class _AnimatedStatusIconState extends State<_AnimatedStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.color.withValues(
              alpha: 0.2 + (_controller.value * 0.1),
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: widget.color, size: 28),
        );
      },
    );
  }
}

class _DeliveryProgressBar extends StatelessWidget {
  final String status;

  const _DeliveryProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'key': 'placed', 'label': 'Placed', 'icon': Icons.receipt},
      {'key': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant},
      {'key': 'ready', 'label': 'Ready', 'icon': Icons.inventory_2},
      {'key': 'in_transit', 'label': 'On Way', 'icon': Icons.delivery_dining},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentIndex = _getStageIndex(status);

    return Column(
      children: [
        // Progress line with dots
        Row(
          children: List.generate(stages.length * 2 - 1, (index) {
            if (index.isEven) {
              // Dot
              final stageIndex = index ~/ 2;
              final isCompleted = stageIndex <= currentIndex;
              final isCurrent = stageIndex == currentIndex;

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 3,
                        )
                      : null,
                ),
                child: Icon(
                  stages[stageIndex]['icon'] as IconData,
                  size: 14,
                  color: isCompleted ? Colors.white : Colors.grey[500],
                ),
              );
            } else {
              // Line
              final beforeIndex = index ~/ 2;
              final isCompleted = beforeIndex < currentIndex;

              return Expanded(
                child: Container(
                  height: 3,
                  color: isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),

        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stages.map((stage) {
            final stageIndex = stages.indexOf(stage);
            final isCompleted = stageIndex <= currentIndex;

            return SizedBox(
              width: 50,
              child: Text(
                stage['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: isCompleted
                      ? Theme.of(context).primaryColor
                      : Colors.grey[500],
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  int _getStageIndex(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
      case 'accepted':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
      case 'waiting_pickup':
      case 'assigned':
      case 'dispatch_requested':
        return 2;
      case 'in_transit':
      case 'arrived_customer':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }
}

/// Compact ETA badge for order list items
class ETABadge extends StatelessWidget {
  final int minutes;
  final String? status;

  const ETABadge({super.key, required this.minutes, this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    if (status == 'delivered') {
      bgColor = Colors.green;
      text = 'Delivered';
    } else if (status == 'cancelled') {
      bgColor = Colors.red;
      text = 'Cancelled';
    } else if (minutes <= 0) {
      bgColor = Colors.green;
      text = 'Arriving!';
    } else if (minutes <= 10) {
      bgColor = Colors.green;
      text = '$minutes min';
    } else if (minutes <= 30) {
      bgColor = Colors.orange;
      text = '$minutes min';
    } else {
      bgColor = Colors.blue;
      text = '$minutes min';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status != 'delivered' && status != 'cancelled')
            const Icon(Icons.access_time, size: 14, color: Colors.white),
          if (status != 'delivered' && status != 'cancelled')
            const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
