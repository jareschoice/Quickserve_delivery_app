import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart'; // kApiBase and useMock constants

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void connect() async {
    if (useMock) return; // skip socket connection in mock mode
    if (socket != null && socket!.connected) return;

    // Resolve base URL from prefs override first
    String uri = kApiBase;
    try {
      final prefs = await SharedPreferences.getInstance();
      final override = prefs.getString('api_base_override');
      if (override != null && override.trim().isNotEmpty) {
        uri = override;
      }
    } catch (_) {}

    // Ensure correct protocol and include port when local
    if (!uri.startsWith('http')) {
      uri = 'https://getquickserves.com';
    }

    print('🔌 Connecting to socket at: $uri');

    socket = IO.io(uri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 2000,
    });

    socket!.on('connect', (_) => print('✅ Socket connected: ${socket!.id}'));
    socket!.on(
      'connect_error',
      (err) => print('⚠️ Socket connect_error: $err'),
    );
    socket!.on('error', (err) => print('❌ Socket error: $err'));
    socket!.on('disconnect', (_) => print('🔌 Socket disconnected'));
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void off(String event) {
    socket?.off(event);
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }
}
