/// QuickServe Special Meal Subscription Models
/// Contains all data models for subscription plans, menus, and schedules
library;

enum SubscriptionCategory { corporate, student }

enum SubscriptionPlanType { basic, standard, premium }

enum MealSession { breakfast, lunch, dinner }

enum ProteinOption { beef, fish, chicken, turkey }

/// Subscription Plan Model
class SubscriptionPlan {
  final SubscriptionPlanType type;
  final SubscriptionCategory category;
  final int weeklyPrice;
  final int monthlyPrice;
  final int mealsPerDay;
  final int weeklyCashback;
  final int monthlyCashback;
  final List<String> features;

  const SubscriptionPlan({
    required this.type,
    required this.category,
    required this.weeklyPrice,
    required this.monthlyPrice,
    required this.mealsPerDay,
    required this.weeklyCashback,
    required this.monthlyCashback,
    required this.features,
  });

  String get planName {
    switch (type) {
      case SubscriptionPlanType.basic:
        return 'Basic';
      case SubscriptionPlanType.standard:
        return 'Standard';
      case SubscriptionPlanType.premium:
        return 'Premium';
    }
  }

  String get categoryName {
    switch (category) {
      case SubscriptionCategory.corporate:
        return 'Corporate';
      case SubscriptionCategory.student:
        return 'Student';
    }
  }
}

/// All Corporate Plans
class CorporatePlans {
  static const basic = SubscriptionPlan(
    type: SubscriptionPlanType.basic,
    category: SubscriptionCategory.corporate,
    weeklyPrice: 10000,
    monthlyPrice: 40000,
    mealsPerDay: 1,
    weeklyCashback: 500,
    monthlyCashback: 2000,
    features: [
      '₦10,000 per week',
      '₦40,000 per month',
      '1 meal per day',
      '₦2,000 cashback on monthly',
      '₦500 cashback on weekly',
    ],
  );

  static const standard = SubscriptionPlan(
    type: SubscriptionPlanType.standard,
    category: SubscriptionCategory.corporate,
    weeklyPrice: 15000,
    monthlyPrice: 60000,
    mealsPerDay: 1,
    weeklyCashback: 1000,
    monthlyCashback: 3000,
    features: [
      '₦15,000 per week',
      '₦60,000 per month',
      '1 meal per day',
      '₦3,000 cashback on monthly',
      '₦1,000 cashback on weekly',
    ],
  );

  static const premium = SubscriptionPlan(
    type: SubscriptionPlanType.premium,
    category: SubscriptionCategory.corporate,
    weeklyPrice: 17500,
    monthlyPrice: 70000,
    mealsPerDay: 1,
    weeklyCashback: 2000,
    monthlyCashback: 5000,
    features: [
      '₦17,500 per week',
      '₦70,000 per month',
      '1 meal per day',
      '₦5,000 cashback on monthly',
      '₦2,000 cashback on weekly',
    ],
  );

  static List<SubscriptionPlan> get all => [basic, standard, premium];
}

/// All Student Plans
class StudentPlans {
  static const basic = SubscriptionPlan(
    type: SubscriptionPlanType.basic,
    category: SubscriptionCategory.student,
    weeklyPrice: 12500,
    monthlyPrice: 45000,
    mealsPerDay: 2,
    weeklyCashback: 500,
    monthlyCashback: 2000,
    features: [
      '₦12,500 per week',
      '₦45,000 per month',
      '2 meals per day',
      '₦2,000 cashback on monthly',
      '₦500 cashback on weekly',
    ],
  );

  static const standard = SubscriptionPlan(
    type: SubscriptionPlanType.standard,
    category: SubscriptionCategory.student,
    weeklyPrice: 18000,
    monthlyPrice: 70000,
    mealsPerDay: 2,
    weeklyCashback: 1000,
    monthlyCashback: 3000,
    features: [
      '₦18,000 per week',
      '₦70,000 per month',
      '2 meals per day',
      '₦3,000 cashback on monthly',
      '₦1,000 cashback on weekly',
    ],
  );

