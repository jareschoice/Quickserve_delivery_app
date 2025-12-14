import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/config.dart';

/// 🎁 Referral & Loyalty Screen
/// Chowdeck/Glovo-style referral and rewards program
class ReferralLoyaltyScreen extends StatefulWidget {
  const ReferralLoyaltyScreen({super.key});

  @override
  State<ReferralLoyaltyScreen> createState() => _ReferralLoyaltyScreenState();
}

class _ReferralLoyaltyScreenState extends State<ReferralLoyaltyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;

  // Referral data
  String? _referralCode;
  String? _shareUrl;
  int _referralCount = 0;
  List<Map<String, dynamic>> _recentReferrals = [];

  // Loyalty data
  int _points = 0;
  int _totalEarned = 0;
  String _tier = 'bronze';
  String _tierLabel = 'Bronze';
  int _tierDiscount = 0;
  String? _nextTier;
  int _pointsToNextTier = 0;
  double _pointsValue = 0;

  // Config
  int _pointsPerOrder = 10;
  int _pointsPerReferral = 100;
  int _minRedeemPoints = 200;
  double _pointsToNgn = 0.5;

  String get _baseUrl => AppConfig.backendBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/referral/my-referrals'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final referral = data['referral'];
          final loyalty = data['loyalty'];
          final config = data['config'];

          setState(() {
            _referralCode = referral['code'];
            _shareUrl = referral['shareUrl'];
            _referralCount = referral['referralCount'] ?? 0;
            _recentReferrals = List<Map<String, dynamic>>.from(
              referral['recentReferrals'] ?? [],
            );

            _points = loyalty['points'] ?? 0;
            _totalEarned = loyalty['totalEarned'] ?? 0;
            _tier = loyalty['tier'] ?? 'bronze';
            _tierLabel = loyalty['tierLabel'] ?? 'Bronze';
            _tierDiscount = loyalty['tierDiscount'] ?? 0;
            _nextTier = loyalty['nextTier'];
            _pointsToNextTier = loyalty['pointsToNextTier'] ?? 0;
            _pointsValue = (loyalty['pointsValue'] ?? 0).toDouble();

            _pointsPerOrder = config['pointsPerOrder'] ?? 10;
            _pointsPerReferral = config['pointsPerReferral'] ?? 100;
            _minRedeemPoints = config['minRedeemPoints'] ?? 200;
            _pointsToNgn = (config['pointsToNgn'] ?? 0.5).toDouble();

            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? 'Failed to load data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyCode() {
    if (_referralCode != null) {
      Clipboard.setData(ClipboardData(text: _referralCode!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
    }
  }

  void _shareCode() {
    if (_referralCode != null) {
      SharePlus.instance.share(
        ShareParams(
          text:
              'Join QuickServe with my code $_referralCode and get bonus points! $_shareUrl',
          subject: 'Join QuickServe!',
        ),
      );
    }
  }

  Future<void> _redeemPoints() async {
    if (_points < _minRedeemPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need at least $_minRedeemPoints points to redeem'),
        ),
      );
      return;
    }

    final pointsToRedeem = await showDialog<int>(
      context: context,
      builder: (context) => _RedeemDialog(
        availablePoints: _points,
        minPoints: _minRedeemPoints,
        pointsToNgn: _pointsToNgn,
      ),
    );

    if (pointsToRedeem != null && mounted) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/api/referral/redeem-points'),
          headers: await _getHeaders(),
          body: jsonEncode({'points': pointsToRedeem}),
        );

        final data = jsonDecode(response.body);
        if (!mounted) return;
        if (response.statusCode == 200 && data['success'] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to redeem')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.card_giftcard), text: 'Referrals'),
            Tab(icon: Icon(Icons.stars), text: 'Loyalty'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : TabBarView(
              controller: _tabController,
              children: [_buildReferralTab(), _buildLoyaltyTab()],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildReferralTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Referral card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 48,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Invite Friends & Earn',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get $_pointsPerReferral points for each friend who orders!',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Referral code
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _referralCode ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyCode,
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Share button
                    ElevatedButton.icon(
                      onPressed: _shareCode,
                      icon: const Icon(Icons.share),
                      label: const Text('Share with Friends'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.people,
                    value: _referralCount.toString(),
                    label: 'Friends Referred',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.stars,
                    value: '${_referralCount * _pointsPerReferral}',
                    label: 'Points Earned',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // How it works
            const Text(
              'How it works',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _HowItWorksStep(
              number: '1',
              title: 'Share your code',
              description: 'Send your referral code to friends',
            ),
            _HowItWorksStep(
              number: '2',
              title: 'Friend signs up',
              description: 'They get 50 bonus points on signup',
            ),
            _HowItWorksStep(
              number: '3',
              title: 'Friend orders',
              description:
                  'You get $_pointsPerReferral points after their first order',
            ),

            if (_recentReferrals.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Recent Referrals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._recentReferrals.map(
                (r) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(r['referredUserName'] ?? 'Friend'),
                  subtitle: Text('+${r['pointsEarned']} points'),
                  trailing: Text(
                    _formatDate(r['earnedAt']),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tier card
            Card(
              color: _getTierColor(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(_getTierIcon(), size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      '$_tierLabel Member',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_tierDiscount > 0)
                      Text(
                        '$_tierDiscount% discount on all orders!',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    const SizedBox(height: 16),

                    // Progress to next tier
                    if (_nextTier != null) ...[
                      Text(
                        '$_pointsToNextTier points to ${_nextTier!.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _getProgressToNextTier(),
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Points balance
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Your Points',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _points.toString(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      '= ₦${_pointsValue.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _points >= _minRedeemPoints
                          ? _redeemPoints
                          : null,
                      child: const Text('Redeem Points'),
                    ),
                    if (_points < _minRedeemPoints)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Need ${_minRedeemPoints - _points} more points to redeem',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Earning info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Earn Points',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EarnRow(
                      icon: Icons.shopping_bag,
                      text: 'Complete an order',
                      points: '+$_pointsPerOrder pts',
                    ),
                    _EarnRow(
                      icon: Icons.person_add,
                      text: 'Refer a friend',
                      points: '+$_pointsPerReferral pts',
                    ),
                    _EarnRow(
                      icon: Icons.star,
                      text: 'Leave a review',
                      points: '+5 pts',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tier benefits
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Benefits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._getTierBenefits().map(
                      (b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(b)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (_tier) {
      case 'silver':
        return Colors.blueGrey;
      case 'gold':
        return Colors.amber[700]!;
      case 'platinum':
        return Colors.indigo;
      default:
        return Colors.brown;
    }
  }

  IconData _getTierIcon() {
    switch (_tier) {
      case 'silver':
        return Icons.workspace_premium;
      case 'gold':
        return Icons.emoji_events;
      case 'platinum':
        return Icons.diamond;
      default:
        return Icons.military_tech;
    }
  }

  double _getProgressToNextTier() {
    if (_nextTier == null) return 1.0;
    final tierThresholds = {'silver': 500, 'gold': 2000, 'platinum': 5000};
    final nextThreshold = tierThresholds[_nextTier] ?? 500;
    final currentThreshold = tierThresholds[_tier] ?? 0;
    final progress = _totalEarned - currentThreshold;
    final required = nextThreshold - currentThreshold;
    return (progress / required).clamp(0.0, 1.0);
  }

  List<String> _getTierBenefits() {
    final benefits = {
      'bronze': [
        'Earn points on every order',
        'Access to referral program',
        'Birthday bonus points',
      ],
      'silver': [
        '5% discount on all orders',
        'Priority customer support',
        'Early access to promotions',
      ],
      'gold': [
        '10% discount on all orders',
        'Free delivery on orders over ₦5,000',
        'Exclusive Gold member deals',
      ],
      'platinum': [
        '15% discount on all orders',
        'Free delivery on all orders',
        'VIP event invitations',
      ],
    };
    return benefits[_tier] ?? benefits['bronze']!;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(number, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String points;

  const _EarnRow({
    required this.icon,
    required this.text,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          Text(
            points,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RedeemDialog extends StatefulWidget {
  final int availablePoints;
  final int minPoints;
  final double pointsToNgn;

  const _RedeemDialog({
    required this.availablePoints,
    required this.minPoints,
    required this.pointsToNgn,
  });

  @override
  State<_RedeemDialog> createState() => _RedeemDialogState();
}

class _RedeemDialogState extends State<_RedeemDialog> {
  late int _selectedPoints;

  @override
  void initState() {
    super.initState();
    _selectedPoints = widget.availablePoints;
  }

  @override
  Widget build(BuildContext context) {
    final value = _selectedPoints * widget.pointsToNgn;

    return AlertDialog(
      title: const Text('Redeem Points'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Available: ${widget.availablePoints} points'),
          const SizedBox(height: 16),
          Slider(
            value: _selectedPoints.toDouble(),
            min: widget.minPoints.toDouble(),
            max: widget.availablePoints.toDouble(),
            divisions: (widget.availablePoints - widget.minPoints) ~/ 50 + 1,
            label: '$_selectedPoints pts',
            onChanged: (v) => setState(() => _selectedPoints = v.toInt()),
          ),
          const SizedBox(height: 8),
          Text(
            '$_selectedPoints points = ₦${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedPoints),
          child: const Text('Redeem'),
        ),
      ],
    );
  }
}
