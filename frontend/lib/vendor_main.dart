import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart' as app_main;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('role', 'vendor');

  // ALWAYS update the API base override from dart-define when provided
  // This ensures old cached IPs are replaced on every run
  const envBase = String.fromEnvironment('BACKEND_BASE_URL', defaultValue: '');
  if (envBase.isNotEmpty) {
    await prefs.setString('api_base_override', envBase);
    debugPrint('VENDOR: Force-updated API base to: $envBase');
  } else {
    // Clear any old override if no BACKEND_BASE_URL is provided
    await prefs.remove('api_base_override');
    debugPrint('VENDOR: Cleared API base override (using production default)');
  }
  runApp(const app_main.QuickServeApp());
}
