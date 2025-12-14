import 'package:flutter/material.dart';

class QLogoWidget extends StatelessWidget {
  final double size;
  final Color primary;
  final Color accent;
  const QLogoWidget({
    super.key,
    this.size = 100,
    this.primary = const Color(0xFFFF6B00),
    this.accent = const Color(0xFFFFD700),
  });

  @override
  Widget build(BuildContext context) {
    final double outer = size;
    final double inner = size * 0.62;
    final double notch = size * 0.26;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // outer circle
          Container(
            width: outer,
            height: outer,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
          // inner cutout to create stylized Q tail
          Positioned(
            right: -size * 0.05,
            child: Container(
              width: inner,
              height: inner,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
            ),
          ),
          // tail notch to form the Q's tail
          Positioned(
            right: size * 0.18,
            bottom: size * 0.18,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: notch,
                height: notch * 0.6,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(notch * 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
