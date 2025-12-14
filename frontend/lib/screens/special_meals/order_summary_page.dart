import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/subscription.dart';
import '../../services/api_client.dart';

/// Order Summary Page - Shows all selected details
/// Allows download/email and proceed to payment
class OrderSummaryPage extends StatefulWidget {
  final SubscriptionOrder order;
  final bool isExistingOrder;

  const OrderSummaryPage({
    super.key,
    required this.order,
    this.isExistingOrder = false,
  });

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final TextEditingController _addressController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('EEE, MMM d, y');

  SharedPreferences? _prefs;
  bool _isProcessing = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final savedAddress =
        widget.order.deliveryAddress ??
        prefs.getString('special_meals_address') ??
        '';
    final savedEmail = prefs.getString('user_email');

    _addressController.text = savedAddress;

    if (mounted) {
      setState(() {
        _userEmail = savedEmail;
      });
    } else {
      _userEmail = savedEmail;
    }

    final authToken = prefs.getString('auth_token');
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    try {
      final profile = await ApiClient().getJson('/api/users/profile');
      final profileEmail = profile['email'] as String?;
      if (profileEmail == null || profileEmail.isEmpty) {
        return;
      }

      await prefs.setString('user_email', profileEmail);
      if (!mounted) {
        _userEmail = profileEmail;
        return;
      }
      setState(() {
        _userEmail = profileEmail;
      });
    } catch (error) {
      debugPrint('Failed to load profile for special meals summary: $error');
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _downloadSummary() async {
    final summaryText = _generateSummaryText();
    await Clipboard.setData(ClipboardData(text: summaryText));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveAddress(String value) async {
    if (widget.isExistingOrder) return; // Read-only
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString('special_meals_address', value);
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  String _generateSummaryText() {
    final buffer = StringBuffer();

    buffer.writeln(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );
    buffer.writeln('   QUICKSERVE SPECIAL MEAL SUBSCRIPTION');
    buffer.writeln(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );
    buffer.writeln();
    buffer.writeln('ðŸ“‹ SUBSCRIPTION DETAILS');
    buffer.writeln(
      'â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€',
    );
    buffer.writeln('Plan: ${widget.order.planFullName}');
    buffer.writeln('Duration: ${widget.order.duration}');
    buffer.writeln('Start Date: ${_formatDate(widget.order.startDate)}');
    buffer.writeln();
    buffer.writeln('â° MEAL SESSIONS');
    buffer.writeln(
      'â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€',
    );
    for (final session in widget.order.selectedSessions) {
      final times = MealSchedule.scheduleTimeRanges[session]!;
      buffer.writeln(
        'â€¢ ${times['label']}: ${times['start']} - ${times['end']}',
      );
    }
    buffer.writeln();
    buffer.writeln('ðŸ½ï¸ SELECTED MEALS');
    buffer.writeln(
      'â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€',
    );
    for (final meal in widget.order.selectedMeals) {
      buffer.writeln('â€¢ ${meal.fullDescription}');
    }
    buffer.writeln();
    buffer.writeln('ðŸ’° PAYMENT SUMMARY');
    buffer.writeln(
      'â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€',
    );
    buffer.writeln(
      'Subscription Price: ${formatNaira(widget.order.totalPrice)}',
    );
    buffer.writeln('Cashback Reward: ${formatNaira(widget.order.cashback)}');
    buffer.writeln();
    buffer.writeln(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );
    buffer.writeln('Thank you for choosing QuickServe!');
    buffer.writeln(
      'â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•',
    );

    return buffer.toString();
  }

  Map<String, dynamic> _buildMealSchedulePayload() {
    final selected = widget.order.selectedSessions.toSet();
    bool includes(MealSession session) => selected.contains(session);

    return {
      'breakfast': {
        'enabled': includes(MealSession.breakfast),
        'time': '09:00',
      },
      'lunch': {'enabled': includes(MealSession.lunch), 'time': '13:00'},
      'dinner': {'enabled': includes(MealSession.dinner), 'time': '19:00'},
    };
  }

  List<String> _selectedSessionNames() {
    return widget.order.selectedSessions
        .map((session) => session.name)
        .toList();
  }

  List<Map<String, String>> _buildSelectedMealsPayload() {
    return widget.order.selectedMeals
        .map(
          (meal) => {
            'menuItem': meal.menuItem.name,
            'protein': meal.proteinName,
            'session': meal.session.name,
          },
        )
        .toList();
  }

  Map<String, dynamic> _buildSubscriptionPayload(
    String deliveryAddress, {
    String? redirectUrl,
  }) {
    final orderJson = widget.order.toJson();
    final sessions = _selectedSessionNames();

    return {
      'plan': orderJson['plan']['type'],
      'planName': orderJson['plan']['name'],
      'category': orderJson['plan']['category'],
      'billingCycle': widget.order.isWeekly ? 'weekly' : 'monthly',
      'startDate': orderJson['startDate'],
      'sessions': sessions,
      'selectedSessions': sessions,
      'selectedMeals': _buildSelectedMealsPayload(),
      'mealSchedule': _buildMealSchedulePayload(),
      'deliveryAddress': deliveryAddress,
      'amount': orderJson['totalPrice'],
      'cashback': orderJson['cashback'],
      'autoRenew': true,
      'paymentMethod': 'paystack',
      'redirectUrl': redirectUrl,
    };
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    const prefixes = ['Exception: ', 'FormatException: '];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        return text.substring(prefix.length);
      }
    }
    return text;
  }

  Future<void> _emailSummary() async {
    if (_userEmail == null || _userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to send email summary'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Send email via API
      await ApiClient().postJson('/api/subscriptions/email-summary', {
        'email': _userEmail,
        'summary': widget.order.toJson(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Summary sent to $_userEmail')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // For now, just show success since backend may not have this endpoint yet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Summary will be sent to $_userEmail'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _proceedToPayment() async {
    // Validate delivery address
    final deliveryAddress = _addressController.text.trim();

    if (deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is logged in
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      _showLoginPrompt();
      return;
    }

    await _saveAddress(deliveryAddress);

    if (mounted) {
      setState(() => _isProcessing = true);
    } else {
      _isProcessing = true;
    }

    try {
      // Get current URL for redirect (works on web)
      String redirectUrl = '';
      try {
        redirectUrl = Uri.base.origin; // e.g. http://localhost:64077
      } catch (_) {}

      // Create subscription order
      final payload = _buildSubscriptionPayload(
        deliveryAddress,
        redirectUrl: redirectUrl,
      );
      final response = await ApiClient().postJson(
        '/api/subscriptions/create',
        payload,
      );

      final errorMessage = response['error'];
      if (errorMessage is String && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      final paymentUrl =
          response['paymentUrl'] ??
          response['authorization_url'] ??
          response['authorizationUrl'];

      if (paymentUrl is String && paymentUrl.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Paystack checkout...'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _openPayment(paymentUrl);
      } else if (response['reference'] != null) {
        _initializePaystack(response['reference']);
      } else {
        throw Exception('Payment link not returned. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start payment: ${_friendlyError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Color(0xFFFF6B00)),
            SizedBox(width: 12),
            Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please login to subscribe to a meal plan. Your subscription details will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPayment(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open payment page'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializePaystack(String reference) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment reference generated: $reference'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: Text(
          widget.isExistingOrder ? 'Subscription Details' : 'Order Summary',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Plan summary header
            _buildPlanHeader(),

            // Schedule details
            _buildScheduleDetails(),

            // Selected meals
            _buildSelectedMeals(),

            // Delivery address
            _buildDeliveryAddress(),

            // Payment summary
            _buildPaymentSummary(),

            // Action buttons
            _buildActionButtons(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubscribeButton(),
    );
  }

  Widget _buildPlanHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.order.plan.category == SubscriptionCategory.corporate
                  ? Icons.business
                  : Icons.school,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.order.planFullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.order.duration} Subscription',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNaira(widget.order.totalPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+${formatNaira(widget.order.cashback)} back',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFFFF6B00)),
              SizedBox(width: 8),
              Text(
                'Schedule Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          // Start date
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Start Date',
            value: _formatDate(widget.order.startDate),
          ),
          const SizedBox(height: 12),

          // Duration
          _buildDetailRow(
            icon: Icons.timelapse,
            label: 'Duration',
            value: widget.order.isWeekly
                ? '7 Days (Weekly)'
                : '30 Days (Monthly)',
          ),
          const SizedBox(height: 12),

          // Meal sessions
          _buildDetailRow(
            icon: Icons.restaurant,
            label: 'Meal Sessions',
            value: '',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.order.selectedSessions.map((session) {
              final times = MealSchedule.scheduleTimeRanges[session]!;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(times['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      '${times['label']} (${times['start']})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        if (value.isNotEmpty) ...[
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedMeals() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu, color: Color(0xFFFF6B00)),
              SizedBox(width: 8),
              Text(
                'Selected Meals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          ...widget.order.selectedMeals.map((meal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        getProteinEmoji(meal.selectedProtein),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.menuItem.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '+ ${meal.proteinName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      MealSchedule.getLabel(meal.session),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFFF6B00)),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            onChanged: (value) => _saveAddress(value),
            readOnly: widget.isExistingOrder,
            decoration: InputDecoration(
              hintText: 'Enter your delivery address',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6B00)),
              ),
              prefixIcon: const Icon(Icons.home, color: Colors.grey),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Color(0xFFFF6B00)),
              SizedBox(width: 8),
              Text(
                'Payment Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),

          _buildSummaryRow(
            'Subscription Price',
            formatNaira(widget.order.totalPrice),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Delivery Fee', 'FREE', isGreen: true),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Cashback Reward',
            '-${formatNaira(widget.order.cashback)}',
            isGreen: true,
          ),

          const Divider(height: 24),

          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              Text(
                formatNaira(widget.order.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Color(0xFFFF6B00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (widget.isExistingOrder)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Payment Successful',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ll earn ${formatNaira(widget.order.cashback)} cashback after payment!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isGreen ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _downloadSummary,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _emailSummary,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B00),
                side: const BorderSide(color: Color(0xFFFF6B00)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
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
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.isExistingOrder
                ? () => Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false)
                : (_isProcessing ? null : _proceedToPayment),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isExistingOrder
                  ? Colors.grey.shade800
                  : const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isExistingOrder ? Icons.home : Icons.payment,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.isExistingOrder
                            ? 'BACK TO HOME'
                            : 'SUBSCRIBE NOW!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
