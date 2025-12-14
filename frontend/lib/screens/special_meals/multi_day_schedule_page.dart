import 'package:flutter/material.dart';
import '../../models/subscription.dart';
import 'order_summary_page.dart';

/// Scheduled meal for a specific day
class DayMealSchedule {
  final DateTime date;
  final MenuItem menuItem;
  final ProteinOption protein;
  final MealSession session;

  const DayMealSchedule({
    required this.date,
    required this.menuItem,
    required this.protein,
    required this.session,
  });
}

/// Multi-Day Schedule Page - Allows scheduling different meals for each day
class MultiDaySchedulePage extends StatefulWidget {
  final SubscriptionPlan plan;

  const MultiDaySchedulePage({super.key, required this.plan});

  @override
  State<MultiDaySchedulePage> createState() => _MultiDaySchedulePageState();
}

class _MultiDaySchedulePageState extends State<MultiDaySchedulePage> {
  bool _isWeekly = true;
  late DateTime _currentMonth;
  final Map<String, List<DayMealSchedule>> _scheduledMeals = {};

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  int get _daysRequired => _isWeekly ? 7 : 30;
  int get _mealsPerDay => widget.plan.mealsPerDay;

  int get _scheduledDaysCount {
    return _scheduledMeals.entries
        .where((e) => e.value.length == _mealsPerDay)
        .length;
  }

  bool get _isComplete => _scheduledDaysCount >= _daysRequired;

  List<MenuItem> get _menuItems => MenuData.getMenuForPlan(widget.plan.type);

  String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  DateTime _parseKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  bool _isDayScheduled(DateTime date) {
    final meals = _scheduledMeals[_dateKey(date)];
    return meals != null && meals.length == _mealsPerDay;
  }

  bool _isDayPartiallyScheduled(DateTime date) {
    final meals = _scheduledMeals[_dateKey(date)];
    return meals != null && meals.isNotEmpty && meals.length < _mealsPerDay;
  }

