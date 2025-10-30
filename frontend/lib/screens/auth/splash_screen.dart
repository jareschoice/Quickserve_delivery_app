// lib/screens/auth/splash_screen.dart
// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/user.dart';
import '../home/consumer_home.dart';
import '../home/vendor_home.dart';
import '../home/rider_home.dart';
import '../home/admin_home.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final me = await ApiClient.me();
      if (!mounted) return;
      if (me != null) {
        final role = roleFromString(me['user']?['role']);
        Widget next;
        switch (role) {
          case UserRole.vendor:
            next = const VendorHome();
            break;
          case UserRole.rider:
            next = const RiderHome();
            break;
          case UserRole.admin:
            next = const AdminHome();
            break;
          case UserRole.consumer:
          default:
            next = const ConsumerHome();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => next),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ignore: camel_case_types
class me {}
