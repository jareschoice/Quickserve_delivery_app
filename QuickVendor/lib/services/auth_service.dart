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
      Uri.parse('$baseUrl/auth/login'),
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
}
