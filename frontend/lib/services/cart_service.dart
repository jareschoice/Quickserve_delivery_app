// lib/services/cart_service.dart
// Global cart service that persists to SharedPreferences (like localStorage in event-frontend)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String name;
  final double price;
  int qty;
  final String vendorId;
  final String? vendorUserId;
  final String? vendorName;
  final List<Map<String, dynamic>> addOns;
  final String specialInstructions;
  final String? imageUrl;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.qty = 1,
    required this.vendorId,
    this.vendorUserId,
    this.vendorName,
    this.addOns = const [],
    this.specialInstructions = '',
    this.imageUrl,
  });

  // Calculate add-ons total
  double get addOnsTotal => addOns.fold(
    0.0,
    (sum, addon) => sum + ((addon['price'] ?? 0) as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'qty': qty,
    'vendorId': vendorId,
    'vendorUserId': vendorUserId,
    'vendorName': vendorName,
    'addOns': addOns,
    'specialInstructions': specialInstructions,
    'imageUrl': imageUrl,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] ?? json['_id'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] ?? 0).toDouble(),
    qty: json['qty'] ?? json['quantity'] ?? 1,
    vendorId: json['vendorId'] ?? '',
    vendorUserId: json['vendorUserId'],
    vendorName: json['vendorName'],
    addOns: (json['addOns'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    specialInstructions: json['specialInstructions'] ?? '',
    imageUrl: json['imageUrl'],
  );

  // Total includes base price + add-ons, multiplied by quantity
  double get total => (price + addOnsTotal) * qty;

  // Unique key for items with different customizations
  String get uniqueKey =>
      '$productId-${addOns.map((a) => a['name']).join('-')}-$specialInstructions';
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  List<CartItem> _items = [];
  static const int serviceCharge = 50; // ₦50 per vendor service fee

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.qty);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  int get vendorCount => itemsByVendor.keys.length;

  double get serviceFeeTotal => serviceCharge.toDouble() * vendorCount;

  double get total => subtotal + serviceFeeTotal;

  // Group items by vendor for multi-vendor orders
  Map<String, List<CartItem>> get itemsByVendor {
    final groups = <String, List<CartItem>>{};
    for (final item in _items) {
      final key = item.vendorId;
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(item);
    }
    return groups;
  }

  bool get isMultiVendor => itemsByVendor.keys.length > 1;

  // Initialize cart from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString('cart');
    if (cartJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((e) => CartItem.fromJson(e)).toList();
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to load cart: $e');
      }
    }
  }

  // Save cart to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString('cart', cartJson);
  }

  // Add item to cart (supports multi-vendor and customizations)
  Future<void> addItem({
    required String productId,
    required String name,
    required double price,
    int qty = 1,
    required String vendorId,
    String? vendorUserId,
    String? vendorName,
    List<Map<String, dynamic>>? addOns,
    String? specialInstructions,
    String? imageUrl,
  }) async {
    final newItem = CartItem(
      productId: productId,
      name: name,
      price: price,
      qty: qty,
      vendorId: vendorId,
      vendorUserId: vendorUserId,
      vendorName: vendorName,
      addOns: addOns ?? [],
      specialInstructions: specialInstructions ?? '',
      imageUrl: imageUrl,
    );

    // Items with different customizations are treated as different items
    final existingIndex = _items.indexWhere(
      (item) => item.uniqueKey == newItem.uniqueKey,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].qty += qty;
    } else {
      _items.add(newItem);
    }

    await _save();
    notifyListeners();
  }

  // Update item quantity
  Future<void> updateQty(String productId, int qty) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].qty = qty;
      }
      await _save();
      notifyListeners();
    }
  }

  // Remove item from cart
  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    await _save();
    notifyListeners();
  }

  // Clear entire cart
  Future<void> clear() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    await prefs.remove('vendorId');
    notifyListeners();
  }

  // Get cart items as list of maps (for API calls)
  List<Map<String, dynamic>> toMapList() {
    return _items
        .map(
          (item) => {
            'productId': item.productId,
            'name': item.name,
            'price': item.price,
            'qty': item.qty,
            'quantity': item.qty, // alias for compatibility
            'vendorId': item.vendorId,
            'vendorUserId': item.vendorUserId,
            'vendorName': item.vendorName,
            'addOns': item.addOns,
            'addOnsTotal': item.addOnsTotal,
            'specialInstructions': item.specialInstructions,
            'total': item.total,
          },
        )
        .toList();
  }

  // Get orders grouped by vendor (for multi-vendor payment)
  List<Map<String, dynamic>> toVendorOrders() {
    return itemsByVendor.entries.map((entry) {
      final vendorId = entry.key;
      final items = entry.value;
      final vendorName = items.first.vendorName ?? 'Vendor';
      final vendorUserId = items.first.vendorUserId ?? vendorId;

      return {
        'vendorId': vendorUserId,
        'vendorUserId': vendorUserId,
        'vendorName': vendorName,
        'items': items
            .map(
              (item) => {
                'name': item.name,
                'price': item.price,
                'qty': item.qty,
              },
            )
            .toList(),
      };
    }).toList();
  }
}
