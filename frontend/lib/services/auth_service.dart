import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient();

  /// Register a new user
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    bool useOTP = false, // Default to email verification
  }) async {
    try {
      final roleStr = (role == UserRole.consumer)
          ? 'customer'
          : roleToString(role);

      final data = await _api.postJson('/auth/register/$roleStr', {
        'name': fullName,
        'email': email,
        'password': password,
      });

      return data['ok'] == true || data['message'] != null;
    } catch (e) {
      print('⚠️ Registration failed: $e');
      return false;
    }
  }

  /// Verify OTP (fallback to dev-verify for now)
  Future<bool> verifyOTP({required String email, required String otp}) async {
    try {
      // For now, use dev-verify as fallback until OTP endpoint is deployed
      final data = await _api.postJson('/auth/dev-verify', {'email': email});

      return data['message'] != null;
    } catch (e) {
      print('⚠️ OTP verification failed: $e');
      return false;
    }
  }

  /// Resend OTP (fallback to resend verification)
  Future<bool> resendOTP({required String email}) async {
    try {
      final data = await _api.postJson('/auth/resend-verification', {
        'email': email,
      });

      return data['message'] != null;
    } catch (e) {
      print('⚠️ Resend OTP failed: $e');
      return false;
    }
  }

  /// Signup alias (used in UI)
  Future<bool> signup(
    String role,
    String name,
    String email,
    String password,
  ) async {
    final parsedRole = roleFromString(role) ?? UserRole.consumer;
    return await register(
      fullName: name,
      email: email,
      password: password,
      role: parsedRole,
    );
  }

  /// Login and save user info locally
  Future<bool> login({required String email, required String password}) async {
    try {
      final data = await _api.postJson('/auth/login', {
        'email': email,
        'password': password,
      });

      final token = data['token'];
      final user = data['user'];

      if (token is String && user is Map) {
        final role = user['role'] as String? ?? '';
        final fullName = user['name'] as String? ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token); // Use consistent key
        if (role.isNotEmpty) await prefs.setString('role', role);
        if (email.isNotEmpty) await prefs.setString('email', email);
        if (fullName.isNotEmpty) await prefs.setString('fullName', fullName);

        print('✅ Login success: $email as $role');
        return true;
      } else {
        print('⚠️ Invalid response from API: $data');
        return false;
      }
    } catch (e) {
      print('❌ Login failed: $e');
      return false;
    }
  }

  /// Logout and clear saved session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _api.clearAuth();
      print('🔒 Logged out successfully.');
    } catch (e) {
      print('⚠️ Logout error: $e');
    }
  }

  /// Retrieve saved user role
  Future<UserRole?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('role');
    return roleFromString(roleStr);
  }

  /// Retrieve the currently saved user info from SharedPreferences.
  /// Returns a map with keys: 'fullName', 'email', 'role'
  Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('fullName') ?? '';
    final email = prefs.getString('email') ?? '';
    final role = prefs.getString('role') ?? '';
    return {'fullName': fullName, 'email': email, 'role': role};
  }
}
