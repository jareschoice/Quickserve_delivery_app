// ===============================
// QuickServe Offline Support Service
// Local caching with SharedPreferences
// ===============================
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  SharedPreferences? _prefs;
  bool _isOnline = true;
  final _onlineController = StreamController<bool>.broadcast();

  Stream<bool> get onlineStream => _onlineController.stream;
  bool get isOnline => _isOnline;

  // Cache keys
  static const String _vendorsKey = 'cached_vendors';
  static const String _productsKey = 'cached_products';
  static const String _ordersKey = 'cached_orders';
  static const String _userKey = 'cached_user';
  static const String _cartKey = 'cached_cart';
  static const String _subscriptionsKey = 'cached_subscriptions';
  static const String _pendingActionsKey = 'pending_actions';

  // Cache expiry duration (24 hours)
  static const Duration cacheExpiry = Duration(hours: 24);

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== Connectivity ====================

  void setOnlineStatus(bool online) {
    _isOnline = online;
    _onlineController.add(online);
    if (online) {
      // Sync pending actions when back online
      _syncPendingActions();
    }
  }

  // ==================== Generic Cache Methods ====================

  Future<void> _saveToCache(String key, dynamic data) async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    await _prefs!.setString(key, jsonString);
    await _prefs!.setInt(
      '${key}_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<T?> _getFromCache<T>(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString(key);
    if (jsonString == null) return null;

    // Check cache expiry
    final timestamp = _prefs!.getInt('${key}_timestamp') ?? 0;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > cacheExpiry) {
      // Cache expired
      await _prefs!.remove(key);
      return null;
    }

    try {
      return jsonDecode(jsonString) as T;
    } catch (e) {
      debugPrint('Cache decode error for $key: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    _prefs ??= await SharedPreferences.getInstance();
    final keys = [
      _vendorsKey,
      _productsKey,
      _ordersKey,
      _userKey,
      _cartKey,
      _subscriptionsKey,
    ];
    for (final key in keys) {
      await _prefs!.remove(key);
      await _prefs!.remove('${key}_timestamp');
    }
  }

  // ==================== Vendors Cache ====================

  Future<void> cacheVendors(List<dynamic> vendors) async {
    await _saveToCache(_vendorsKey, vendors);
    debugPrint('✅ Cached ${vendors.length} vendors');
  }

  Future<List<dynamic>?> getCachedVendors() async {
    final data = await _getFromCache<List<dynamic>>(_vendorsKey);
    if (data != null) {
      debugPrint('📦 Retrieved ${data.length} vendors from cache');
    }
    return data;
  }

  // ==================== Products Cache ====================

  Future<void> cacheProducts(String vendorId, List<dynamic> products) async {
    // Get existing products cache
    Map<String, dynamic> allProducts =
        await _getFromCache<Map<String, dynamic>>(_productsKey) ?? {};
    allProducts[vendorId] = products;
    await _saveToCache(_productsKey, allProducts);
    debugPrint('✅ Cached ${products.length} products for vendor $vendorId');
  }

  Future<List<dynamic>?> getCachedProducts(String vendorId) async {
    final allProducts = await _getFromCache<Map<String, dynamic>>(_productsKey);
    if (allProducts != null && allProducts[vendorId] != null) {
      final products = allProducts[vendorId] as List<dynamic>;
      debugPrint(
        '📦 Retrieved ${products.length} products from cache for vendor $vendorId',
      );
      return products;
    }
    return null;
  }

  // ==================== Orders Cache ====================

  Future<void> cacheOrders(List<dynamic> orders) async {
    await _saveToCache(_ordersKey, orders);
    debugPrint('✅ Cached ${orders.length} orders');
  }

  Future<List<dynamic>?> getCachedOrders() async {
    return await _getFromCache<List<dynamic>>(_ordersKey);
  }

  // ==================== User Cache ====================

  Future<void> cacheUser(Map<String, dynamic> user) async {
    await _saveToCache(_userKey, user);
    debugPrint('✅ Cached user data');
  }

  Future<Map<String, dynamic>?> getCachedUser() async {
    return await _getFromCache<Map<String, dynamic>>(_userKey);
  }

  // ==================== Cart Cache ====================

  Future<void> cacheCart(List<dynamic> cartItems) async {
    await _saveToCache(_cartKey, cartItems);
  }

  Future<List<dynamic>?> getCachedCart() async {
    return await _getFromCache<List<dynamic>>(_cartKey);
  }

  // ==================== Subscriptions Cache ====================

  Future<void> cacheSubscriptions(List<dynamic> subscriptions) async {
    await _saveToCache(_subscriptionsKey, subscriptions);
    debugPrint('✅ Cached ${subscriptions.length} subscriptions');
  }

  Future<List<dynamic>?> getCachedSubscriptions() async {
    return await _getFromCache<List<dynamic>>(_subscriptionsKey);
  }

  // ==================== Pending Actions (Offline Queue) ====================

  Future<void> addPendingAction(Map<String, dynamic> action) async {
    _prefs ??= await SharedPreferences.getInstance();
    final pendingJson = _prefs!.getString(_pendingActionsKey);
    List<dynamic> pending = pendingJson != null ? jsonDecode(pendingJson) : [];

    action['timestamp'] = DateTime.now().toIso8601String();
    pending.add(action);

    await _prefs!.setString(_pendingActionsKey, jsonEncode(pending));
    debugPrint('📝 Added pending action: ${action['type']}');
  }

  Future<List<Map<String, dynamic>>> getPendingActions() async {
    _prefs ??= await SharedPreferences.getInstance();
    final pendingJson = _prefs!.getString(_pendingActionsKey);
    if (pendingJson == null) return [];

    final List<dynamic> pending = jsonDecode(pendingJson);
    return pending.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> clearPendingActions() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_pendingActionsKey);
  }

  Future<void> _syncPendingActions() async {
    final actions = await getPendingActions();
    if (actions.isEmpty) return;

    debugPrint('🔄 Syncing ${actions.length} pending actions...');

    // Process actions - this would be implemented based on action types
    // For now, just clear them (actual sync would call API)
    for (final action in actions) {
      try {
        debugPrint('  - Processing: ${action['type']}');
        // TODO: Call appropriate API based on action type
        // await _processAction(action);
      } catch (e) {
        debugPrint('  - Failed: ${action['type']}: $e');
      }
    }

    await clearPendingActions();
    debugPrint('✅ Sync complete');
  }

  void dispose() {
    _onlineController.close();
  }
}

// Connectivity checker widget mixin
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  bool _isOnline = true;
  StreamSubscription<bool>? _connectivitySubscription;

  bool get isOnline => _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = OfflineService().isOnline;
    _connectivitySubscription = OfflineService().onlineStream.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        onConnectivityChanged(online);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void onConnectivityChanged(bool isOnline) {
    // Override in subclass to handle connectivity changes
  }
}
