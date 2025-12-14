import 'dart:ui' show Color;
import 'package:flutter/foundation.dart';
import '../api_client.dart';

/// Service for event-specific API calls
class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  /// Get all vendors for event
  Future<List<EventVendor>> getVendors() async {
    try {
      final response = await ApiClient().getJson('/api/event/vendors');
      if (response['success'] == true && response['vendors'] != null) {
        return (response['vendors'] as List)
            .map((v) => EventVendor.fromJson(v))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vendors: $e');
      return [];
    }
  }

  /// Get products for a specific vendor
  Future<List<EventProduct>> getVendorProducts(String vendorId) async {
    try {
      final response = await ApiClient().getJson(
        '/api/event/vendors/$vendorId/products',
      );
      if (response['success'] == true && response['products'] != null) {
        return (response['products'] as List)
            .map((p) => EventProduct.fromJson(p))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  /// Create a new order
  Future<EventOrder?> createOrder({
    String? phone,
    String? seatNumber,
    Map<String, dynamic>? deliveryAddress,
    String? customerPhone,
    String? customerEmail,
    required String vendorId,
    required List<CartItem> items,
  }) async {
    try {
      // Prefer structured `deliveryAddress` and `customerPhone` when available.
      // Fall back to legacy `phone`/`seatNumber` for backwards compatibility.
      final payload = {
        if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (phone != null && deliveryAddress == null && customerPhone == null)
          'phone': phone,
        if (seatNumber != null && deliveryAddress == null)
          'seatNumber': seatNumber,
        'vendorId': vendorId,
        'items': items.map((i) => i.toJson()).toList(),
      };

      final response = await ApiClient().postJson('/api/event/orders', payload);
      if (response['success'] == true && response['order'] != null) {
        return EventOrder.fromJson(response['order']);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  /// Track an order by ID
  Future<EventOrder?> trackOrder(String orderId) async {
    try {
      final response = await ApiClient().getJson('/api/event/orders/$orderId');
      if (response['success'] == true && response['order'] != null) {
        return EventOrder.fromJson(response['order']);
      }
      return null;
    } catch (e) {
      debugPrint('Error tracking order: $e');
      return null;
    }
  }

  /// Verify payment
  Future<bool> verifyPayment(String reference, String orderId) async {
    try {
      final response = await ApiClient().postJson(
        '/api/event/orders/verify-payment',
        {'reference': reference, 'orderId': orderId},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      return false;
    }
  }

  /// Get vendor's orders (for vendor dashboard)
  Future<List<EventOrder>> getVendorOrders() async {
    try {
      final response = await ApiClient().getJson('/api/event/vendor/orders');
      if (response['success'] == true && response['orders'] != null) {
        return (response['orders'] as List)
            .map((o) => EventOrder.fromJson(o))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching vendor orders: $e');
      return [];
    }
  }

  /// Update order status (vendor)
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await ApiClient().patchJson(
        '/api/event/vendor/orders/$orderId/status',
        {'status': status},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  /// Get ready orders (for dispatcher)
  Future<List<EventOrder>> getReadyOrders() async {
    try {
      final response = await ApiClient().getJson(
        '/api/event/dispatcher/ready-orders',
      );
      if (response['success'] == true && response['orders'] != null) {
        return (response['orders'] as List)
            .map((o) => EventOrder.fromJson(o))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching ready orders: $e');
      return [];
    }
  }

  /// Claim an order (dispatcher)
  Future<bool> claimOrder(String orderId) async {
    try {
      final response = await ApiClient().postJson(
        '/api/event/dispatcher/claim',
        {'orderId': orderId},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error claiming order: $e');
      return false;
    }
  }

  /// Confirm delivery (dispatcher)
  Future<bool> confirmDelivery(String orderId, String qrToken) async {
    try {
      final response = await ApiClient().postJson(
        '/api/event/dispatcher/confirm',
        {'orderId': orderId, 'qrToken': qrToken},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error confirming delivery: $e');
      return false;
    }
  }

  /// Get dispatcher stats
  Future<Map<String, dynamic>?> getDispatcherStats() async {
    try {
      final response = await ApiClient().getJson('/api/event/dispatcher/stats');
      if (response['success'] == true && response['stats'] != null) {
        return response['stats'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching dispatcher stats: $e');
      return null;
    }
  }

  /// Get event summary (admin)
  Future<Map<String, dynamic>?> getEventSummary() async {
    try {
      final response = await ApiClient().getJson('/api/event/admin/summary');
      if (response['success'] == true && response['summary'] != null) {
        return response['summary'];
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching event summary: $e');
      return null;
    }
  }
}

/// Event Vendor Model
class EventVendor {
  final String id;
  final String name;
  final String email;
  final String? businessName;
  final String? phone;
  final String? category;
  final String? imageUrl;
  final double rating;
  final bool isOpen;

  EventVendor({
    required this.id,
    required this.name,
    required this.email,
    this.businessName,
    this.phone,
    this.category,
    this.imageUrl,
    this.rating = 0.0,
    this.isOpen = true,
  });

  factory EventVendor.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return EventVendor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      businessName: profile['businessName'] ?? json['name'],
      phone: profile['phone'],
      category: profile['category'],
      imageUrl: profile['imageUrl'] ?? json['imageUrl'],
      rating: (json['rating'] ?? 0).toDouble(),
      isOpen: json['isOpen'] ?? true,
    );
  }
}

/// Event Product Model
class EventProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;
  final bool available;
  final int stock;

  EventProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.available = true,
    this.stock = 999,
  });

  factory EventProduct.fromJson(Map<String, dynamic> json) {
    return EventProduct(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      imageUrl: json['imageUrl'],
      available: json['available'] ?? true,
      stock: json['stock'] ?? 999,
    );
  }
}

/// Cart Item Model
class CartItem {
  final String productId;
  final String name;
  final double price;
  int quantity;
  final String? vendorId;
  final String? vendorName;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.vendorId,
    this.vendorName,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'qty': quantity,
  };

  factory CartItem.fromProduct(
    EventProduct product, {
    String? vendorId,
    String? vendorName,
  }) {
    return CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      vendorId: vendorId,
      vendorName: vendorName,
    );
  }
}

/// Event Order Model
class EventOrder {
  final String id;
  final String phone;
  final String seatNumber;
  final String? vendorId;
  final String? vendorName;
  final String? dispatcherId;
  final String? dispatcherName;
  final List<OrderItem> items;
  final double subtotal;
  final double serviceCharge;
  final double total;
  final String status;
  final bool paid;
  final String? paymentReference;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  EventOrder({
    required this.id,
    required this.phone,
    required this.seatNumber,
    this.vendorId,
    this.vendorName,
    this.dispatcherId,
    this.dispatcherName,
    required this.items,
    required this.subtotal,
    required this.serviceCharge,
    required this.total,
    required this.status,
    required this.paid,
    this.paymentReference,
    this.qrCode,
    required this.createdAt,
    this.deliveredAt,
  });

  factory EventOrder.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendorId'];
    final dispatcher = json['dispatcherId'];
    final payment = json['payment'] as Map<String, dynamic>? ?? {};

    return EventOrder(
      id: json['_id'] ?? '',
      phone: json['phone'] ?? '',
      seatNumber: json['seatNumber'] ?? '',
      vendorId: vendor is Map ? vendor['_id'] : vendor?.toString(),
      vendorName: vendor is Map
          ? (vendor['profile']?['businessName'] ?? vendor['name'])
          : null,
      dispatcherId: dispatcher is Map
          ? dispatcher['_id']
          : dispatcher?.toString(),
      dispatcherName: dispatcher is Map ? dispatcher['name'] : null,
      items: (json['items'] as List? ?? [])
          .map((i) => OrderItem.fromJson(i))
          .toList(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      serviceCharge: (json['serviceCharge'] ?? 100).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paid: payment['paid'] ?? false,
      paymentReference: payment['reference'],
      qrCode: json['qrCode'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      deliveredAt: json['deliveryConfirmedAt'] != null
          ? DateTime.tryParse(json['deliveryConfirmedAt'])
          : null,
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA000);
      case 'accepted':
        return const Color(0xFF2196F3);
      case 'preparing':
        return const Color(0xFF9C27B0);
      case 'ready':
        return const Color(0xFF4CAF50);
      case 'out_for_delivery':
        return const Color(0xFFFF6B00);
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF757575);
    }
  }
}

/// Order Item Model
class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({required this.name, required this.price, required this.quantity});

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['qty'] ?? json['quantity'] ?? 1,
    );
  }
}
