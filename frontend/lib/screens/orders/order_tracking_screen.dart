// lib/screens/orders/order_tracking_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import 'rider_chat_screen.dart';

/// OrderTrackingScreen - Real-time order tracking with live map and QR code
/// ✅ ENHANCED: Now supports multi-vendor orders with grouped display
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final SocketService _socketService = SocketService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _order;
  Map<String, dynamic>? _riderLocation;

  // ✅ Multi-vendor support
  bool _isMultiVendor = false;
  List<Map<String, dynamic>> _groupOrders = [];
  int _vendorCount = 1;
  num _groupTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.connect();

    // Join order room
    _socketService.joinRoom('order:${widget.orderId}');

    // Listen for order status updates
    _socketService.on('order:status', (data) {
      debugPrint('Order status update: $data');
      if (data['orderId'] == widget.orderId && mounted) {
        _loadOrder();
      }
    });

    _socketService.on('order:updated', (data) {
      debugPrint('Order updated: $data');
      if (data['orderId'] == widget.orderId && mounted) {
        _loadOrder();
      }
    });

    // Listen for rider location updates (live map)
    _socketService.on('rider:location', (data) {
      debugPrint('Rider location: $data');
      if (data['orderId'] == widget.orderId && mounted) {
        setState(() {
          _riderLocation = {
            'lat': data['lat'] ?? data['latitude'],
            'lng': data['lng'] ?? data['longitude'],
            'updatedAt': DateTime.now().toIso8601String(),
          };
        });
      }
    });

    // Listen for dispatcher location updates
    _socketService.on('dispatcher:location:update', (data) {
      debugPrint('Dispatcher location: $data');
      if (data['orderId'] == widget.orderId && mounted) {
        setState(() {
          _riderLocation = {
            'lat': data['lat'] ?? data['latitude'],
            'lng': data['lng'] ?? data['longitude'],
            'updatedAt': DateTime.now().toIso8601String(),
          };
        });
      }
    });

    // Emit tracking request
    _socketService.emit('order:track', {'orderId': widget.orderId});
  }

  void _removeSocketListeners() {
    _socketService.off('order:status');
    _socketService.off('order:updated');
    _socketService.off('rider:location');
    _socketService.off('dispatcher:location:update');
    _socketService.leaveRoom('order:${widget.orderId}');
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Try public tracking endpoint first (now returns multi-vendor data)
      final data = await ApiClient().getJson('/api/track/${widget.orderId}');
      setState(() {
        _order = data['order'] ?? data;
        _loading = false;

        // ✅ Handle multi-vendor response - only treat as multi-vendor if vendorCount > 1
        _vendorCount = data['vendorCount'] ?? 1;
        _isMultiVendor = data['isMultiVendor'] == true && _vendorCount > 1;
        _groupTotal = data['groupTotal'] ?? _order?['total'] ?? 0;

        if (data['groupOrders'] != null && data['groupOrders'] is List) {
          _groupOrders = (data['groupOrders'] as List)
              .map((o) => Map<String, dynamic>.from(o))
              .toList();
        } else {
          _groupOrders = [];
        }

        // If multi-vendor, also join rooms for all orders in group
        if (_isMultiVendor && _groupOrders.isNotEmpty) {
          for (var ord in _groupOrders) {
            final oid = ord['_id']?.toString();
            if (oid != null && oid != widget.orderId) {
              _socketService.joinRoom('order:$oid');
            }
          }
        }
      });
    } catch (e) {
      // Try order detail endpoint
      try {
        final data = await ApiClient().getJson('/api/orders/${widget.orderId}');
        setState(() {
          _order = data['order'] ?? data;
          _loading = false;
          _isMultiVendor = false;
          _groupOrders = [];
        });
      } catch (e2) {
        setState(() {
          _error = e2.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tracking Order'),
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tracking Order'),
          backgroundColor: const Color(0xFFFF6B00),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Failed to load order',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final status = _order!['status'] ?? 'placed';
    // Look for QR token in multiple possible field names (different API versions)
    final qrToken =
        _order!['qrConsumerToken'] ??
        _order!['deliveryConfirmationToken'] ??
        _order!['qrCode'];
    final rider = _order!['riderId'] ?? _order!['dispatcher'];
    // Safely extract delivery location - deliveryAddress might be a string or an object
    dynamic deliveryLocation;
    if (_order!['deliveryLocation'] != null) {
      deliveryLocation = _order!['deliveryLocation'];
    } else if (_order!['deliveryAddress'] is Map) {
      deliveryLocation = _order!['deliveryAddress']['coordinates'];
    }
    // If still null, it's okay - the map section will use defaults

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isMultiVendor
              ? 'Multi-Vendor Order'
              : 'Order #${_getShortId(widget.orderId)}',
        ),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrder),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        color: const Color(0xFFFF6B00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ✅ Multi-vendor badge
              if (_isMultiVendor) _buildMultiVendorBadge(),

              // Live Map Section
              _buildMapSection(deliveryLocation),

              // Status Timeline
              _buildStatusTimeline(status),

              // Rider Info (if assigned)
              if (rider != null) _buildRiderInfo(rider),

              // QR Code Section (for delivery confirmation)
              if (qrToken != null && _isActiveStatus(status))
                _buildQrCodeSection(qrToken),

              // ✅ Order Items - show grouped by vendor for multi-vendor
              if (_isMultiVendor && _groupOrders.length > 1)
                _buildMultiVendorOrderItems()
              else
                _buildOrderItems(
                  _order!['items'] as List? ?? [],
                  _order!['total'] ?? 0,
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ NEW: Badge showing this is a multi-vendor order
  Widget _buildMultiVendorBadge() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFF6B00), const Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Vendor Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$_vendorCount vendors • ₦${_formatNumber(_groupTotal)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_vendorCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Safely parse a coordinate value that might be a num, String, or null
  double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  Widget _buildMapSection(dynamic locationData) {
    // Safely parse location data which might be a Map or null
    Map<String, dynamic>? location;
    if (locationData is Map) {
      location = Map<String, dynamic>.from(locationData);
    }

    // Get coordinates for map - safely handle String/num/null
    double? deliveryLat =
        _parseCoordinate(location?['lat']) ??
        _parseCoordinate(location?['latitude']);
    double? deliveryLng =
        _parseCoordinate(location?['lng']) ??
        _parseCoordinate(location?['longitude']);
    double? riderLat = _parseCoordinate(_riderLocation?['lat']);
    double? riderLng = _parseCoordinate(_riderLocation?['lng']);

    // Default to a reasonable location if nothing available (Lagos, Nigeria)
    final defaultLat = 6.5244;
    final defaultLng = 3.3792;

    final hasDeliveryLocation = deliveryLat != null && deliveryLng != null;
    final hasRiderLocation = riderLat != null && riderLng != null;

    // Create markers
    Set<Marker> markers = {};

    if (hasDeliveryLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(deliveryLat, deliveryLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Delivery Location'),
        ),
      );
    }

    if (hasRiderLocation) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: LatLng(riderLat, riderLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: const InfoWindow(title: 'Rider Location'),
        ),
      );
    }

    // Determine center and zoom
    LatLng center;
    double zoom = 15.0;

    if (hasRiderLocation) {
      center = LatLng(riderLat, riderLng);
    } else if (hasDeliveryLocation) {
      center = LatLng(deliveryLat, deliveryLng);
    } else {
      center = LatLng(defaultLat, defaultLng);
      zoom = 12.0;
    }

    // Create polyline between rider and delivery if both exist
    Set<Polyline> polylines = {};
    if (hasRiderLocation && hasDeliveryLocation) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            LatLng(riderLat, riderLng),
            LatLng(deliveryLat, deliveryLng),
          ],
          color: const Color(0xFFFF6B00),
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    return Container(
      height: 220,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Google Map - use placeholder on web if Maps API not configured
            if (kIsWeb)
              _buildMapPlaceholder(hasRiderLocation, hasDeliveryLocation)
            else
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: center,
                  zoom: zoom,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  // Fit bounds if we have both markers
                  if (hasRiderLocation && hasDeliveryLocation) {
                    final bounds = LatLngBounds(
                      southwest: LatLng(
                        riderLat < deliveryLat ? riderLat : deliveryLat,
                        riderLng < deliveryLng ? riderLng : deliveryLng,
                      ),
                      northeast: LatLng(
                        riderLat > deliveryLat ? riderLat : deliveryLat,
                        riderLng > deliveryLng ? riderLng : deliveryLng,
                      ),
                    );
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 50),
                    );
                  }
                },
              ),
            // Real-time indicator
            if (hasRiderLocation)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Legend
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasRiderLocation)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B00),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Rider', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    if (hasDeliveryLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Delivery',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a map placeholder for web when Google Maps API isn't configured
  Widget _buildMapPlaceholder(bool hasRiderLocation, bool hasDeliveryLocation) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF6B00).withValues(alpha: 0.1),
            const Color(0xFFFF6B00).withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasRiderLocation ? Icons.delivery_dining : Icons.location_on,
            size: 48,
            color: const Color(0xFFFF6B00),
          ),
          const SizedBox(height: 12),
          Text(
            hasRiderLocation
                ? 'Rider is on the way!'
                : hasDeliveryLocation
                ? 'Awaiting pickup'
                : 'Tracking your order',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasRiderLocation
                ? 'Your order will arrive soon'
                : 'We\'ll notify you when it\'s ready',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    // ✅ FIX: Added 'placed' as first status (orders are created with 'placed' status)
    final statuses = [
      {'key': 'placed', 'label': 'Order Placed', 'icon': Icons.receipt_long},
      {'key': 'confirmed', 'label': 'Confirmed', 'icon': Icons.check_circle},
      {'key': 'preparing', 'label': 'Preparing', 'icon': Icons.restaurant},
      {'key': 'ready', 'label': 'Ready', 'icon': Icons.inventory_2},
      {'key': 'picked_up', 'label': 'Picked Up', 'icon': Icons.delivery_dining},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.done_all},
    ];

    // Normalize status - handle both 'pending' and 'placed'
    String normalizedStatus = currentStatus.toLowerCase();
    if (normalizedStatus == 'pending') {
      normalizedStatus = 'placed';
    }

    final currentIndex = statuses.indexWhere(
      (s) => s['key'] == normalizedStatus,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isCompleted = currentIndex >= 0 && index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? const Color(0xFFFF6B00)
                            : Colors.grey[300],
                        border: isCurrent
                            ? Border.all(
                                color: const Color(0xFFFF6B00),
                                width: 3,
                              )
                            : null,
                      ),
                      child: Icon(
                        status['icon'] as IconData,
                        size: 16,
                        color: isCompleted ? Colors.white : Colors.grey,
                      ),
                    ),
                    if (index < statuses.length - 1)
                      Container(
                        width: 2,
                        height: 24,
                        color: isCompleted
                            ? const Color(0xFFFF6B00)
                            : Colors.grey[300],
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status['label'] as String,
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRiderInfo(Map<String, dynamic> rider) {
    final name = rider['name'] ?? rider['firstName'] ?? 'Rider';
    final phone = rider['phone'] ?? rider['profile']?['phone'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Color(0xFFFF6B00),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Rider',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (phone != null)
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                  ],
                ),
              ),
              // Call button
              if (phone != null)
                IconButton(
                  onPressed: () async {
                    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch phone dialer'),
                          ),
                        );
                      }
                    }
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, color: Colors.green),
                  ),
                ),
              // Chat button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RiderChatScreen(
                        orderId: widget.orderId,
                        rider: rider,
                      ),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Chat with Rider button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RiderChatScreen(orderId: widget.orderId, rider: rider),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Rider'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String qrToken) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Delivery QR Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Show this to the rider to confirm delivery',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF6B00), width: 2),
            ),
            child: QrImageView(
              data: qrToken,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFFFF6B00),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ NEW: Build multi-vendor order items grouped by vendor
  Widget _buildMultiVendorOrderItems() {
    return Column(
      children: [
        for (int i = 0; i < _groupOrders.length; i++)
          _buildVendorOrderCard(_groupOrders[i], i + 1),

        // Group Total
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF6B00)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '₦${_formatNumber(_groupTotal)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Single vendor order card for multi-vendor display
  Widget _buildVendorOrderCard(Map<String, dynamic> order, int vendorNumber) {
    final vendor = order['vendorId'];
    final vendorName =
        order['vendorName'] ??
        vendor?['businessName'] ??
        vendor?['storeName'] ??
        'Vendor $vendorNumber';
    final items = order['items'] as List? ?? [];
    final subtotal = order['subtotal'] ?? order['total'] ?? 0;
    final status = order['status'] ?? 'placed';
    final orderId = order['_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$vendorNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Order #${_getShortId(orderId)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFF6B00,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${item['quantity'] ?? item['qty'] ?? 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B00),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['name'] ??
                                item['productId']?['name'] ??
                                'Item',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '₦${_formatNumber(item['price'] ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '₦${_formatNumber(subtotal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(List items, dynamic total) {
    final vendorName =
        _order?['vendorName'] ??
        _order?['vendorId']?['businessName'] ??
        _order?['vendorId']?['storeName'] ??
        'Vendor';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Show vendor name
          Row(
            children: [
              const Icon(Icons.store, color: Color(0xFFFF6B00), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vendorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Order Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${item['quantity'] ?? item['qty'] ?? 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B00),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'] ?? item['productId']?['name'] ?? 'Item',
                    ),
                  ),
                  Text(
                    '₦${_formatNumber(item['price'] ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '₦${_formatNumber(total)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getShortId(String id) {
    return id.length > 6
        ? id.substring(id.length - 6).toUpperCase()
        : id.toUpperCase();
  }

  bool _isActiveStatus(String status) {
    return ![
      'delivered',
      'completed',
      'cancelled',
    ].contains(status.toLowerCase());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return Colors.blue;
      case 'confirmed':
        return Colors.purple;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'picked_up':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Placed';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'picked_up':
        return 'Picked Up';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatNumber(dynamic number) {
    final n = number is int
        ? number
        : (number is num
              ? number.toInt()
              : int.tryParse(number.toString()) ?? 0);
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
