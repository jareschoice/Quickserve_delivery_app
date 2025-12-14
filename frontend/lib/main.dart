import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'widgets/bottom_nav.dart';
import 'screens/home/vendor_home.dart';
import 'screens/home/rider_home.dart';
import 'screens/home/admin_home.dart';
import 'screens/home/place_order.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_tracking_screen.dart';
import 'screens/special_meals/special_meals_screen.dart';
import 'screens/special_meals/subscription_page.dart';
import 'screens/special_meals/menu_page.dart';
import 'screens/special_meals/schedule_page.dart';
import 'screens/special_meals/order_summary_page.dart';
import 'screens/special_meals/student_verification_page.dart';
import 'screens/special_meals/my_subscriptions_page.dart';
import 'screens/wallet/wallet_page.dart';
import 'screens/search/search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/support/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'models/user.dart';
import 'models/subscription.dart';
import 'services/socket_service.dart';
import 'services/offline_service.dart';
import 'screens/special_meals/subscription_success_screen.dart';
import 'config/app_theme.dart';
import 'config/app_localization.dart';
import 'widgets/q_logo_widget.dart';

// Conditionally import Firebase only on mobile
import 'services/firebase_init.dart'
    if (dart.library.html) 'services/firebase_init_stub.dart';

// Global providers
final ThemeProvider themeProvider = ThemeProvider();
final LocaleProvider localeProvider = LocaleProvider();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on mobile platforms
  await initializeFirebase();

  // Initialize offline service
  await OfflineService().initialize();

  // Connect to Socket.IO
  SocketService().connect();

  runApp(const QuickServeApp());
}

class QuickServeApp extends StatefulWidget {
  const QuickServeApp({super.key});

  @override
  State<QuickServeApp> createState() => _QuickServeAppState();
}

class _QuickServeAppState extends State<QuickServeApp> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    themeProvider.addListener(_onThemeChanged);
    localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});
  void _onLocaleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickServe',
      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Locale configuration
      locale: localeProvider.locale,
      supportedLocales: AppLocales.supportedLocales,
      // Use initialRoute instead of home to allow deep linking to work properly
      initialRoute: '/',
      routes: {
        '/': (_) => const CustomSplashScreen(),
        '/auth': (_) => const LoginScreen(),
        '/register': (_) => const SignupScreen(), // Use the new signup screen
        '/verify': (_) => const VerifyEmailScreen(email: ''),
        '/place-order': (_) => const PlaceOrderScreen(),
        '/home': (_) => const MainNavigation(), // Directly to consumer home
        '/orders': (_) => const OrdersScreen(),
        '/special-meals': (_) =>
            const SubscriptionPage(), // New subscription page
        '/special-meals-legacy': (_) =>
            const SpecialMealsScreen(), // Keep old for reference
        '/my-subscriptions': (_) =>
            const MySubscriptionsPage(), // User's subscription history
        '/wallet': (_) => const WalletPage(),
        '/student-verify': (context) => StudentVerificationPage(
          onVerified: () => Navigator.of(context).pop(true),
        ),
        '/search': (_) => const SearchScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/support': (_) => const ChatScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle subscription page with query parameters (e.g. success redirect)
        if (settings.name?.startsWith('/special-meals') == true) {
          // Check if it has query params
          final uri = Uri.parse(settings.name!);
          if (uri.queryParameters.containsKey('status') &&
              uri.queryParameters['status'] == 'success') {
            final subId = uri.queryParameters['subId'];
            if (subId != null) {
              return MaterialPageRoute(
                builder: (_) => SubscriptionSuccessScreen(subId: subId),
              );
            }
          }
          // Default fallback
          return MaterialPageRoute(builder: (_) => const SubscriptionPage());
        }

        // Handle order tracking with orderId parameter
        if (settings.name?.startsWith('/track/') == true) {
          final orderId = settings.name!.substring('/track/'.length);
          return MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(orderId: orderId),
          );
        }

        // Handle subscription menu page with plan parameter
        if (settings.name?.startsWith('/special-meals/menu') == true) {
          final plan = settings.arguments as SubscriptionPlan?;
          if (plan != null) {
            return MaterialPageRoute(builder: (_) => MenuPage(plan: plan));
          }
        }

        // Handle subscription schedule page with plan parameter
        if (settings.name?.startsWith('/special-meals/schedule') == true) {
          final plan = settings.arguments as SubscriptionPlan?;
          if (plan != null) {
            return MaterialPageRoute(builder: (_) => SchedulePage(plan: plan));
          }
        }

        // Handle order summary page with order parameter
        if (settings.name?.startsWith('/special-meals/summary') == true) {
          final order = settings.arguments as SubscriptionOrder?;
          if (order != null) {
            return MaterialPageRoute(
              builder: (_) => OrderSummaryPage(order: order),
            );
          }
        }

        return null;
      },
    );
  }
}

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});
  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Show splash briefly (2 seconds) - enough to see the branding
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Check if we are already on a deep link path (e.g. /track/...)
    // If the current route is NOT '/', we shouldn't force navigation to /home
    // However, on web, the initial route is handled by the framework before this widget builds if we use initialRoute.
    // But since we are IN the splash screen (mapped to '/'), we need to decide where to go.

    // If the user just opened the app (root), go to home.
    // If the user opened a deep link, Flutter's router should have handled it?
    // Actually, if we use initialRoute: '/', Flutter will push '/' onto the stack.
    // If the URL was /track/123, Flutter parses it.
    // If we are here, it means the route is '/'.

    // Simple check: just go to home. Deep links usually bypass '/' if configured correctly,
    // OR they stack on top.
    // But to be safe, we use pushReplacementNamed.

    // FIX: Only navigate if this route is the current top route.
    // If a deep link (like /track/...) was pushed on top, isCurrent will be false.
    if (ModalRoute.of(context)?.isCurrent != true) return;

    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF6B00), // Orange background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Q Logo at the top
              const QLogoWidget(size: 100),
              const SizedBox(height: 24),
              // QUICKSERVE text in Golden
              const Text(
                "QUICKSERVE",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700), // Gold text
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks the correct home by saved role (consumer/vendor/rider).
class RoleHomeDecider extends StatelessWidget {
  const RoleHomeDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final roleStr = snap.data!.getString('role');
        final role = roleFromString(roleStr) ?? UserRole.consumer;
        switch (role) {
          case UserRole.consumer:
            // Return the main navigation widget (includes bottom nav and app screens)
            return const MainNavigation();
          case UserRole.vendor:
            return const VendorHome();
          case UserRole.rider:
            return const RiderHome();
          case UserRole.admin:
            return const AdminHome();
        }
      },
    );
  }
}
