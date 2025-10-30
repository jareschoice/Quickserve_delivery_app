import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  String get base => AppConfig.backendBaseUrl;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _u(String path) => Uri.parse('$base$path');

  Future<http.Response> get(String path, {bool auth = false}) async {
    return await http.get(_u(path), headers: await _headers(auth: auth));
  }

  Future<http.Response> post(String path, Map body, {bool auth = false}) async {
    return await http.post(_u(path),
        headers: await _headers(auth: auth), body: jsonEncode(body));
  }
}