  static const premium = SubscriptionPlan(
    type: SubscriptionPlanType.premium,
    category: SubscriptionCategory.student,
    weeklyPrice: 25000,
    monthlyPrice: 100000,
    mealsPerDay: 2,
    weeklyCashback: 2000,
    monthlyCashback: 5000,
    features: [
      '₦25,000 per week',
      '₦100,000 per month',
      '2 meals per day',
      '₦5,000 cashback on monthly',
      '₦2,000 cashback on weekly',
    ],
  );

  static List<SubscriptionPlan> get all => [basic, standard, premium];
}

/// Menu Item Model
class MenuItem {
  final String id;
  final String name;
  final String imageUrl;
  final List<ProteinOption> availableProteins;
  final SubscriptionPlanType minimumPlan;

  const MenuItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.availableProteins,
    required this.minimumPlan,
  });
}

/// Menu Data - All available meals per plan
class MenuData {
  /// Basic Plan Menu (Beef or Fish only)
  static const List<MenuItem> basicMenu = [
    MenuItem(
      id: 'rice_stew',
      name: 'Rice & Stew',
      imageUrl: 'assets/images/meals/rice_stew.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'jollof_rice',
      name: 'Jollof Rice',
      imageUrl: 'assets/images/meals/jollof_rice.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'pasta',
      name: 'Pasta',
      imageUrl: 'assets/images/meals/pasta.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'semo',
      name: 'Semo',
      imageUrl: 'assets/images/meals/semo.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'amala',
      name: 'Amala',
      imageUrl: 'assets/images/meals/amala.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'eba',
      name: 'Eba',
      imageUrl: 'assets/images/meals/eba.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
    MenuItem(
      id: 'beans_bread',
      name: 'Beans & Bread',
      imageUrl: 'assets/images/meals/beans_bread.jpg',
      availableProteins: [ProteinOption.beef, ProteinOption.fish],
      minimumPlan: SubscriptionPlanType.basic,
    ),
  ];

  /// Standard Plan Menu (Chicken, Beef, or Fish)
  static const List<MenuItem> standardMenu = [
    MenuItem(
      id: 'rice_stew_std',
      name: 'Rice & Stew',
      imageUrl: 'assets/images/meals/rice_stew.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'jollof_rice_std',
      name: 'Jollof Rice',
      imageUrl: 'assets/images/meals/jollof_rice.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'fried_jollof_std',
      name: 'Fried Jollof Rice',
      imageUrl: 'assets/images/meals/fried_jollof.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'pasta_std',
      name: 'Pasta',
      imageUrl: 'assets/images/meals/pasta.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'semo_std',
      name: 'Semo',
      imageUrl: 'assets/images/meals/semo.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'amala_std',
      name: 'Amala',
      imageUrl: 'assets/images/meals/amala.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'eba_std',
      name: 'Eba',
      imageUrl: 'assets/images/meals/eba.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'rice_beans_std',
      name: 'Rice & Beans',
      imageUrl: 'assets/images/meals/rice_beans.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'yam_porridge_std',
      name: 'Yam Porridge',
      imageUrl: 'assets/images/meals/yam_porridge.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'yam_egg_std',
      name: 'Yam & Egg',
      imageUrl: 'assets/images/meals/yam_egg.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
    MenuItem(
      id: 'beans_bread_std',
      name: 'Beans & Bread',
      imageUrl: 'assets/images/meals/beans_bread.jpg',
      availableProteins: [
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.standard,
    ),
  ];

  /// Premium Plan Menu (Turkey, Chicken, Beef, or Fish)
  static const List<MenuItem> premiumMenu = [
    MenuItem(
      id: 'rice_stew_prm',
      name: 'Rice & Stew',
      imageUrl: 'assets/images/meals/rice_stew.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'jollof_rice_prm',
      name: 'Jollof Rice',
      imageUrl: 'assets/images/meals/jollof_rice.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'fried_jollof_prm',
      name: 'Fried Jollof Rice',
      imageUrl: 'assets/images/meals/fried_jollof.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'pasta_prm',
      name: 'Pasta',
      imageUrl: 'assets/images/meals/pasta.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'basmati_prm',
      name: 'Basmati Rice',
      imageUrl: 'assets/images/meals/basmati.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'semo_prm',
      name: 'Semo',
      imageUrl: 'assets/images/meals/semo.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'amala_prm',
      name: 'Amala',
      imageUrl: 'assets/images/meals/amala.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'eba_prm',
      name: 'Eba',
      imageUrl: 'assets/images/meals/eba.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'rice_beans_prm',
      name: 'Rice & Beans',
      imageUrl: 'assets/images/meals/rice_beans.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'poundo_prm',
      name: 'Poundo Yam',
      imageUrl: 'assets/images/meals/poundo.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'yam_egg_prm',
      name: 'Yam & Egg',
      imageUrl: 'assets/images/meals/yam_egg.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
    MenuItem(
      id: 'beans_bread_prm',
      name: 'Beans & Bread',
      imageUrl: 'assets/images/meals/beans_bread.jpg',
      availableProteins: [
        ProteinOption.turkey,
        ProteinOption.chicken,
        ProteinOption.beef,
        ProteinOption.fish,
      ],
      minimumPlan: SubscriptionPlanType.premium,
    ),
  ];

  static List<MenuItem> getMenuForPlan(SubscriptionPlanType planType) {
    switch (planType) {
      case SubscriptionPlanType.basic:
        return basicMenu;
      case SubscriptionPlanType.standard:
        return standardMenu;
      case SubscriptionPlanType.premium:
        return premiumMenu;
    }
  }
}

/// Meal Schedule Times
class MealSchedule {
  static const Map<MealSession, Map<String, String>> scheduleTimeRanges = {
    MealSession.breakfast: {
      'label': 'Breakfast',
      'start': '9:00 AM',
      'end': '11:30 AM',
      'icon': '🌅',
    },
    MealSession.lunch: {
      'label': 'Lunch',
      'start': '1:00 PM',
      'end': '3:00 PM',
      'icon': '☀️',
    },
    MealSession.dinner: {
      'label': 'Dinner',
      'start': '6:00 PM',
      'end': '8:30 PM',
      'icon': '🌙',
    },
  };

  static String getTimeRange(MealSession session) {
    final times = scheduleTimeRanges[session]!;
    return '${times['start']} - ${times['end']}';
  }

  static String getLabel(MealSession session) {
    return scheduleTimeRanges[session]!['label']!;
  }

  static String getIcon(MealSession session) {
    return scheduleTimeRanges[session]!['icon']!;
  }
}

/// Selected Meal for Schedule
class SelectedMeal {
  final MenuItem menuItem;
  final ProteinOption selectedProtein;
  final MealSession session;

  const SelectedMeal({
    required this.menuItem,
    required this.selectedProtein,
    required this.session,
  });

  String get proteinName {
    switch (selectedProtein) {
      case ProteinOption.beef:
        return 'Beef';
      case ProteinOption.fish:
        return 'Fish';
      case ProteinOption.chicken:
        return 'Chicken';
      case ProteinOption.turkey:
        return 'Turkey';
    }
  }

  String get fullDescription => '${menuItem.name} + $proteinName';
}

/// Subscription Order Model
class SubscriptionOrder {
  final SubscriptionPlan plan;
  final bool isWeekly; // true for weekly, false for monthly
  final DateTime startDate;
  final List<MealSession> selectedSessions;
  final List<SelectedMeal> selectedMeals;
  final String? deliveryAddress;

  const SubscriptionOrder({
    required this.plan,
    required this.isWeekly,
    required this.startDate,
    required this.selectedSessions,
    required this.selectedMeals,
    this.deliveryAddress,
  });

  int get totalPrice => isWeekly ? plan.weeklyPrice : plan.monthlyPrice;
  int get cashback => isWeekly ? plan.weeklyCashback : plan.monthlyCashback;
  String get duration => isWeekly ? 'Weekly' : 'Monthly';
  String get planFullName => '${plan.categoryName} ${plan.planName} Plan';

  factory SubscriptionOrder.fromJson(Map<String, dynamic> json) {
    // 1. Determine Plan Type and Category
    SubscriptionPlanType planType;
    try {
      final rawPlan = json['plan'];
      final typeStr = rawPlan is Map
          ? rawPlan['type']
          : (json['planType'] ?? rawPlan);
      planType = SubscriptionPlanType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => SubscriptionPlanType.basic,
      );
    } catch (_) {
      planType = SubscriptionPlanType.basic;
    }

    SubscriptionCategory category;
    try {
      final rawCat = json['category'];
      final catStr = rawCat is Map ? rawCat['name'] : rawCat;
      category = SubscriptionCategory.values.firstWhere(
        (e) => e.name == catStr,
        orElse: () => SubscriptionCategory.corporate,
      );
    } catch (_) {
      category = SubscriptionCategory.corporate;
    }

    // 2. Find the matching SubscriptionPlan object
    SubscriptionPlan plan;
    if (category == SubscriptionCategory.corporate) {
      plan = CorporatePlans.all.firstWhere(
        (p) => p.type == planType,
        orElse: () => CorporatePlans.basic,
      );
    } else {
      plan = StudentPlans.all.firstWhere(
        (p) => p.type == planType,
        orElse: () => StudentPlans.basic,
      );
    }

    // 3. Parse Billing Cycle
    final isWeekly =
        (json['billingCycle'] == 'weekly') || (json['isWeekly'] == true);

    // 4. Parse Start Date
    DateTime startDate;
    try {
      startDate = DateTime.parse(json['startDate'] ?? json['periodStart']);
    } catch (_) {
      startDate = DateTime.now();
    }

    // 5. Parse Selected Sessions
    List<MealSession> selectedSessions = [];
    final sessionsList = json['selectedSessions'] ?? json['sessions'];
    if (sessionsList is List) {
      for (var s in sessionsList) {
        try {
          final session = MealSession.values.firstWhere(
            (e) => e.name.toLowerCase() == s.toString().toLowerCase(),
          );
          selectedSessions.add(session);
        } catch (_) {}
      }
    }

    // 6. Parse Selected Meals
    List<SelectedMeal> selectedMeals = [];
    final mealsList = json['selectedMeals'] ?? json['meals'];
    if (mealsList is List) {
      for (var m in mealsList) {
        try {
          // Find Menu Item
          final menuItemName = m['menuItem'] ?? m['name'];
          // We need to find the MenuItem object. Since we don't have a global lookup by name easily,
          // we'll search in the plan's menu.
          final menu = MenuData.getMenuForPlan(planType);
          final menuItem = menu.firstWhere(
            (item) => item.name == menuItemName,
            orElse: () => menu.first, // Fallback
          );

          // Find Protein
          final proteinName = m['protein'] ?? m['proteinName'];
          final protein = ProteinOption.values.firstWhere(
            (p) => p.name.toLowerCase() == proteinName.toString().toLowerCase(),
            orElse: () => ProteinOption.beef,
          );

          // Find Session
          final sessionName = m['session'] ?? m['mealSession'];
          final session = MealSession.values.firstWhere(
            (s) => s.name.toLowerCase() == sessionName.toString().toLowerCase(),
            orElse: () => MealSession.lunch,
          );

          selectedMeals.add(
            SelectedMeal(
              menuItem: menuItem,
              selectedProtein: protein,
              session: session,
            ),
          );
        } catch (_) {}
      }
    }

    return SubscriptionOrder(
      plan: plan,
      isWeekly: isWeekly,
      startDate: startDate,
      selectedSessions: selectedSessions,
      selectedMeals: selectedMeals,
      deliveryAddress: json['deliveryAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': {
        'type': plan.type.name,
        'category': plan.category.name,
        'name': planFullName,
      },
      'isWeekly': isWeekly,
      'startDate': startDate.toIso8601String(),
      'sessions': selectedSessions.map((s) => s.name).toList(),
      'meals': selectedMeals
          .map(
            (m) => <String, dynamic>{
              'menuItem': m.menuItem.name,
              'protein': m.proteinName,
              'session': m.session.name,
            },
          )
          .toList(),
      'totalPrice': totalPrice,
      'cashback': cashback,
      'deliveryAddress': deliveryAddress,
    };
  }
}

/// Helper to get protein emoji
String getProteinEmoji(ProteinOption protein) {
  switch (protein) {
    case ProteinOption.beef:
      return '🥩';
    case ProteinOption.fish:
      return '🐟';
    case ProteinOption.chicken:
      return '🍗';
    case ProteinOption.turkey:
      return '🦃';
  }
}

/// Format currency in Naira
String formatNaira(int amount) {
  return '₦${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
}
