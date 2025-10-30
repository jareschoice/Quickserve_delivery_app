import 'package:flutter/material.dart';
import 'package:quickride/screens/auth/login_screen.dart';
import 'package:quickride/screens/dashboard/main_nav.dart';
import 'package:quickride/screens/products/product_form_page.dart';
import 'package:quickride/screens/auth/signup_screen.dart';
import 'package:quickride/screens/splash/splash_screen.dart';

void main() {
  runApp(const QuickRideApp());
}

class QuickRideApp extends StatelessWidget {
  const QuickRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickVendor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      // Splash then route to auth
      home: const VendorSplashScreen(),
      routes: {
        '/auth': (_) => const LoginScreen(),
        '/dashboard': (_) => const MainNav(),
        '/products/new': (_) => const ProductFormPage(),
        '/signup': (_) => const SignupScreen(),
      },
    );
  }
}
