import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_client.dart';

/// WebView screen to load event-frontend pages
class EventWebViewScreen extends StatefulWidget {
  final String initialPage;
  final String? title;

  const EventWebViewScreen({
    super.key,
    this.initialPage = 'home.html',
    this.title,
  });

  @override
  State<EventWebViewScreen> createState() => _EventWebViewScreenState();
}

class _EventWebViewScreenState extends State<EventWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentTitle = 'QuickServe Event';
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title ?? 'QuickServe Event';
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Update title based on page
            _updateTitle(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            _showError(error.description);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation within our app
            if (request.url.contains('paystack.co')) {
              // Allow Paystack payment pages
              return NavigationDecision.navigate;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJsBridge(message.message);
        },
      )
      ..loadRequest(Uri.parse(_buildUrl(widget.initialPage)));
  }

  String _buildUrl(String page) {
    // Use the discovered backend URL
    final baseUrl = kApiBase.replaceAll('/api', '');
    return '$baseUrl/event-frontend/$page';
  }

  void _updateTitle(String url) {
    final pageTitles = {
      'home.html': 'QuickServe Home',
      'restaurants.html': 'Restaurants',
      'shops.html': 'Shops',
      'pharmacies.html': 'Pharmacies',
      'markets.html': 'Markets',
      'checkout.html': 'Checkout',
      'track.html': 'Track Order',
      'profile.html': 'My Profile',
      'vendor-dashboard.html': 'Vendor Dashboard',
      'dispatcher-dashboard.html': 'Dispatcher Dashboard',
      'admin.html': 'Admin Dashboard',
    };

    for (final entry in pageTitles.entries) {
      if (url.contains(entry.key)) {
        setState(() {
          _currentTitle = entry.value;
        });
        break;
      }
    }
  }

  void _handleJsBridge(String message) {
    // Handle messages from JavaScript
    debugPrint('JS Bridge message: $message');

    if (message.startsWith('navigate:')) {
      final page = message.replaceFirst('navigate:', '');
      _controller.loadRequest(Uri.parse(_buildUrl(page)));
    } else if (message == 'goBack') {
      Navigator.of(context).pop();
    } else if (message.startsWith('token:')) {
      // Handle auth token from web
      final token = message.replaceFirst('token:', '');
      _saveToken(token);
    }
  }

  Future<void> _saveToken(String token) async {
    // Save token to shared preferences for native screens
    // This allows seamless auth between WebView and native
    debugPrint('Received auth token from web');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading page: $message'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _controller.reload();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              _controller.loadRequest(Uri.parse(_buildUrl(value)));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'home.html', child: Text('Home')),
              const PopupMenuItem(
                value: 'restaurants.html',
                child: Text('Restaurants'),
              ),
              const PopupMenuItem(value: 'shops.html', child: Text('Shops')),
              const PopupMenuItem(value: 'checkout.html', child: Text('Cart')),
              const PopupMenuItem(
                value: 'profile.html',
                child: Text('Profile'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            LinearProgressIndicator(
              value: _loadingProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6B00),
              ),
            ),
        ],
      ),
    );
  }
}

/// Quick launcher for specific event pages
class EventPages {
  static const String home = 'home.html';
  static const String restaurants = 'restaurants.html';
  static const String shops = 'shops.html';
  static const String pharmacies = 'pharmacies.html';
  static const String markets = 'markets.html';
  static const String checkout = 'checkout.html';
  static const String track = 'track.html';
  static const String profile = 'profile.html';
  static const String vendorDashboard = 'vendor-dashboard.html';
  static const String dispatcherDashboard = 'dispatcher-dashboard.html';
  static const String adminDashboard = 'admin.html';
  static const String login = 'login.html';
  static const String signup = 'signup.html';
}

/// Extension for easy navigation
extension EventWebViewNavigation on BuildContext {
  void openEventPage(String page, {String? title}) {
    Navigator.of(this).push(
      MaterialPageRoute(
        builder: (_) => EventWebViewScreen(initialPage: page, title: title),
      ),
    );
  }

  void openEventHome() => openEventPage(EventPages.home, title: 'QuickServe');
  void openRestaurants() =>
      openEventPage(EventPages.restaurants, title: 'Restaurants');
  void openShops() => openEventPage(EventPages.shops, title: 'Shops');
  void openCheckout() => openEventPage(EventPages.checkout, title: 'Checkout');
  void openOrderTracking() =>
      openEventPage(EventPages.track, title: 'Track Order');
}
