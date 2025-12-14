import 'package:flutter/material.dart';
import 'event_webview_screen.dart';
import 'event_native_home_screen.dart';

/// Event launcher screen - main entry point for event functionality
class EventLauncherScreen extends StatelessWidget {
  const EventLauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Q',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'QuickServe',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'EVENT EDITION',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 40),

              // Main Actions
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose your experience',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select how you want to browse the event',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Native App Option
                        _ExperienceCard(
                          icon: Icons.phone_android,
                          title: 'Native App',
                          subtitle: 'Fast & optimized Flutter experience',
                          color: const Color(0xFFFF6B00),
                          badge: 'RECOMMENDED',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EventNativeHomeScreen(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // WebView Option
                        _ExperienceCard(
                          icon: Icons.web,
                          title: 'Web View',
                          subtitle: 'Full web-based experience',
                          color: const Color(0xFF2196F3),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EventWebViewScreen(
                                  initialPage: 'home.html',
                                  title: 'QuickServe Event',
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 20),

                        // Quick Access
                        const Text(
                          'Quick Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _CategoryCard(
                              icon: Icons.restaurant,
                              label: 'Restaurants',
                              color: const Color(0xFFFF6B00),
                              onTap: () => _openWebPage(
                                context,
                                EventPages.restaurants,
                                'Restaurants',
                              ),
                            ),
                            _CategoryCard(
                              icon: Icons.shopping_basket,
                              label: 'Shops',
                              color: const Color(0xFF4CAF50),
                              onTap: () => _openWebPage(
                                context,
                                EventPages.shops,
                                'Shops',
                              ),
                            ),
                            _CategoryCard(
                              icon: Icons.local_pharmacy,
                              label: 'Pharmacy',
                              color: const Color(0xFF2196F3),
                              onTap: () => _openWebPage(
                                context,
                                EventPages.pharmacies,
                                'Pharmacies',
                              ),
                            ),
                            _CategoryCard(
                              icon: Icons.storefront,
                              label: 'Markets',
                              color: const Color(0xFF9C27B0),
                              onTap: () => _openWebPage(
                                context,
                                EventPages.markets,
                                'Markets',
                              ),
                            ),
                            _CategoryCard(
                              icon: Icons.local_shipping,
                              label: 'Packages',
                              color: const Color(0xFF795548),
                              onTap: () => _openWebPage(
                                context,
                                'send-packages.html',
                                'Send Packages',
                              ),
                            ),
                            _CategoryCard(
                              icon: Icons.track_changes,
                              label: 'Track',
                              color: const Color(0xFF607D8B),
                              onTap: () => _openWebPage(
                                context,
                                EventPages.track,
                                'Track Order',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),
                        const Divider(),
                        const SizedBox(height: 20),

                        // Dashboard Access
                        const Text(
                          'Dashboard Access',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _DashboardCard(
                                icon: Icons.store,
                                label: 'Vendor',
                                color: const Color(0xFF667eea),
                                onTap: () => _openWebPage(
                                  context,
                                  EventPages.vendorDashboard,
                                  'Vendor Dashboard',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DashboardCard(
                                icon: Icons.delivery_dining,
                                label: 'Dispatcher',
                                color: const Color(0xFF4CAF50),
                                onTap: () => _openWebPage(
                                  context,
                                  EventPages.dispatcherDashboard,
                                  'Dispatcher',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DashboardCard(
                                icon: Icons.admin_panel_settings,
                                label: 'Admin',
                                color: const Color(0xFFE91E63),
                                onTap: () => _openWebPage(
                                  context,
                                  EventPages.adminDashboard,
                                  'Admin',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWebPage(BuildContext context, String page, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventWebViewScreen(initialPage: page, title: title),
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
