import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

/// Animated Clock Banner Widget for QuickServe Special Meal
/// Features a ticking clock icon that shows real-time seconds
class AnimatedClockBanner extends StatefulWidget {
  final VoidCallback? onTap;

  const AnimatedClockBanner({super.key, this.onTap});

  @override
  State<AnimatedClockBanner> createState() => _AnimatedClockBannerState();
}

class _AnimatedClockBannerState extends State<AnimatedClockBanner>
    with TickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Update time every second for ticking effect
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Pulse animation for the glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B00),
                  const Color(0xFFFF8C00),
                  const Color(0xFFFFB366),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFFFF6B00,
                  ).withValues(alpha: 0.3 * _pulseAnimation.value),
                  blurRadius: 15 * _pulseAnimation.value,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left side: Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '‰ ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _buildWordmark(),
                          const SizedBox(width: 8),
                          const Text(
                            'Special Meal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Animated ticking clock
                          _buildTickingClock(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Subscribe & Save! Affordable meals delivered daily',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap to Subscribe â†’',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Right side: Large animated clock display
                _buildClockDisplay(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTickingClock() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated clock icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.rotate(
                angle:
                    value * 0.1 * math.sin(_currentTime.second * math.pi / 30),
                child: const Icon(
                  Icons.access_time_filled,
                  color: Colors.white,
                  size: 16,
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          // Time display with seconds ticking
          Text(
            _formatTime(_currentTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockDisplay() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clock face
          CustomPaint(
            size: const Size(60, 60),
            painter: _ClockPainter(_currentTime),
          ),
          // Center dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  RichText _buildWordmark() {
    const colors = [
      Color(0xFF4285F4), // Blue
      Color(0xFFDB4437), // Red
      Color(0xFFF4B400), // Yellow
      Color(0xFF4285F4), // Blue
      Color(0xFF0F9D58), // Green
      Color(0xFFDB4437), // Red
      Color(0xFF4285F4), // Blue
      Color(0xFFF4B400), // Yellow
      Color(0xFF0F9D58), // Green
      Color(0xFFDB4437), // Red
    ];

    const text = 'QuickServe';
    final spans = <TextSpan>[];
    for (var i = 0; i < text.length; i++) {
      spans.add(
        TextSpan(
          text: text[i],
          style: TextStyle(
            color: colors[i % colors.length],
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

/// Custom painter for analog clock face
class _ClockPainter extends CustomPainter {
  final DateTime time;

  _ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw hour markers
    final markerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final outerPoint = Offset(
        center.dx + (radius - 3) * math.cos(angle),
        center.dy + (radius - 3) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      canvas.drawLine(innerPoint, outerPoint, markerPaint);
    }

    // Hour hand
    final hourAngle =
        ((time.hour % 12) * 30 + time.minute * 0.5 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.4 * math.cos(hourAngle),
        center.dy + radius * 0.4 * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute hand
    final minuteAngle = (time.minute * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.6 * math.cos(minuteAngle),
        center.dy + radius * 0.6 * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // Second hand (with smooth movement)
    final secondAngle = (time.second * 6 - 90) * math.pi / 180;
    final secondPaint = Paint()
      ..color =
          const Color(0xFFFFD700) // Gold color for seconds
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.7 * math.cos(secondAngle),
        center.dy + radius * 0.7 * math.sin(secondAngle),
      ),
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) => true;
}
