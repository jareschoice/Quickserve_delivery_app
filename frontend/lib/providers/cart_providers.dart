// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  int qty;
  final String vendorId;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.qty = 1,
    required this.vendorId,
  });

  int get total => price * qty;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  // fixed service charge (as you wanted Service charge naming)
  int serviceCharge = 50;

  List<CartItem> get items => List.unmodifiable(_items);

  void addItem(CartItem item) {
    // allow multiple items if same id -> increase qty
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx].qty += item.qty;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void updateQty(String id, int qty) {
    final idx = _items.indexWhere((i) => i.id == id);
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
  int get total => subtotal + (items.isEmpty ? 0 : serviceCharge);
  int get itemCount => _items.fold(0, (s, i) => s + i.qty);
}