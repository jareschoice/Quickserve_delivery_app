import 'package:flutter/material.dart';
import '../../models/subscription.dart';
import 'order_summary_page.dart';

/// Schedule Page - Calendar, Time Slot, and Menu Selection
/// Allows users to schedule their meal subscription
class SchedulePage extends StatefulWidget {
  final SubscriptionPlan plan;

  const SchedulePage({super.key, required this.plan});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Step tracking
  int _currentStep = 0;

  // Duration selection
  bool _isWeekly = true;

  // Date selection
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  // Time slot selection
  final Set<MealSession> _selectedSessions = {};

  // Menu selection (meal -> protein)
  final Map<String, ProteinOption> _selectedMeals = {};

  int get _maxSessions => widget.plan.mealsPerDay;

  List<MenuItem> get _menuItems {
    return MenuData.getMenuForPlan(widget.plan.type);
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0: // Duration & Date
        return true;
      case 1: // Time slots
        return _selectedSessions.length == _maxSessions;
      case 2: // Menu selection - must select exactly mealsPerDay meals
        return _selectedMeals.length == _maxSessions;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _proceedToSummary();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _proceedToSummary() {
    // Build selected meals list
    final selectedMealsList = _selectedMeals.entries.map((entry) {
      final menuItem = _menuItems.firstWhere((m) => m.id == entry.key);
      // For simplicity, assign meals to sessions in order
      final sessionIndex = _selectedMeals.keys.toList().indexOf(entry.key);
      final session = _selectedSessions.elementAt(
        sessionIndex % _selectedSessions.length,
      );

      return SelectedMeal(
        menuItem: menuItem,
        selectedProtein: entry.value,
        session: session,
      );
    }).toList();

    final order = SubscriptionOrder(
      plan: widget.plan,
      isWeekly: _isWeekly,
      startDate: _selectedDate,
      selectedSessions: _selectedSessions.toList(),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),

          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStepContent(),
            ),
          ),

