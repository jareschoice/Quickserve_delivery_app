import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Production backend URL (use once server is deployed with /api/* routes)
  static const String productionUrl = 'https://getquickserves.com';

  // Local development URL - This is used when web app is on localhost
  // Update this IP to match your backend's IP address
  static const String localUrl = 'http://';

  // Set to true for production builds (once backend is deployed)
  // Set to false for local WiFi testing
  static const bool isProduction = false;

  static const int defaultPort = 5555;

  /// Get the backend base URL
  /// - Production: Uses productionUrl
  /// - Web Development:
  ///   - If running on same IP as backend: auto-detect
  ///   - If running on localhost: use localUrl (for dev server scenarios)
  /// - Mobile Development: Uses localUrl (configure IP for your network)
  static String get backendBaseUrl {
    if (isProduction) {
      return productionUrl;
    }

    // For web, check if we're on localhost (Flutter dev server)
    // or on the same host as the backend
    if (kIsWeb) {
      try {
        final host = Uri.base.host;

        // If running on localhost (Flutter dev server), use the configured localUrl
        // because backend is on a different host (LAN IP)
        if (host == 'localhost' || host == '127.0.0.1') {
          return localUrl;
        }

        // Otherwise, we're likely on the same host as backend (e.g., LAN IP)
        final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
        return '$scheme://$host:${defaultPort.toString()}';
      } catch (e) {
        return localUrl;
      }
    }

    // Mobile apps need the explicit IP
    return localUrl;
  }
}




