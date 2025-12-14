import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling fingerprint/face ID authentication
/// Note: Biometrics are not supported on web platform
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserKey = 'biometric_user_email';

  /// Check if running on web platform
  bool get _isWeb => kIsWeb;

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    // Biometrics not supported on web
    if (_isWeb) return false;

    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Plugin not available on this platform
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    // Biometrics not supported on web
    if (_isWeb) return [];

    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    } on MissingPluginException {
      return [];
    }
  }

  /// Check if user has enabled biometric login
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric login for current user
  Future<bool> enableBiometric(String userEmail) async {
    // First verify biometric to ensure it works
    final authenticated = await authenticate(
      reason: 'Verify your fingerprint to enable quick login',
    );

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      await prefs.setString(_biometricUserKey, userEmail);
      return true;
    }
    return false;
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_biometricUserKey);
  }

  /// Get the email of user who enabled biometric
  Future<String?> getBiometricUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricUserKey);
  }

  /// Authenticate using biometrics (fingerprint/face)
  Future<bool> authenticate({
    String reason = 'Authenticate to access QuickServe',
  }) async {
    // Biometrics not supported on web
    if (_isWeb) return false;

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        // stickyAuth removed in latest local_auth
        biometricOnly: true,
        // useErrorDialogs removed in latest local_auth
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Authenticate with fallback to device PIN/pattern
  Future<bool> authenticateWithFallback({
    String reason = 'Authenticate to access QuickServe',
  }) async {
    // Biometrics not supported on web
    if (_isWeb) return false;

    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        // stickyAuth removed in latest local_auth
        biometricOnly: false, // Allow PIN/pattern fallback
        // useErrorDialogs removed in latest local_auth
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Cancel any ongoing authentication
  Future<void> cancelAuthentication() async {
    if (_isWeb) return;
    try {
      await _localAuth.stopAuthentication();
    } on MissingPluginException {
      // Ignore on unsupported platforms
    }
  }

  /// Get a friendly name for available biometric type
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'Biometric';
    }
    return 'Biometric';
  }
}
