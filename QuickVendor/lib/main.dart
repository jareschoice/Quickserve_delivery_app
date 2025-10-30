import 'package:flutter/material.dart';
import 'package:quickride/screens/auth/login_screen.dart';
import 'package:quickride/screens/dashboard/main_nav.dart';
import 'package:quickride/screens/products/product_form_page.dart';

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
      // TODO: add persisted auth state, for now always show login
      home: const LoginScreen(),
      routes: {
        '/dashboard': (_) => const MainNav(),
        '/products/new': (_) => const ProductFormPage(),
      },
    );
  }
}
