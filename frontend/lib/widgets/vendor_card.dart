// lib/widgets/vendor_card.dart
import 'package:flutter/material.dart';

class VendorCard extends StatelessWidget {
  final String id;
  final String name;
  final String image;
  final String eta;
  final double rating;
  final String? availabilityStatus; // open, closed, busy
  final Map<String, dynamic>? operatingHours;
  final VoidCallback onTap;

  const VendorCard({
    super.key,
    required this.id,
    required this.name,
    required this.image,
    required this.eta,
    required this.rating,
    this.availabilityStatus,
    this.operatingHours,
    required this.onTap,
  });

  // Check if store is currently open based on operating hours
  bool _isCurrentlyOpen() {
    if (availabilityStatus == 'closed') return false;
    if (operatingHours == null) return availabilityStatus != 'closed';

    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final today = dayNames[now.weekday - 1];
    final todayHours = operatingHours![today] as Map<String, dynamic>?;

    if (todayHours == null) return true;
    if (todayHours['isOpen'] == false) return false;

    final openTime = todayHours['open'] as String? ?? '09:00';
    final closeTime = todayHours['close'] as String? ?? '21:00';

    final openParts = openTime.split(':');
    final closeParts = closeTime.split(':');

    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes =
        int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    final currentMinutes = now.hour * 60 + now.minute;

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  String _getTodayHours() {
    if (operatingHours == null) return '';

    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final today = dayNames[now.weekday - 1];
    final todayHours = operatingHours![today] as Map<String, dynamic>?;

    if (todayHours == null) return '';
    if (todayHours['isOpen'] == false) return 'Closed today';

    final openTime = todayHours['open'] as String? ?? '09:00';
    final closeTime = todayHours['close'] as String? ?? '21:00';

    return '$openTime - $closeTime';
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _isCurrentlyOpen();
    final todayHours = _getTodayHours();
    final statusColor = availabilityStatus == 'busy'
        ? Colors.orange
        : isOpen
        ? Colors.green
        : Colors.red;
    final statusText = availabilityStatus == 'busy'
        ? 'Busy'
        : isOpen
        ? 'Open'
        : 'Closed';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Store image with status indicator
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.store, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Status dot
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Store info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          eta,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (todayHours.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            todayHours,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
