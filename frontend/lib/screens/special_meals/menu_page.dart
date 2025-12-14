import 'package:flutter/material.dart';
import '../../models/subscription.dart';
import 'multi_day_schedule_page.dart';

/// Menu Page - Shows all available meals for a selected plan
/// Displays food images in a grid with schedule times info
class MenuPage extends StatefulWidget {
  final SubscriptionPlan plan;

  const MenuPage({super.key, required this.plan});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Set initial tab based on selected plan
    _selectedTabIndex = widget.plan.type.index;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<MenuItem> _getMenuForTab(int index) {
    switch (index) {
      case 0:
        return MenuData.basicMenu;
      case 1:
        return MenuData.standardMenu;
      case 2:
        return MenuData.premiumMenu;
      default:
        return MenuData.basicMenu;
    }
  }

  SubscriptionPlanType _getPlanTypeForTab(int index) {
    switch (index) {
      case 0:
        return SubscriptionPlanType.basic;
      case 1:
        return SubscriptionPlanType.standard;
      case 2:
        return SubscriptionPlanType.premium;
      default:
        return SubscriptionPlanType.basic;
    }
  }

  SubscriptionPlan _getPlanForTab(int index) {
    final planType = _getPlanTypeForTab(index);
    if (widget.plan.category == SubscriptionCategory.corporate) {
      switch (planType) {
        case SubscriptionPlanType.basic:
          return CorporatePlans.basic;
        case SubscriptionPlanType.standard:
          return CorporatePlans.standard;
        case SubscriptionPlanType.premium:
          return CorporatePlans.premium;
      }
    } else {
      switch (planType) {
        case SubscriptionPlanType.basic:
          return StudentPlans.basic;
        case SubscriptionPlanType.standard:
          return StudentPlans.standard;
        case SubscriptionPlanType.premium:
          return StudentPlans.premium;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '${widget.plan.categoryName} Menu',
                style: const TextStyle(fontSize: 18),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Plan Info Header
          SliverToBoxAdapter(child: _buildPlanInfoHeader()),

          // Schedule Times Info
          SliverToBoxAdapter(child: _buildScheduleTimesInfo()),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _MenuTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF6B00),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF6B00),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'BASIC'),
                  Tab(text: 'STANDARD'),
                  Tab(text: 'PREMIUM'),
                ],
              ),
            ),
          ),

          // Menu Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final menu = _getMenuForTab(_selectedTabIndex);
                if (index >= menu.length) return null;
                return _buildMenuCard(menu[index]);
              }, childCount: _getMenuForTab(_selectedTabIndex).length),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildPlanInfoHeader() {
    final currentPlan = _getPlanForTab(_selectedTabIndex);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.plan.category == SubscriptionCategory.corporate
                  ? Icons.business
                  : Icons.school,
              color: const Color(0xFFFF6B00),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentPlan.categoryName} ${currentPlan.planName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentPlan.mealsPerDay} meal${currentPlan.mealsPerDay > 1 ? 's' : ''} per day',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNaira(currentPlan.weeklyPrice),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B00),
                ),
              ),
              Text(
                '/week',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimesInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivery Schedule Times',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTimeSlot('🌅', 'Breakfast', '9:00 AM - 11:30 AM'),
              const SizedBox(width: 8),
              _buildTimeSlot('☀️', 'Lunch', '1:00 PM - 3:00 PM'),
              const SizedBox(width: 8),
              _buildTimeSlot('🌙', 'Dinner', '6:00 PM - 8:30 PM'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.plan.category == SubscriptionCategory.corporate
                        ? 'Corporate plans: Choose 1 meal time per day'
                        : 'Student plans: Choose 2 meal times per day',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String emoji, String label, String time) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
            Text(
              time,
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(MenuItem item) {
    // Get food image URL based on item name
    final imageUrl = _getFoodImageUrl(item.name);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFFFF6B00),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                  // Protein badges
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Wrap(
                      spacing: 4,
                      children: item.availableProteins.map((protein) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            getProteinEmoji(protein),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Food Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+ ${_formatProteins(item.availableProteins)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatProteins(List<ProteinOption> proteins) {
    final names = proteins.map((p) {
      switch (p) {
        case ProteinOption.beef:
          return 'Beef';
        case ProteinOption.fish:
          return 'Fish';
        case ProteinOption.chicken:
          return 'Chicken';
        case ProteinOption.turkey:
          return 'Turkey';
      }
    }).toList();

    if (names.length == 1) return names[0];
    if (names.length == 2) return '${names[0]} or ${names[1]}';
    return '${names.sublist(0, names.length - 1).join(', ')} or ${names.last}';
  }

  String _getFoodImageUrl(String foodName) {
    // Map food names to real food images
    final foodImages = {
      'Rice & Stew':
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400',
      'Jollof Rice':
          'https://images.unsplash.com/photo-1604329760661-e71dc83f8f26?w=400',
      'Fried Jollof Rice':
          'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=400',
      'Pasta':
          'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=400',
      'Semo': 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=400',
      'Amala':
          'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=400',
      'Eba': 'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=400',
      'Beans & Bread':
          'https://images.unsplash.com/photo-1585325701956-60dd9c8553bc?w=400',
      'Rice & Beans':
          'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=400',
      'Yam Porridge':
          'https://images.unsplash.com/photo-1574484284002-952d92456975?w=400',
      'Yam & Egg':
          'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
      'Basmati Rice':
          'https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6?w=400',
      'Poundo Yam':
          'https://images.unsplash.com/photo-1546549032-9571cd6b27df?w=400',
    };

    return foodImages[foodName] ??
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400';
  }

  Widget _buildBottomBar() {
    final currentPlan = _getPlanForTab(_selectedTabIndex);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentPlan.planName} Plan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'From ${formatNaira(currentPlan.weeklyPrice)}/week',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MultiDaySchedulePage(plan: currentPlan),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: const Text('Schedule Meals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab Bar Delegate
class _MenuTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _MenuTabBarDelegate(this.tabBar);

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
  bool shouldRebuild(covariant _MenuTabBarDelegate oldDelegate) => false;
}
