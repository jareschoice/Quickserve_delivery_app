import 'package:flutter/material.dart';
import '../vendor/vendor_dashboard.dart';
import '../../widgets/background_wrapper.dart';

class VendorHome extends StatelessWidget {
  const VendorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: const VendorDashboard(),
    );
  }
}