  void _proceedToSummary() {
    final selectedMealsList = <SelectedMeal>[];
    final selectedSessions = <MealSession>{};
    DateTime? startDate;

    final sortedKeys = _scheduledMeals.keys.toList()..sort();

    for (final key in sortedKeys) {
      final date = _parseKey(key);
      startDate ??= date;

      for (final schedule in _scheduledMeals[key]!) {
        selectedSessions.add(schedule.session);
        selectedMealsList.add(
          SelectedMeal(
            menuItem: schedule.menuItem,
            selectedProtein: schedule.protein,
            session: schedule.session,
          ),
        );
      }
    }

    final order = SubscriptionOrder(
      plan: widget.plan,
      isWeekly: _isWeekly,
      startDate: startDate ?? DateTime.now().add(const Duration(days: 1)),
      selectedSessions: selectedSessions.toList(),
      selectedMeals: selectedMealsList,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderSummaryPage(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('Schedule Your Meals'),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDurationToggle(),
                  _buildInstructions(),
                  _buildCalendar(),
                  _buildScheduledMealsList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgressBar() {
    // Cap progress at 100% (1.0)
    final progress = (_scheduledDaysCount / _daysRequired).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_scheduledDaysCount of $_daysRequired days scheduled',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: progress == 1 ? Colors.green : const Color(0xFFFF6B00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                progress == 1 ? Colors.green : const Color(0xFFFF6B00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isWeekly && _scheduledMeals.isNotEmpty) {
                  _showClearConfirmation(true);
                } else {
                  setState(() => _isWeekly = true);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isWeekly
                      ? const Color(0xFFFF6B00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Weekly',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isWeekly ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${formatNaira(widget.plan.weeklyPrice)} • 7 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isWeekly ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isWeekly && _scheduledMeals.isNotEmpty) {
                  _showClearConfirmation(false);
                } else {
                  setState(() => _isWeekly = false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isWeekly
                      ? const Color(0xFFFF6B00)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_isWeekly ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${formatNaira(widget.plan.monthlyPrice)} • 30 days',
                      style: TextStyle(
                        fontSize: 12,
                        color: !_isWeekly ? Colors.white70 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation(bool toWeekly) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Duration?'),
        content: const Text(
          'Changing the duration will clear your current schedule. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isWeekly = toWeekly;
                _scheduledMeals.clear();
              });
            },
            child: const Text('Clear & Change'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap on any date to schedule $_mealsPerDay meal${_mealsPerDay > 1 ? 's' : ''} for that day. '
              'You need to schedule $_daysRequired days total.',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(
                        _currentMonth.year,
                        _currentMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  _getMonthName(_currentMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    final maxMonth = DateTime.now().add(
                      const Duration(days: 90),
                    );
                    if (_currentMonth.isBefore(
                      DateTime(maxMonth.year, maxMonth.month),
                    )) {
                      setState(() {
                        _currentMonth = DateTime(
                          _currentMonth.year,
                          _currentMonth.month + 1,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Calendar grid
          _buildCalendarGrid(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    );

    // Monday = 1, so we need to calculate offset
    int startWeekday = firstDayOfMonth.weekday - 1; // 0 = Monday

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final now = DateTime.now();

    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - startWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );
              final isPast = date.isBefore(
                DateTime(now.year, now.month, now.day + 1),
              );
              final isTooFar = date.isAfter(now.add(const Duration(days: 90)));
              final isScheduled = _isDayScheduled(date);
              final isPartial = _isDayPartiallyScheduled(date);

              return Expanded(
                child: GestureDetector(
                  onTap: isPast || isTooFar
                      ? null
                      : () => _showDayScheduleSheet(date),
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isScheduled
                          ? Colors.green
                          : isPartial
                          ? Colors.orange.shade300
                          : isPast || isTooFar
                          ? Colors.grey.shade100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: !isScheduled && !isPartial && !isPast && !isTooFar
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isScheduled || isPartial
                                ? Colors.white
                                : isPast || isTooFar
                                ? Colors.grey.shade400
                                : Colors.black,
                            fontWeight: isScheduled
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                        if (isScheduled)
                          const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showDayScheduleSheet(DateTime date) {
    final key = _dateKey(date);
    final existingMeals = List<DayMealSchedule>.from(
      _scheduledMeals[key] ?? [],
    );

    // Check if we've already scheduled the maximum number of days
    // Only block new days, allow editing existing scheduled days
    if (existingMeals.isEmpty && _scheduledDaysCount >= _daysRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You have already scheduled $_daysRequired days. '
            'Remove a day to add a different one.',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayScheduleSheet(
        date: date,
        mealsPerDay: _mealsPerDay,
        menuItems: _menuItems,
        existingMeals: existingMeals,
        onSave: (meals) {
          setState(() {
            if (meals.isEmpty) {
              _scheduledMeals.remove(key);
            } else {
              _scheduledMeals[key] = meals;
            }
          });
        },
      ),
    );
  }

  Widget _buildScheduledMealsList() {
    if (_scheduledMeals.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No meals scheduled yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap on dates above to schedule',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final sortedKeys = _scheduledMeals.keys.toList()..sort();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scheduled Meals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All?'),
                      content: const Text(
                        'This will remove all scheduled meals.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _scheduledMeals.clear());
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sortedKeys.map((key) {
            final date = _parseKey(key);
            final meals = _scheduledMeals[key]!;
            return _buildScheduledDayCard(date, meals);
          }),
        ],
      ),
    );
  }

  Widget _buildScheduledDayCard(DateTime date, List<DayMealSchedule> meals) {
    final isComplete = meals.length == _mealsPerDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showDayScheduleSheet(date),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isComplete ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDateShort(date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDayName(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    isComplete ? Icons.check_circle : Icons.pending,
                    color: isComplete ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...meals.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        MealSchedule.getIcon(meal.session),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        MealSchedule.getLabel(meal.session),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${meal.menuItem.name} + ${_getProteinName(meal.protein)}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _getDayName(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  String _getProteinName(ProteinOption protein) {
    switch (protein) {
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

  Widget _buildBottomBar() {
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
                    formatNaira(
                      _isWeekly
                          ? widget.plan.weeklyPrice
                          : widget.plan.monthlyPrice,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                  Text(
                    '$_scheduledDaysCount/$_daysRequired days scheduled',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isComplete ? _proceedToSummary : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isComplete
                        ? 'Proceed'
                        : 'Schedule ${_daysRequired - _scheduledDaysCount} more',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (_isComplete) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for scheduling meals for a specific day
class _DayScheduleSheet extends StatefulWidget {
  final DateTime date;
  final int mealsPerDay;
  final List<MenuItem> menuItems;
  final List<DayMealSchedule> existingMeals;
  final Function(List<DayMealSchedule>) onSave;

  const _DayScheduleSheet({
    required this.date,
    required this.mealsPerDay,
    required this.menuItems,
    required this.existingMeals,
    required this.onSave,
  });

  @override
  State<_DayScheduleSheet> createState() => _DayScheduleSheetState();
}

class _DayScheduleSheetState extends State<_DayScheduleSheet> {
  late List<DayMealSchedule> _meals;

  @override
  void initState() {
    super.initState();
    _meals = List.from(widget.existingMeals);
  }

  void _addMeal() {
    if (_meals.length >= widget.mealsPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum ${widget.mealsPerDay} meal${widget.mealsPerDay > 1 ? 's' : ''} per day',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final usedSessions = _meals.map((m) => m.session).toSet();
    final availableSessions = MealSession.values
        .where((s) => !usedSessions.contains(s))
        .toList();

    if (availableSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All meal times are already scheduled'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _showMealSelectionDialog(availableSessions);
  }

  void _showMealSelectionDialog(List<MealSession> availableSessions) {
    MealSession? selectedSession;
    MenuItem? selectedMeal;
    ProteinOption? selectedProtein;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle, color: Color(0xFFFF6B00)),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Select Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: availableSessions.map((session) {
                          final isSelected = selectedSession == session;
                          final times =
                              MealSchedule.scheduleTimeRanges[session]!;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(times['icon']!),
                                const SizedBox(width: 4),
                                Text(times['label']!),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF6B00),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (selected) {
                              setSheetState(() => selectedSession = session);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        '2. Select Meal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.menuItems.map((item) {
                        final isSelected = selectedMeal?.id == item.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B00)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFFF6B00),
                                  )
                                : null,
                            onTap: () {
                              setSheetState(() {
                                selectedMeal = item;
                                selectedProtein = null;
                              });
                            },
                          ),
                        );
                      }),

                      if (selectedMeal != null) ...[
                        const SizedBox(height: 24),

                        const Text(
                          '3. Select Protein',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: selectedMeal!.availableProteins.map((
                            protein,
                          ) {
                            final isSelected = selectedProtein == protein;
                            return ChoiceChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(getProteinEmoji(protein)),
                                  const SizedBox(width: 4),
                                  Text(_getProteinName(protein)),
                                ],
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFFF6B00),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              onSelected: (selected) {
                                setSheetState(() => selectedProtein = protein);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        selectedSession != null &&
                            selectedMeal != null &&
                            selectedProtein != null
                        ? () {
                            setState(() {
                              _meals.add(
                                DayMealSchedule(
                                  date: widget.date,
                                  menuItem: selectedMeal!,
                                  protein: selectedProtein!,
                                  session: selectedSession!,
                                ),
                              );
                            });
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add This Meal',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  String _getProteinName(ProteinOption protein) {
    switch (protein) {
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

  @override
  Widget build(BuildContext context) {
    final isComplete = _meals.length == widget.mealsPerDay;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.date.day}/${widget.date.month}/${widget.date.year}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getDayName(widget.date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.pending,
                  color: isComplete ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_meals.length}/${widget.mealsPerDay} meal${widget.mealsPerDay > 1 ? 's' : ''} scheduled',
                  style: TextStyle(
                    color: isComplete ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _meals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No meals scheduled',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the button below to add',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _meals.length,
                    itemBuilder: (context, index) {
                      final meal = _meals[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              MealSchedule.getIcon(meal.session),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    MealSchedule.getLabel(meal.session),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${meal.menuItem.name} + ${_getProteinName(meal.protein)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(() => _meals.removeAt(index));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_meals.length < widget.mealsPerDay)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addMeal,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Meal'),
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
                if (_meals.length < widget.mealsPerDay)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSave(_meals);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isComplete ? 'Save Schedule' : 'Save (Incomplete)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  String _getDayName(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }
}
