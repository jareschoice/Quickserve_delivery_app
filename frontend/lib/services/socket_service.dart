import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart'; // kApiBase and useMock constants

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

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

    // Normalize: if user passed just an IP/host without protocol
    if (!uri.startsWith('http://') && !uri.startsWith('https://')) {
      // Prefer http for LAN development
      uri = 'http://$uri';
    }

    // Strip trailing slashes to avoid double // when appending paths
    uri = uri.replaceAll(RegExp(r'/+$'), '');

    // For socket.io we want the origin only (no /api suffix if user added one)
    uri = uri.replaceFirst(RegExp(r'/api/?$'), '');

    debugPrint('Connecting to socket at: $uri');

    socket = io.io(uri, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 1000,
      'forceNew': false,
    });

    socket!.on('connect', (_) {
      _isConnected = true;
      debugPrint('Socket connected: ${socket!.id}');
      // Auto-join consumer room on connect
      _joinRooms();
    });

    socket!.on('connect_error', (err) {
      _isConnected = false;
      debugPrint('Socket connect_error: $err');
    });

    socket!.on('error', (err) => debugPrint('Socket error: $err'));

    socket!.on('disconnect', (_) {
      _isConnected = false;
      debugPrint('Socket disconnected');
    });

    // Listen for server broadcasts
    socket!.on('vendor:created', (data) => debugPrint('New vendor: $data'));
    socket!.on('vendor:updated', (data) => debugPrint('Vendor updated: $data'));
    socket!.on('product:created', (data) => debugPrint('New product: $data'));
    socket!.on(
      'product:updated',
      (data) => debugPrint('Product updated: $data'),
    );
  }

  void _joinRooms() async {
    // Try to identify with user info if logged in
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        // Use 'identify' event for auth payload - server auto-joins user:<id> and role:consumer rooms
        socket?.emit('identify', {'userId': userId, 'role': 'consumer'});
        debugPrint('[socket] identified as user: $userId, role: consumer');
      } else {
        // Not logged in - just join consumer role room manually
        socket?.emit('join', 'role:consumer');
        debugPrint('[socket] joined room: role:consumer (guest)');
      }
    } catch (_) {
      // Fallback: just join consumer role room
      socket?.emit('join', 'role:consumer');
      debugPrint('[socket] joined room: role:consumer (fallback)');
    }
  }

  void joinRoom(String room) {
    // ✅ FIX: Emit plain string, not {'room': room} object
    // Backend expects: socket.on('join', (room) => socket.join(room))
    socket?.emit('join', room);
    debugPrint('[socket] joined room: $room');
  }

  void leaveRoom(String room) {
    // ✅ FIX: Emit plain string, not {'room': room} object
    socket?.emit('leave', room);
    debugPrint('[socket] left room: $room');
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
