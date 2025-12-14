import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

class RegisterResult {
  final bool success;
  final String? message;
  final bool emailSent;
  final bool useOTP;
  final String? verificationUrl;
  final String? otp;
  final String? error;

  const RegisterResult({
    required this.success,
    required this.emailSent,
    required this.useOTP,
    this.message,
    this.verificationUrl,
    this.otp,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasVerificationLink =>
      verificationUrl != null && verificationUrl!.isNotEmpty;
  String get displayMessage => (error != null && error!.isNotEmpty)
      ? error!
      : (message ??
            (success
                ? 'Registration completed.'
                : 'Registration failed. Please try again.'));
}

class VerificationActionResult {
  final bool success;
  final String? message;
  final bool emailSent;
  final String? verificationUrl;
  final String? error;

  const VerificationActionResult({
    required this.success,
    required this.emailSent,
    this.message,
    this.verificationUrl,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasVerificationLink =>
      verificationUrl != null && verificationUrl!.isNotEmpty;
  String get displayMessage => (error != null && error!.isNotEmpty)
      ? error!
      : (message ??
            (success
                ? 'Action completed successfully.'
                : 'Action failed. Please try again.'));
}

class AuthService {
  final _api = ApiClient();

  /// Check if user is currently logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  /// Register a new user
  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    bool useOTP = false, // Default to email verification
  }) async {
    try {
      // Map UserRole to API endpoint string
      final roleStr = role == UserRole.consumer
          ? 'customer'
          : role == UserRole.vendor
          ? 'vendor'
          : role == UserRole.rider
          ? 'rider'
          : 'customer'; // fallback

      final data = await _api.postJson('/auth/register/$roleStr', {
        'name': fullName,
        'email': email,
        'password': password,
      }, timeout: const Duration(seconds: 60));

      final errorMessage = data['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return RegisterResult(
          success: false,
          message: errorMessage,
          error: errorMessage,
          emailSent: data['emailSent'] == true,
          useOTP: data['useOTP'] == true,
          verificationUrl: data['verificationUrl']?.toString(),
          otp: data['otp']?.toString(),
        );
      }

      final message = data['message']?.toString();
      final emailSent = data['emailSent'] == true;
      final needsOtp = data['useOTP'] == true;

      return RegisterResult(
        success: true,
        message:
            message ??
            'Account created successfully. Please verify your email.',
        emailSent: emailSent,
        useOTP: needsOtp,
        verificationUrl: data['verificationUrl']?.toString(),
        otp: data['otp']?.toString(),
      );
    } catch (e) {
      debugPrint('Registration failed: $e');
      final message = e.toString().replaceFirst('Exception: ', '');
      return RegisterResult(
        success: false,
        message: message,
        error: message,
        emailSent: false,
        useOTP: false,
      );
    }
  }

  /// Verify OTP (fallback to dev-verify for now)
  Future<bool> verifyOTP({required String email, required String otp}) async {
    try {
      // For now, use dev-verify as fallback until OTP endpoint is deployed
      final data = await _api.postJson('/auth/dev-verify', {'email': email});

      final errorMessage = data['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      return data['message'] != null;
    } catch (e) {
      debugPrint('OTP verification failed: $e');
      return false;
    }
  }

  /// Resend OTP (fallback to resend verification)
  Future<VerificationActionResult> resendOTP({required String email}) async {
    try {
      final data = await _api.postJson('/auth/resend-verification', {
        'email': email,
      });
      final errorMessage = data['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return VerificationActionResult(
          success: false,
          message: errorMessage,
          error: errorMessage,
          emailSent: data['emailSent'] == true,
          verificationUrl: data['verificationUrl']?.toString(),
        );
      }

      return VerificationActionResult(
        success: true,
        message: data['message']?.toString() ?? 'Verification email sent.',
        emailSent: data['emailSent'] == true,
        verificationUrl: data['verificationUrl']?.toString(),
      );
    } catch (e) {
      debugPrint('Resend OTP failed: $e');
      final message = e.toString().replaceFirst('Exception: ', '');
      return VerificationActionResult(
        success: false,
        message: message,
        error: message,
        emailSent: false,
        verificationUrl: null,
      );
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
    final result = await register(
      fullName: name,
      email: email,
      password: password,
      role: parsedRole,
    );
    return result.success;
  }

  /// Login and save user info locally
  Future<bool> login({required String email, required String password}) async {
    try {
      final data = await _api.postJson('/auth/login', {
        'email': email,
        'password': password,
      });

      final errorMessage = data['error']?.toString();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

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

        debugPrint('Login success: $email as $role');
        return true;
      } else {
        debugPrint('Invalid response from API: $data');
        throw Exception('Invalid response from server.');
      }
    } catch (e) {
      debugPrint('Login failed: $e');
      rethrow;
    }
  }

  /// Logout and clear saved session
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _api.clearAuth();
      debugPrint('Logged out successfully.');
    } catch (e) {
      debugPrint('Logout error: $e');
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
