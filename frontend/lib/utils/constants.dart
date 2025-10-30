// lib/utils/constants.dart

import 'package:flutter/material.dart';

// 🔹 Base API configuration
// Leave blank or local IP (e.g. 'http://192.168.138.104:5000')
const String kApiBase = '';

// Toggle mock API mode (true if no backend available)
bool get useMock => kApiBase.trim().isEmpty;

// 🔹 App configuration constants
class AppConfig {
  static const appName = 'QuickServe';
  static const currency = '₦';
  static const serviceCharge = 50;

  static bool? get useMockApi => null;

  static get apiBaseUrl => null; // Default service charge
}

// 🔹 Color palette
class AppColors {
  static const Color primary = Color(0xFF008000); // Green
  static const Color accent = Color(0xFFFF9800); // Orange
  static const Color danger = Color(0xFFE53935); // Red
  static const Color gold = Color(0xFFFFD700);
  static const Color cream = Color(0xFFFDF3E7);
}

// 🔹 Text styles
class AppTextStyle {
  static const heading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static const subText = TextStyle(fontSize: 14, color: Colors.grey);

  static const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
