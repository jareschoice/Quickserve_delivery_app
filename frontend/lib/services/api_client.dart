// lib/services/api_client.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL for the backend API.
/// Override at run-time with:
///   --dart-define=BACKEND_BASE_URL=http://192.168.x.x:5555
/// Falls back to production domain when not provided.
const String kApiBase = String.fromEnvironment(
  'BACKEND_BASE_URL',
  defaultValue: 'https://getquickserves.com',
);
bool get useMock => kApiBase.trim().isEmpty;

class ApiClient {
  final String? baseUrl; // preferred base if provided explicitly
  ApiClient({this.baseUrl});

  // Resolve base URL in this order:
  // 1) Explicit constructor arg
  // 2) SharedPreferences override 'api_base_override'
  // 3) Compile-time env BACKEND_BASE_URL (kApiBase)
  Future<String> _resolveBaseUrl() async {
    if (baseUrl != null && baseUrl!.trim().isNotEmpty) return baseUrl!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString('api_base_override');
      if (override != null && override.trim().isNotEmpty) {
        return override;
      }
    } catch (_) {}
    return kApiBase;
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
    // Debug print once per call site; harmless in release
    // ignore: avoid_print
    print('API BASE => $base');
    return Uri.parse(base + normalized);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map body, {
    String? token,
    Duration timeout = const Duration(seconds: 10),
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
      print('clearAuth error: $e');
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