          // Bottom action bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepDot(0, 'Duration'),
          _buildStepLine(0),
          _buildStepDot(1, 'Time'),
          _buildStepLine(1),
          _buildStepDot(2, 'Menu'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFFFF6B00) : Colors.grey.shade300,
              border: isCurrent
                  ? Border.all(color: const Color(0xFFFF6B00), width: 3)
                  : null,
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFFFF6B00) : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 30,
      height: 2,
      color: isActive ? const Color(0xFFFF6B00) : Colors.grey.shade300,
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDurationDateStep();
      case 1:
        return _buildTimeSlotStep();
      case 2:
        return _buildMenuSelectionStep();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Duration & Date Selection
  Widget _buildDurationDateStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_0'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration selection
          const Text(
            'Select Duration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDurationCard(
                  isWeekly: true,
                  price: widget.plan.weeklyPrice,
                  cashback: widget.plan.weeklyCashback,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDurationCard(
                  isWeekly: false,
                  price: widget.plan.monthlyPrice,
                  cashback: widget.plan.monthlyCashback,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date selection
          const Text(
            'Select Start Date',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCalendar(),

          const SizedBox(height: 16),

          // Selected date info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: Color(0xFFFF6B00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your subscription starts',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isWeekly ? '7 Days' : '30 Days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildDurationCard({
    required bool isWeekly,
    required int price,
    required int cashback,
  }) {
    final isSelected = _isWeekly == isWeekly;

    return GestureDetector(
      onTap: () => setState(() => _isWeekly = isWeekly),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isWeekly ? Icons.view_week : Icons.calendar_month,
              color: isSelected ? Colors.white : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isWeekly ? 'Weekly' : 'Monthly',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatNaira(price),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFFFF6B00),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${formatNaira(cashback)} cashback',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDate = now.add(const Duration(days: 1));
    final lastDate = now.add(const Duration(days: 60));

    return Container(
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
      child: CalendarDatePicker(
        initialDate: _selectedDate,
        firstDate: firstDate,
        lastDate: lastDate,
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
      ),
    );
  }

  // STEP 2: Time Slot Selection
  Widget _buildTimeSlotStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_1'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select $_maxSessions Meal Time${_maxSessions > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your ${widget.plan.planName} plan includes $_maxSessions meal${_maxSessions > 1 ? 's' : ''} per day',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Selection counter
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSessions.length == _maxSessions
                  ? Colors.green.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedSessions.length == _maxSessions
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedSessions.length == _maxSessions
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedSessions.length == _maxSessions
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedSessions.length} of $_maxSessions selected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedSessions.length == _maxSessions
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Time slot cards
          ...MealSession.values.map((session) => _buildTimeSlotCard(session)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(MealSession session) {
    final isSelected = _selectedSessions.contains(session);
    final canSelect = isSelected || _selectedSessions.length < _maxSessions;
    final times = MealSchedule.scheduleTimeRanges[session]!;

    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedSessions.remove(session);
                } else {
                  _selectedSessions.add(session);
                }
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B00)
                : canSelect
                ? Colors.grey.shade300
                : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFFF6B00).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  times['icon']!,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    times['label']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${times['start']} - ${times['end']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : canSelect
                    ? Colors.grey.shade200
                    : Colors.grey.shade100,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : canSelect
                      ? Colors.grey.shade400
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFFFF6B00), size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // STEP 3: Menu Selection
  Widget _buildMenuSelectionStep() {
    return SingleChildScrollView(
      key: const ValueKey('step_2'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Meals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose meals from the ${widget.plan.planName} menu',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Selection info - enforces mealsPerDay limit
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedMeals.length == _maxSessions
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedMeals.length == _maxSessions
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedMeals.length == _maxSessions
                      ? Icons.check_circle
                      : Icons.info_outline,
                  color: _selectedMeals.length == _maxSessions
                      ? Colors.green.shade600
                      : Colors.blue.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedMeals.length == _maxSessions
                        ? '${_selectedMeals.length} of $_maxSessions meal${_maxSessions != 1 ? 's' : ''} selected âœ“'
                        : '${_selectedMeals.length} of $_maxSessions meal${_maxSessions != 1 ? 's' : ''} selected. Select exactly $_maxSessions.',
                    style: TextStyle(
                      color: _selectedMeals.length == _maxSessions
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Menu items
          ...List.generate(_menuItems.length, (index) {
            final item = _menuItems[index];
            return _buildMenuItemCard(item);
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final isSelected = _selectedMeals.containsKey(item.id);
    final selectedProtein = _selectedMeals[item.id];
    final imageUrl = _getFoodImageUrl(item.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main card content
          InkWell(
            onTap: () {
              if (!isSelected) {
                // Check if we can add more meals
                if (_selectedMeals.length < _maxSessions) {
                  // If not selected and under limit, show protein selection
                  _showProteinSelectionDialog(item);
                } else {
                  // Show a message that limit is reached
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You can only select $_maxSessions meal${_maxSessions != 1 ? 's' : ''} for this plan',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                // If selected, deselect
                setState(() {
                  _selectedMeals.remove(item.id);
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Food image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Food info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: item.availableProteins.map((protein) {
                            final isProteinSelected =
                                selectedProtein == protein;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isProteinSelected
                                    ? const Color(0xFFFF6B00)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${getProteinEmoji(protein)} ${_getProteinName(protein)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isProteinSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  // Checkbox
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFFF6B00)
                          : Colors.grey.shade200,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Selected protein indicator
          if (isSelected && selectedProtein != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    getProteinEmoji(selectedProtein),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Selected: ${_getProteinName(selectedProtein)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showProteinSelectionDialog(item),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
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

  void _showProteinSelectionDialog(MenuItem item) {
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
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _getFoodImageUrl(item.name),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose protein for ${item.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...item.availableProteins.map((protein) {
              return ListTile(
                leading: Text(
                  getProteinEmoji(protein),
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(
                  _getProteinName(protein),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  setState(() {
                    _selectedMeals[item.id] = protein;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
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

  String _getFoodImageUrl(String foodName) {
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

  String _formatDate(DateTime date) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
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
            // Price summary
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
                    _isWeekly ? 'per week' : 'per month',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Action button
            ElevatedButton(
              onPressed: _canProceed ? _nextStep : null,
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
                    _currentStep < 2 ? 'Continue' : 'Proceed',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
