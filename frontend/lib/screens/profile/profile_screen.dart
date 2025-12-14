import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/config.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/socket_service.dart';
import '../rewards/referral_loyalty_screen.dart';
import '../chat/chat_support_screen.dart';
import 'address_management_screen.dart';

/// ProfileScreen - Full profile management with real features
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SocketService _socketService = SocketService();

  bool _isLoggedIn = false;
  bool _loading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _userId = '';
  String? _profileImage;
  String _backendBaseUrl = AppConfig.backendBaseUrl;
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _favorites = [];

  // Notification settings
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newRestaurants = false;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _initBackendUrl();
    _loadProfile();
    _setupSocketListeners();
  }

  Future<void> _initBackendUrl() async {
    try {
      final url = await ApiClient.getCurrentBackendUrl();
      if (mounted) {
        setState(() => _backendBaseUrl = url);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _removeSocketListeners();
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.connect();

    _socketService.on('user:updated', (data) {
      debugPrint('User profile updated: $data');
      if (mounted) _loadProfile();
    });
  }

  void _removeSocketListeners() {
    _socketService.off('user:updated');
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) {
      return '$_backendBaseUrl$url';
    }
    return '$_backendBaseUrl/$url';
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoggedIn = false;
        _loading = false;
      });
      return;
    }

    // Load cached values first as fallback
    final cachedName = prefs.getString('fullName') ?? '';
    final cachedEmail = prefs.getString('email') ?? '';

    try {
      // Fetch full user profile from backend
      final data = await ApiClient().getJson('/auth/me');
      final user = data['user'] ?? {};

      setState(() {
        _isLoggedIn = true;
        // Use API value or fallback to cached value
        _name = (user['name'] as String?)?.isNotEmpty == true
            ? user['name']
            : cachedName;
        _email = (user['email'] as String?)?.isNotEmpty == true
            ? user['email']
            : cachedEmail;

        // Handle nested profile data safely
        final profile = user['profile'];
        if (profile is Map) {
          _phone = profile['phone'] ?? user['phone'] ?? '';
          _profileImage = profile['avatarUrl'];
        } else {
          _phone = user['phone'] ?? '';
          _profileImage = null;
        }

        _userId = user['id'] ?? user['_id'] ?? '';
        _loading = false;
      });

      // Load addresses
      _loadAddresses();
      // Load favorites
      _loadFavorites();
      // Load notification settings
      _loadNotificationSettings();

      // Join user room for real-time updates
      if (_userId.isNotEmpty) {
        _socketService.joinRoom('user:$_userId');
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoggedIn = false;
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _uploadImage(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() => _loading = true);
    try {
      final bytes = await image.readAsBytes();
      final response = await ApiClient().uploadBytes(
        '/users/upload-avatar',
        bytes,
        image.name,
      );

      if (mounted) {
        // Backend returns { url: '...', message: '...' } on success
        if (response['url'] != null ||
            response['avatarUrl'] != null ||
            response['ok'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated')),
          );
          _loadProfile(); // Reload to show new image
        } else {
          throw Exception(response['error'] ?? 'Upload failed');
        }
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final data = await ApiClient().getJson('/users/addresses');
      if (mounted) {
        setState(() {
          _addresses =
              (data['addresses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load addresses: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final data = await ApiClient().getJson('/users/favorites');
      if (mounted) {
        setState(() {
          _favorites =
              (data['favorites'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final data = await ApiClient().getJson('/users/notifications/settings');
      if (mounted && data['settings'] != null) {
        final settings = data['settings'];
        setState(() {
          _orderUpdates = settings['orderUpdates'] ?? true;
          _promotions = settings['promotions'] ?? true;
          _newRestaurants = settings['newRestaurants'] ?? false;
          _emailNotifications = settings['emailNotifications'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load notification settings: $e');
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    try {
      final Map<String, bool> settings = {
        'orderUpdates': _orderUpdates,
        'promotions': _promotions,
        'newRestaurants': _newRestaurants,
        'emailNotifications': _emailNotifications,
      };
      settings[key] = value;

      await ApiClient().putJson('/users/notifications/settings', settings);

      if (!mounted) {
        return;
      }

      setState(() {
        switch (key) {
          case 'orderUpdates':
            _orderUpdates = value;
            break;
          case 'promotions':
            _promotions = value;
            break;
          case 'newRestaurants':
            _newRestaurants = value;
            break;
          case 'emailNotifications':
            _emailNotifications = value;
            break;
        }
      });
    } catch (e) {
      debugPrint('Failed to update notification setting: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update setting')));
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _name = '';
          _email = '';
          _phone = '';
          _userId = '';
          _addresses = [];
          _favorites = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    if (!_isLoggedIn) {
      return _buildGuestProfile();
    }

    return _buildLoggedInProfile();
  }

  Widget _buildGuestProfile() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00), Color(0xFFFFD700)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Q',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QuickServe',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Order Food Fast',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 60,
                          color: Color(0xFFFF6B00),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome, Guest!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access your profile,\norders, and saved addresses.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/auth'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B00),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF6B00),
                              side: const BorderSide(
                                color: Color(0xFFFF6B00),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInProfile() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfile,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: const Color(0xFFFF6B00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? NetworkImage(_resolveImageUrl(_profileImage!))
                                : null,
                            child: _profileImage == null
                                ? Text(
                                    _name.isNotEmpty
                                        ? _name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF6B00),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFFFF6B00),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name.isNotEmpty ? _name : 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Menu items
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      subtitle: 'View your order history',
                      onTap: () => _navigateToOrders(),
                    ),
                    _buildMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Favorites',
                      subtitle: '${_favorites.length} saved restaurants',
                      trailing: _favorites.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B00),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_favorites.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      onTap: _showFavorites,
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Addresses',
                      subtitle: '${_addresses.length} saved addresses',
                      trailing: _addresses.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B00),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_addresses.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressManagementScreen(),
                          ),
                        ).then((_) => _loadAddresses());
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.card_giftcard_outlined,
                      title: 'Rewards & Referrals',
                      subtitle: 'Earn points, refer friends',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReferralLoyaltyScreen(),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.payment_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage your payment options',
                      onTap: _showPaymentMethods,
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: _showNotificationSettings,
                    ),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      onTap: _showSettings,
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get help with your orders',
                      onTap: _showHelpSupport,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'QuickServe v1.0.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B00)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            trailing ??
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _navigateToOrders() {
    // Navigate to orders screen directly
    Navigator.pushNamed(context, '/orders');
  }

  void _showEditProfile() {
    final rootContext = context;
    showModalBottomSheet(
      context: rootContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EditProfileSheet(
        name: _name,
        email: _email,
        phone: _phone,
        onSave: (name, phone) async {
          try {
            await ApiClient().putJson('/users/profile', {
              'name': name,
              'phone': phone,
            });
            if (!sheetContext.mounted) {
              return;
            }
            Navigator.pop(sheetContext);
            if (!mounted) {
              return;
            }
            _loadProfile();
            ScaffoldMessenger.of(rootContext).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          } catch (e) {
            debugPrint('Failed to update profile: $e');
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(
              rootContext,
            ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
          }
        },
      ),
    );
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Color(0xFFFF6B00)),
                  const SizedBox(width: 12),
                  const Text(
                    'Favorites',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _favorites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No favorites yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _favorites.length,
                      itemBuilder: (context, index) {
                        final fav = _favorites[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFFF6B00,
                              ).withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.store,
                                color: Color(0xFFFF6B00),
                              ),
                            ),
                            title: Text(fav['name'] ?? 'Restaurant'),
                            subtitle: Text(fav['address'] ?? ''),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeFavorite(fav['_id']),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'Online Payment',
              subtitle: 'Card, Bank Transfer, USSD',
              isActive: true,
            ),
            _buildPaymentOption(
              icon: Icons.account_balance_wallet,
              title: 'Wallet',
              subtitle: 'QuickServe wallet balance',
              isActive: true,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/wallet');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFFFF6B00) : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
        onTap: isActive ? onTap : null,
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Order Updates'),
                subtitle: const Text('Get notified about your order status'),
                value: _orderUpdates,
                activeThumbColor: const Color(0xFFFF6B00),
                onChanged: (value) {
                  setModalState(() => _orderUpdates = value);
                  _updateNotificationSetting('orderUpdates', value);
                },
              ),
              SwitchListTile(
                title: const Text('Promotions'),
                subtitle: const Text('Receive special offers and discounts'),
                value: _promotions,
                activeThumbColor: const Color(0xFFFF6B00),
                onChanged: (value) {
                  setModalState(() => _promotions = value);
                  _updateNotificationSetting('promotions', value);
                },
              ),
              SwitchListTile(
                title: const Text('New Restaurants'),
                subtitle: const Text('Know when new vendors join'),
                value: _newRestaurants,
                activeThumbColor: const Color(0xFFFF6B00),
                onChanged: (value) {
                  setModalState(() => _newRestaurants = value);
                  _updateNotificationSetting('newRestaurants', value);
                },
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates via email'),
                value: _emailNotifications,
                activeThumbColor: const Color(0xFFFF6B00),
                onChanged: (value) {
                  setModalState(() => _emailNotifications = value);
                  _updateNotificationSetting('emailNotifications', value);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: false,
                onChanged: (v) {},
                activeThumbColor: const Color(0xFFFF6B00),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showAbout();
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, color: Color(0xFFFF6B00)),
                  const SizedBox(width: 12),
                  const Text(
                    'Help & Support',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHelpItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat with Us',
                    subtitle: 'Get instant support via chat',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatSupportScreen(),
                        ),
                      );
                    },
                  ),
                  _buildHelpItem(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    subtitle: 'support@getquickserves.com',
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'support@getquickserves.com',
                        query: 'subject=QuickServe Support Request',
                      );
                      try {
                        await launchUrl(emailUri);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Email: support@getquickserves.com',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _buildHelpItem(
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: '+234 812 345 6789',
                    onTap: () async {
                      Navigator.pop(context);
                      final Uri phoneUri = Uri(
                        scheme: 'tel',
                        path: '+2348123456789',
                      );
                      try {
                        await launchUrl(phoneUri);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Call: +234 812 345 6789'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'FAQs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildFAQItem(
                    question: 'How do I track my order?',
                    answer:
                        'Go to Orders in the bottom navigation, tap on your active order to see real-time tracking.',
                  ),
                  _buildFAQItem(
                    question: 'How do I cancel an order?',
                    answer:
                        'You can cancel an order within 2 minutes of placing it. Go to Orders and tap Cancel.',
                  ),
                  _buildFAQItem(
                    question: 'How do payments work?',
                    answer:
                        'We accept Paystack (cards, bank transfer, USSD) and cash on delivery.',
                  ),
                  _buildFAQItem(
                    question: 'How do I become a vendor?',
                    answer:
                        'Download the QuickServe Vendor app, register, complete KYC verification, and wait for approval.',
                  ),
                  _buildFAQItem(
                    question: 'How do I become a rider?',
                    answer:
                        'Download the QuickServe Rider app, register, complete KYC verification with your ID and vehicle documents.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF6B00)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFF6B00)),
            SizedBox(width: 8),
            Text('About QuickServe'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'QuickServe - Fast Food Delivery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'QuickServe connects you with local vendors for fast, fresh food delivery.',
            ),
            SizedBox(height: 16),
            Text(
              'Â© 2025 QuickServe. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFavorite(String? id) async {
    if (id == null) return;
    try {
      await ApiClient().deleteJson('/users/favorites/$id');
      _loadFavorites();
    } catch (e) {
      debugPrint('Failed to remove favorite: $e');
    }
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final Function(String name, String phone) onSave;

  const _EditProfileSheet({
    required this.name,
    required this.email,
    required this.phone,
    required this.onSave,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: widget.email,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  widget.onSave(_nameController.text, _phoneController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAddressDialog extends StatefulWidget {
  final Function(String label, String address) onSave;

  const _AddAddressDialog({required this.onSave});

  @override
  State<_AddAddressDialog> createState() => _AddAddressDialogState();
}

class _AddAddressDialogState extends State<_AddAddressDialog> {
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label (e.g., Home, Work)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Full Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () =>
              widget.onSave(_labelController.text, _addressController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
