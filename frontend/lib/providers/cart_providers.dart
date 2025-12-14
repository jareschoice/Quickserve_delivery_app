// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  int qty;
  final String vendorId;
  final List<Map<String, dynamic>> addOns;
  final String specialInstructions;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    required this.vendorId,
    this.addOns = const [],
    this.specialInstructions = '',
    this.imageUrl,
  });

  // Calculate add-ons total
  int get addOnsTotal => addOns.fold(
    0,
    (sum, addon) => sum + ((addon['price'] ?? 0) as num).toInt(),
  );

  // Total includes base price + add-ons, multiplied by quantity
  int get total => (price + addOnsTotal) * qty;

  // For comparison - items with different add-ons are treated as different
  String get uniqueKey =>
      '$id-${addOns.map((a) => a['name']).join('-')}-$specialInstructions';

  // Create a copy with new quantity
  CartItem copyWith({int? qty}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      qty: qty ?? this.qty,
      vendorId: vendorId,
      addOns: addOns,
      specialInstructions: specialInstructions,
      imageUrl: imageUrl,
    );
  }

  // Convert to map for API
  Map<String, dynamic> toMap() {
    return {
      'productId': id,
      'name': name,
      'quantity': qty,
      'price': price,
      'addOns': addOns,
      'addOnsTotal': addOnsTotal,
      'specialInstructions': specialInstructions,
      'total': total,
    };
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  // fixed service charge (as you wanted Service charge naming)
  int serviceCharge = 50; // per vendor service charge

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(CartItem item) {
    // Items with different add-ons or instructions are treated as separate items
    final idx = _items.indexWhere((i) => i.uniqueKey == item.uniqueKey);
    if (idx >= 0) {
      _items[idx].qty += item.qty;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String uniqueKey) {
    _items.removeWhere((i) => i.uniqueKey == uniqueKey);
    notifyListeners();
  }

  void removeById(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateQty(String uniqueKey, int qty) {
    final idx = _items.indexWhere((i) => i.uniqueKey == uniqueKey);
    if (idx >= 0) {
      _items[idx].qty = qty;
      if (_items[idx].qty <= 0) _items.removeAt(idx);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int get subtotal => _items.fold(0, (s, i) => s + i.total);
  int get vendorCount => _items.map((i) => i.vendorId).toSet().length;
  int get serviceFeeTotal => serviceCharge * vendorCount;
  int get total => subtotal + serviceFeeTotal;
  int get itemCount => _items.fold(0, (s, i) => s + i.qty);

  // Get items as maps for API submission
  List<Map<String, dynamic>> toMapList() {
    return _items.map((item) => item.toMap()).toList();
  }
}
