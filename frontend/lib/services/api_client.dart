// lib/services/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';

/// Default port for the backend
const int kDefaultPort = 5555;

/// List of common LAN IP prefixes to scan for auto-discovery
const List<String> kCommonSubnets = [
  '10.146.51.', // Current Wi-Fi subnet
  '192.168.1.',
  '192.168.0.',
  '192.168.36.',
  '192.168.43.', // Mobile hotspot
  '10.0.0.',
  '10.0.1.',
  '172.16.0.',
];

/// Base URL for the backend API.
/// Uses AppConfig.backendBaseUrl for production or auto-discovery for dev
String get kApiBase => AppConfig.backendBaseUrl;
bool get useMock => false; // Disable mock mode

class ApiClient {
  final String? baseUrl; // preferred base if provided explicitly
  static String? _cachedBaseUrl; // Cache discovered URL
  static DateTime? _cacheTime; // When cache was set
  static const Duration _cacheDuration = Duration(minutes: 5);

  ApiClient({this.baseUrl});

  /// Auto-discover the backend server on the local network
  static Future<String?> discoverBackend() async {
    debugPrint('Auto-discovering backend server...');

    // Try known IPs first (faster)
    final prefs = await SharedPreferences.getInstance();
    final lastKnownIp = prefs.getString('last_known_backend_ip');

    if (lastKnownIp != null) {
      debugPrint('Trying last known IP: $lastKnownIp');
      if (await _tryServer(lastKnownIp)) {
        return lastKnownIp;
      }
    }

    // Scan common subnets
    for (final subnet in kCommonSubnets) {
      debugPrint('Scanning subnet: $subnet*');
      // Try common host IPs first (1, 100-110, 200)
      final priorityHosts = [
        1,
        100,
        101,
        102,
        103,
        104,
        105,
        106,
        107,
        108,
        109,
        110,
        200,
        2,
        10,
        50,
      ];

      // Run parallel checks for speed
      final futures = <Future<String?>>[];
      for (final host in priorityHosts) {
        final ip = '$subnet$host';
        futures.add(_checkServer(ip));
      }

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          // Save for next time
          await prefs.setString('last_known_backend_ip', result);
          debugPrint('Found backend at: $result');
          return result;
        }
      }
    }

    debugPrint('Backend not found on local network');
    return null;
  }

  static Future<String?> _checkServer(String ip) async {
    final url = 'http://$ip:$kDefaultPort';
    if (await _tryServer(url)) {
      return url;
    }
    return null;
  }

  static Future<bool> _tryServer(String baseUrl) async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('clearAuth error: $e');
    }
    return false;
  }

  // Resolve base URL in this order:
  // 1) Explicit constructor arg
  // 2) SharedPreferences override 'api_base_override'
  // 3) Cached discovered URL (if still valid)
  // 4) Compile-time env BACKEND_BASE_URL (kApiBase)
  // 5) Auto-discovery
  Future<String> _resolveBaseUrl() async {
    // 1) Explicit constructor arg
    if (baseUrl != null && baseUrl!.trim().isNotEmpty) return baseUrl!;

    // 2) SharedPreferences override
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString('api_base_override');
      if (override != null && override.trim().isNotEmpty) {
        return override;
      }
    } catch (_) {}

    // 3) Check cache
    if (_cachedBaseUrl != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedBaseUrl!;
      }
    }

    // 4) Compile-time env
    if (kApiBase.isNotEmpty) {
      _cachedBaseUrl = kApiBase;
      _cacheTime = DateTime.now();
      return kApiBase;
    }

    // 5) Auto-discovery
    final discovered = await discoverBackend();
    if (discovered != null) {
      _cachedBaseUrl = discovered;
      _cacheTime = DateTime.now();
      return discovered;
    }

    // Fallback to localhost (won't work on mobile but better than crashing)
    return 'http://localhost:$kDefaultPort';
  }

  /// Force re-discovery of backend (call when connection fails)
  static Future<String?> refreshBackendUrl() async {
    _cachedBaseUrl = null;
    _cacheTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_known_backend_ip');
    return await discoverBackend();
  }

  /// Set a manual backend URL override
  static Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_override', url);
    _cachedBaseUrl = url;
    _cacheTime = DateTime.now();
  }

  /// Get the current backend URL (for display in settings)
  static Future<String> getCurrentBackendUrl() async {
    final client = ApiClient();
    return await client._resolveBaseUrl();
  }

  Future<Map<String, String>> _headers([String? token]) async {
    final h = {'Content-Type': 'application/json'};

    // Get token from storage if not provided
    String? authToken = token;
    if (authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      authToken = prefs.getString('auth_token');
    }

    if (authToken != null && authToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $authToken';
    }
    return h;
  }

  Future<Uri> _buildUri(String path) async {
    final normalized = path.startsWith('/api') ? path : '/api$path';
    final base = await _resolveBaseUrl();
    debugPrint('API BASE => $base');
    return Uri.parse(base + normalized);
  }

  // Static convenience methods (used by screens like rider_chat_screen.dart)
  static Future<Map<String, dynamic>> get(String path, {String? token}) async {
    return ApiClient().getJson(path, token: token);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return ApiClient().postJson(path, body, token: token);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return ApiClient().patchJson(path, body, token: token);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return ApiClient().putJson(path, body, token: token);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    return ApiClient().deleteJson(path, token: token);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map body, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (useMock) return _mockPost(path, body);
    final uri = await _buildUri(path);
    final headers = await _headers(token);
    final res = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (useMock) return _mockGet(path);
    final uri = await _buildUri(path);
    final headers = await _headers(token);
    final res = await http.get(uri, headers: headers).timeout(timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map body, {
    String? token,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = await _buildUri(path);
    final headers = await _headers(token);
    final res = await http
        .patch(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map body, {
    String? token,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = await _buildUri(path);
    final headers = await _headers(token);
    final res = await http
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(timeout);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? token,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = await _buildUri(path);
    final headers = await _headers(token);
    final res = await http.delete(uri, headers: headers).timeout(timeout);
    if (res.body.isEmpty) {
      return {'ok': true};
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    String? token,
    Map<String, String>? fields,
  }) async {
    final uri = await _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    final headers = await _headers(token);
    request.headers.addAll(headers);
    // Remove Content-Type as MultipartRequest sets it automatically
    request.headers.remove('Content-Type');

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadBytes(
    String path,
    List<int> bytes,
    String filename, {
    String fieldName = 'file',
    String? token,
    Map<String, String>? fields,
  }) async {
    final uri = await _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    // Add headers
    final headers = await _headers(token);
    request.headers.addAll(headers);
    request.headers.remove('Content-Type');

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // -------------------------
  // Specific API helpers
  // (adjust endpoints to match your backend when ready)
  // -------------------------
  Future<Map<String, dynamic>> createOrder(Map payload) =>
      postJson('/api/orders', payload);
  Future<Map<String, dynamic>> confirmDelivery(
    String orderId,
    String qrToken,
  ) => postJson('/api/orders/$orderId/confirm-delivery', {'token': qrToken});
  Future<Map<String, dynamic>> getVendors() => getJson('/api/vendors');
  Future<Map<String, dynamic>> getVendor(String id) =>
      getJson('/api/vendors/$id');

  // Get current user profile
  Future<Map<String, dynamic>> me() => getJson('/auth/me');

  /// Get server config (useful for debugging)
  Future<Map<String, dynamic>> getServerConfig() => getJson('/config');

  // -------------------------
  // Mock/demo responses when no backend present
  // -------------------------
  Map<String, dynamic> _mockPost(String path, Map body) {
    if (path.startsWith('/orders')) {
      // create a fake order
      final rnd = Random();
      final id = 'order_${rnd.nextInt(999999)}';
      final qrToken = List.generate(
        12,
        (_) => rnd.nextInt(36).toRadixString(36),
      ).join();
      return {
        'ok': true,
        'order': {
          '_id': id,
          'qrToken': qrToken,
          'status': 'placed',
          'total': body['total'] ?? 0,
        },
      };
    }
    if (path.contains('/confirm')) {
      // accept any qr token for demo
      return {'ok': true, 'message': 'Confirmed (mock)'};
    }
    return {'ok': true, 'data': body};
  }

  Map<String, dynamic> _mockGet(String path) {
    if (path == '/vendors') {
      final vendors = List.generate(6, (i) {
        return {
          'id': 'vendor_${i + 1}',
          'name': 'Food Court ${i + 1}',
          'rating': 4.5,
          'eta': '${20 + i}-${30 + i} min',
          'image':
              'https://source.unsplash.com/random/400x400?restaurant,${i + 1}',
        };
      });
      return {'ok': true, 'vendors': vendors};
    }
    if (path.startsWith('/vendors/')) {
      final id = path.split('/').last;
      return {
        'ok': true,
        'vendor': {
          'id': id,
          'name': 'Food Court X',
          'image': 'https://source.unsplash.com/random/800x400?food',
          'menu': List.generate(
            6,
            (j) => {
              'id': 'item_${j + 1}',
              'name': 'Dish ${j + 1}',
              'price': 500 + j * 250,
              'image': 'https://source.unsplash.com/random/200x200?food,$j',
            },
          ),
        },
      };
    }
    return {'ok': true};
  }

  /// Clear any stored auth state that ApiClient might hold.
  /// The app currently stores token/role/email/fullName in SharedPreferences
  /// (see `AuthService`). Ensure any remaining keys are removed here too.
  Future<void> clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token'); // Use consistent key
      await prefs.remove('role');
      await prefs.remove('email');
      await prefs.remove('fullName');
    } catch (e) {
      // non-fatal
      debugPrint('clearAuth error: $e');
    }
  }

  /// Provide a simple demo vendor list used by the UI when `useMock == true`.
  static List<Map<String, dynamic>> demoVendors() {
    return List.generate(6, (i) {
      return {
        'id': 'vendor_${i + 1}',
        'name': 'Food Court ${i + 1}',
        'rating': 4.5,
        'eta': '${20 + i}-${30 + i} min',
        'image':
            'https://source.unsplash.com/random/400x400?restaurant,${i + 1}',
      };
    });
  }
}
