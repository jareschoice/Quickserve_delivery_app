import 'config.dart';

class ApiConfig {
  // Single source of truth for backend base URL.
  // Override at build/run via:
  //   flutter run --flavor consumer --dart-define BACKEND_BASE_URL=http://<PC_IP>:5555
  //   flutter build apk --flavor consumer --dart-define BACKEND_BASE_URL=http://<PC_IP>:5555
  static String get baseUrl => AppConfig.backendBaseUrl;
}
