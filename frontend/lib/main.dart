import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/home/vendor_home.dart';
import 'screens/home/rider_home.dart';
import 'screens/home/place_order.dart';
import 'screens/splash/splash_screen.dart'; // Your custom splash screen
import 'models/user.dart';
import 'services/socket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService().connect();
  runApp(const QuickServeApp());
}

class QuickServeApp extends StatelessWidget {
  const QuickServeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickServe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home:
          const CustomSplashScreen(), // Use your custom designed splash screen
      routes: {
        '/auth': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/verify': (_) => const VerifyEmailScreen(email: ''),
        '/place-order': (_) => const PlaceOrderScreen(),
        '/home': (_) => const RoleHomeDecider(),
      },
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});
  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Show your beautiful splash for 6 seconds like you requested
    await Future.delayed(const Duration(seconds: 6));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      // If not logged in, show your custom onboarding first
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use your designed splash screen layout
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Your watermark background
          Image.asset(
            'assets/images/Quickserve_logo.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.15),
            colorBlendMode: BlendMode.darken,
          ),
          // Center content with your branding
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/Quickserve_icon.jpg', height: 100),
                const SizedBox(height: 16),
                const Text(
                  "QuickServe",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks the correct home by saved role (consumer/vendor/rider).
class RoleHomeDecider extends StatelessWidget {
  const RoleHomeDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final roleStr = snap.data!.getString('role');
        final role = roleFromString(roleStr) ?? UserRole.consumer;
        switch (role) {
          case UserRole.consumer:
            // Return the main navigation widget (includes bottom nav and app screens)
            return const MainNavigation();
          case UserRole.vendor:
            return const VendorHome();
          case UserRole.rider:
            return const RiderHome();
          case UserRole.admin:
            // show simple placeholder for now
            return const Scaffold(
              body: Center(child: Text('Admin Dashboard (coming soon)')),
            );
        }
      },
    );
  }
}
