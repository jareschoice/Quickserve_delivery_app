import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart' as app_main;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('role', 'vendor');
  // Persist API base override from dart-define if provided for faster LAN testing
  const envBase = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
  if (envBase.isNotEmpty) {
    await prefs.setString('api_base_override', envBase);
  }
  runApp(const app_main.QuickServeApp());
}
