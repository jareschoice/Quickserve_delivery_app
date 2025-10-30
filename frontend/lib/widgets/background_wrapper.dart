// lib/widgets/background_wrapper.dart
import 'package:flutter/material.dart';

/// Put this widget at the root of any screen to show the Quickserve watermark
/// behind the screen's Scaffold/content.
/// Usage:
///   return BackgroundWrapper(child: Scaffold(...));
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BackgroundWrapper({
    super.key,
    required this.child,
    this.opacity = 0.09, // default watermark opacity
  });

    @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Quickserve_logo.jpg'),
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          opacity: 0.1,
        ),
      ),
      child: child,
    );
  }
}