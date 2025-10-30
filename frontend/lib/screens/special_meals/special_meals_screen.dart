import 'package:flutter/material.dart';

class SpecialMealsScreen extends StatefulWidget {
  const SpecialMealsScreen({super.key});

  @override
  State<SpecialMealsScreen> createState() => _SpecialMealsScreenState();
}

class _SpecialMealsScreenState extends State<SpecialMealsScreen> {
  String? _selectedPlan;
  bool _breakfast = true;
  bool _lunch = true;
  bool _dinner = true;

  final Map<String, int> _planPrices = {
    'Basic': 25000,
    'Standard': 50000,
    'Premium': 75000,
  };

  int get _serviceCharge => 1500; // Fixed service charge for now
  int get _totalAmount {
    if (_selectedPlan == null) return 0;
    return _planPrices[_selectedPlan]! + _serviceCharge;
  }

  void _confirmSubscription() {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a meal plan first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Subscription'),
        content: Text(
          'You selected the $_selectedPlan plan.\n\n'
          'Meal Times:\n'
          '${_breakfast ? "• Breakfast\n" : ""}'
          '${_lunch ? "• Lunch\n" : ""}'
          '${_dinner ? "• Dinner\n" : ""}\n'
          'Service Charge: ₦$_serviceCharge\n'
          'Total: ₦$_totalAmount',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ Subscription confirmed successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String desc, int price) {
    final selected = _selectedPlan == title;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Text(
              '₦$price',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Delivery Time',
              style: TextStyle(fontWeight: FontWeight.bold)),
          CheckboxListTile(
            value: _breakfast,
            title: const Text('Breakfast (8:00 AM)'),
            onChanged: (v) => setState(() => _breakfast = v!),
          ),
          CheckboxListTile(
            value: _lunch,
            title: const Text('Lunch (1:00 PM)'),
            onChanged: (v) => setState(() => _lunch = v!),
          ),
          CheckboxListTile(
            value: _dinner,
            title: const Text('Dinner (7:00 PM)'),
            onChanged: (v) => setState(() => _dinner = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Charge'),
              Text('₦$_serviceCharge'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Plan Total'),
              Text(
                _selectedPlan == null
                    ? '₦0'
                    : '₦${_planPrices[_selectedPlan]}',
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₦$_totalAmount',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Special Meals Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Meal Plan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildPlanCard('Basic', 'Affordable plan (₦25,000)', 25000),
            _buildPlanCard('Standard', 'Balanced plan (₦50,000)', 50000),
            _buildPlanCard('Premium', 'Exclusive plan (₦75,000)', 75000),
            const SizedBox(height: 16),
            _buildScheduleSelector(),
            _buildSummaryCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Confirm Subscription',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}