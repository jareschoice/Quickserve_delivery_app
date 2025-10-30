import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:quickride/config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  final String baseUrl;
  AuthService({this.baseUrl = Config.baseUrl});

  Future<String> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final token = data['token'] as String?;
      if (token == null) throw Exception('No token returned');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      return token;
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> registerVendor({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register/vendor'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return true;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(data['error'] ?? 'Registration failed');
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception(data['error'] ?? 'Resend failed');
  }
}
