import 'package:flutter/material.dart';
import '../../models/subscription.dart';
import 'menu_page.dart';
import 'student_verification_page.dart';

/// QuickServe Special Meal Subscription Page
/// Shows hero section with food watermark, and Corporate/Student tabs
/// with Basic, Standard, and Premium plans
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isStudentVerified = false; // Track student verification status

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkStudentVerification();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkStudentVerification() async {
    // TODO: Check from backend/local storage if user is verified student
    // For now, default to false
    setState(() {
      _isStudentVerified = false;
    });
  }

  void _navigateToMenu(SubscriptionPlan plan) {
    // If student plan and not verified, show verification first
    if (plan.category == SubscriptionCategory.student && !_isStudentVerified) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentVerificationPage(
            onVerified: () {
              setState(() {
                _isStudentVerified = true;
              });
              Navigator.pop(context);
              // After verification, navigate to menu
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MenuPage(plan: plan)),
              );
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MenuPage(plan: plan)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Custom App Bar with back button
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              title: const Text('Special Meal Subscription'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Hero Section
            SliverToBoxAdapter(child: _buildHeroSection()),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFF6B00),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFFFF6B00),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.business), text: 'CORPORATE'),
                    Tab(icon: Icon(Icons.school), text: 'STUDENT'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Corporate Plans
            _buildPlansGrid(CorporatePlans.all),

            // Student Plans
            _buildPlansGrid(StudentPlans.all, isStudent: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Food watermark background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.transparent),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QuickServe Special Meal Offers',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Benefits list
                _buildBenefitItem(
                  'ðŸ’°',
                  'Affordable Meals',
                  'Budget-friendly daily meals',
                ),
                _buildBenefitItem(
                  'ðŸšš',
                  'On-Time Delivery',
                  'Always delivered on schedule',
                ),
                _buildBenefitItem(
                  'ðŸ’µ',
                  'Cashback Rewards',
                  'Earn cashback on subscriptions',
                ),
                _buildBenefitItem(
                  'ðŸ½ï¸',
                  'Fresh & Hygienic',
                  'Quality meals prepared daily',
                ),
                _buildBenefitItem(
                  'ðŸ“…',
                  'Flexible Scheduling',
                  'Choose your preferred meal times',
                ),
                _buildBenefitItem(
                  'ðŸ˜Œ',
                  'No Cooking Stress',
                  'Let us handle your meals',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String emoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansGrid(
    List<SubscriptionPlan> plans, {
    bool isStudent = false,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isStudent && !_isStudentVerified)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Student verification required to access these plans',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          ...plans.map((plan) => _buildPlanCard(plan)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final bool isPopular = plan.type == SubscriptionPlanType.standard;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular
            ? Border.all(color: const Color(0xFFFF6B00), width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? const Color(0xFFFF6B00).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Popular badge
          if (isPopular)
            Positioned(
              top: 0,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B00),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan name and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPlanColor(plan.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPlanIcon(plan.type),
                        color: _getPlanColor(plan.type),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${plan.planName} Plan',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${plan.mealsPerDay} meal${plan.mealsPerDay > 1 ? 's' : ''} per day',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pricing
                Row(
                  children: [
                    Expanded(
                      child: _buildPriceBox(
                        'Weekly',
                        formatNaira(plan.weeklyPrice),
                        '${formatNaira(plan.weeklyCashback)} cashback',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPriceBox(
                        'Monthly',
                        formatNaira(plan.monthlyPrice),
                        '${formatNaira(plan.monthlyCashback)} cashback',
                        isHighlighted: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Features
                ...plan.features
                    .take(3)
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CAF50),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                const SizedBox(height: 16),

                // Read More Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToMenu(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? const Color(0xFFFF6B00)
                          : Colors.grey.shade100,
                      foregroundColor: isPopular
                          ? Colors.white
                          : Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isPopular ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Menu & Subscribe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBox(
    String label,
    String price,
    String cashback, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFFF6B00).withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? const Color(0xFFFF6B00) : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              cashback,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlanColor(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.basic:
        return Colors.blue;
      case SubscriptionPlanType.standard:
        return const Color(0xFFFF6B00);
      case SubscriptionPlanType.premium:
        return Colors.purple;
    }
  }

  IconData _getPlanIcon(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.basic:
        return Icons.star_outline;
      case SubscriptionPlanType.standard:
        return Icons.star_half;
      case SubscriptionPlanType.premium:
        return Icons.star;
    }
  }
}

/// Tab Bar Delegate for sticky tabs
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
