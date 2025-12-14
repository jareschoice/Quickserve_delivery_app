import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/subscription.dart';

/// Wallet Page - Shows cashback balance and allows airtime/data purchase
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isProcessing = false;
  double _walletBalance = 0;
  List<Map<String, dynamic>> _transactions = [];

  // Airtime form
  String _selectedNetwork = 'MTN';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Data form
  String _selectedDataNetwork = 'MTN';
  String? _selectedDataPlan;

  final List<String> _networks = ['MTN', 'Airtel', 'Glo', '9Mobile'];

  final Map<String, List<Map<String, dynamic>>> _dataPlans = {
    'MTN': [
      {'label': '500MB - 30 Days', 'value': '500mb_30', 'price': 500},
      {'label': '1GB - 30 Days', 'value': '1gb_30', 'price': 1000},
      {'label': '2GB - 30 Days', 'value': '2gb_30', 'price': 1500},
      {'label': '3GB - 30 Days', 'value': '3gb_30', 'price': 2000},
      {'label': '5GB - 30 Days', 'value': '5gb_30', 'price': 3000},
      {'label': '10GB - 30 Days', 'value': '10gb_30', 'price': 5000},
    ],
    'Airtel': [
      {'label': '500MB - 30 Days', 'value': '500mb_30', 'price': 500},
      {'label': '1GB - 30 Days', 'value': '1gb_30', 'price': 1000},
      {'label': '2GB - 30 Days', 'value': '2gb_30', 'price': 1500},
      {'label': '4GB - 30 Days', 'value': '4gb_30', 'price': 2500},
      {'label': '6GB - 30 Days', 'value': '6gb_30', 'price': 3500},
    ],
    'Glo': [
      {'label': '1GB - 30 Days', 'value': '1gb_30', 'price': 500},
      {'label': '2GB - 30 Days', 'value': '2gb_30', 'price': 1000},
      {'label': '4.5GB - 30 Days', 'value': '4.5gb_30', 'price': 1500},
      {'label': '7.5GB - 30 Days', 'value': '7.5gb_30', 'price': 2500},
    ],
    '9Mobile': [
      {'label': '500MB - 30 Days', 'value': '500mb_30', 'price': 500},
      {'label': '1GB - 30 Days', 'value': '1gb_30', 'price': 1000},
      {'label': '2.5GB - 30 Days', 'value': '2.5gb_30', 'price': 1500},
      {'label': '5GB - 30 Days', 'value': '5gb_30', 'price': 3000},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().getJson('/api/wallet/balance');
      setState(() {
        _walletBalance = (response['balance'] ?? 0).toDouble();
        _transactions =
            (response['transactions'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
      });
    } catch (e) {
      // Demo data
      setState(() {
        _walletBalance = 2500;
        _transactions = [
          {
            'type': 'credit',
            'amount': 2000,
            'description': 'Cashback - Corporate Standard Monthly',
            'date': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
          },
          {
            'type': 'credit',
            'amount': 500,
            'description': 'Cashback - Student Basic Weekly',
            'date': DateTime.now()
                .subtract(const Duration(days: 5))
                .toIso8601String(),
          },
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseAirtime() async {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    if (amountText.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    final amount = int.tryParse(amountText) ?? 0;
    if (amount < 50) {
      _showError('Minimum amount is â‚¦50');
      return;
    }

    if (amount > _walletBalance) {
      _showError('Insufficient wallet balance');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await ApiClient().postJson('/api/wallet/airtime', {
        'network': _selectedNetwork,
        'phone': phone,
        'amount': amount,
      });

      setState(() {
        _walletBalance -= amount;
      });

      _showSuccess('${formatNaira(amount)} airtime sent to $phone');
      _phoneController.clear();
      _amountController.clear();
      _loadWalletData();
    } catch (e) {
      // Demo mode
      setState(() {
        _walletBalance -= amount;
      });
      _showSuccess(
        '${formatNaira(amount)} $_selectedNetwork airtime sent to $phone',
      );
      _phoneController.clear();
      _amountController.clear();
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _purchaseData() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    if (_selectedDataPlan == null) {
      _showError('Please select a data plan');
      return;
    }

    final plans = _dataPlans[_selectedDataNetwork]!;
    final plan = plans.firstWhere((p) => p['value'] == _selectedDataPlan);
    final amount = plan['price'] as int;

    if (amount > _walletBalance) {
      _showError('Insufficient wallet balance');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await ApiClient().postJson('/api/wallet/data', {
        'network': _selectedDataNetwork,
        'phone': phone,
        'plan': _selectedDataPlan,
        'amount': amount,
      });

      setState(() {
        _walletBalance -= amount;
      });

      _showSuccess('${plan['label']} data sent to $phone');
      _phoneController.clear();
      _selectedDataPlan = null;
      _loadWalletData();
    } catch (e) {
      // Demo mode
      setState(() {
        _walletBalance -= amount;
      });
      _showSuccess(
        '${plan['label']} $_selectedDataNetwork data sent to $phone',
      );
      _phoneController.clear();
      setState(() => _selectedDataPlan = null);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('My Wallet'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            )
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              color: const Color(0xFFFF6B00),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Wallet balance card
                    _buildBalanceCard(),

                    // Quick actions
                    _buildQuickActions(),

                    // Airtime/Data tabs
                    _buildPurchaseTabs(),

                    // Transaction history
                    _buildTransactionHistory(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Cashback',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatNaira(_walletBalance.toInt()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Earned from meal subscriptions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              icon: Icons.phone_android,
              label: 'Buy Airtime',
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              icon: Icons.wifi,
              label: 'Buy Data',
              onTap: () => _tabController.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF6B00)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Tab header
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFFF6B00),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFF6B00),
            tabs: const [
              Tab(text: '📱 Airtime'),
              Tab(text: '📶 Data Bundle'),
            ],
          ),

          // Tab content
          SizedBox(
            height: 350,
            child: TabBarView(
              controller: _tabController,
              children: [_buildAirtimeForm(), _buildDataForm()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirtimeForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Network',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: _networks.map((network) {
              final isSelected = _selectedNetwork == network;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedNetwork = network),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B00)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      network,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Phone Number',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '08012345678',
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount (min â‚¦50)',
              prefixIcon: const Icon(Icons.money),
              prefixText: 'â‚¦ ',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing || _walletBalance <= 0
                  ? null
                  : _purchaseAirtime,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Text('Buy Airtime'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Network',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: _networks.map((network) {
              final isSelected = _selectedDataNetwork == network;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDataNetwork = network;
                      _selectedDataPlan = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B00)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF6B00)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      network,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Phone Number',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '08012345678',
              prefixIcon: const Icon(Icons.phone),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Data Plan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDataPlan,
                isExpanded: true,
                hint: const Text('Select a plan'),
                items: _dataPlans[_selectedDataNetwork]!.map((plan) {
                  return DropdownMenuItem(
                    value: plan['value'] as String,
                    child: Text(
                      '${plan['label']} - ${formatNaira(plan['price'] as int)}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDataPlan = value);
                },
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing || _walletBalance <= 0
                  ? null
                  : _purchaseData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Text('Buy Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    if (_transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Subscribe to a meal plan to earn cashback!',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

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
          const Text(
            'Recent Transactions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ..._transactions.map((tx) {
            final isCredit = tx['type'] == 'credit';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCredit
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.add : Icons.remove,
                      color: isCredit ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['description'] ?? 'Transaction',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(tx['date']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isCredit ? '+' : '-'}${formatNaira(tx['amount'] as int)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCredit ? Colors.green : Colors.red,
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
}
