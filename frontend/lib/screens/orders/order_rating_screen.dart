import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/config.dart';

/// ⭐ Order Rating Screen
/// Submit rating and review after order delivery (Chowdeck/Glovo standard)
class OrderRatingScreen extends StatefulWidget {
  final String orderId;
  final String? vendorId;
  final String? vendorName;
  final String? dispatcherId;
  final String? dispatcherName;

  const OrderRatingScreen({
    super.key,
    required this.orderId,
    this.vendorId,
    this.vendorName,
    this.dispatcherId,
    this.dispatcherName,
  });

  @override
  State<OrderRatingScreen> createState() => _OrderRatingScreenState();
}

class _OrderRatingScreenState extends State<OrderRatingScreen> {
  int _overallRating = 0;
  int _foodRating = 0;
  int _deliveryRating = 0;
  final TextEditingController _commentController = TextEditingController();

  bool _isSubmitting = false;
  bool _submitted = false;

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
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an overall rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/reviews'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'orderId': widget.orderId,
          'overallRating': _overallRating,
          'foodRating': _foodRating > 0 ? _foodRating : _overallRating,
          'deliveryRating': _deliveryRating > 0
              ? _deliveryRating
              : _overallRating,
          'comment': _commentController.text.trim(),
          'vendorId': widget.vendorId,
          'dispatcherId': widget.dispatcherId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });

        // Auto close after 2 seconds
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to submit review')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Thank you!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps us improve',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Order'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall rating
            const Text(
              'How was your overall experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _StarRating(
              rating: _overallRating,
              size: 48,
              onRatingChanged: (r) => setState(() => _overallRating = r),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_overallRating),
              style: TextStyle(
                color: _getRatingColor(_overallRating),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Food rating
            if (widget.vendorName != null) ...[
              _RatingRow(
                label: 'Food Quality',
                sublabel: widget.vendorName!,
                icon: Icons.restaurant,
                rating: _foodRating,
                onRatingChanged: (r) => setState(() => _foodRating = r),
              ),
              const SizedBox(height: 16),
            ],

            // Delivery rating
            if (widget.dispatcherName != null) ...[
              _RatingRow(
                label: 'Delivery',
                sublabel: widget.dispatcherName!,
                icon: Icons.delivery_dining,
                rating: _deliveryRating,
                onRatingChanged: (r) => setState(() => _deliveryRating = r),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            // Comment
            const Text(
              'Additional Comments (optional)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Tell us more about your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              maxLines: 4,
              maxLength: 500,
            ),

            const SizedBox(height: 24),

            // Quick feedback chips
            const Text(
              'Quick feedback',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeedbackChip(
                  label: '🔥 Hot & Fresh',
                  onTap: () => _addFeedback('Food was hot and fresh'),
                ),
                _FeedbackChip(
                  label: '⚡ Fast Delivery',
                  onTap: () => _addFeedback('Delivery was fast'),
                ),
                _FeedbackChip(
                  label: '😊 Friendly Rider',
                  onTap: () => _addFeedback('Rider was friendly'),
                ),
                _FeedbackChip(
                  label: '📦 Good Packaging',
                  onTap: () => _addFeedback('Great packaging'),
                ),
                _FeedbackChip(
                  label: '💰 Good Value',
                  onTap: () => _addFeedback('Good value for money'),
                ),
                _FeedbackChip(
                  label: '😕 Could Improve',
                  onTap: () => _addFeedback('Could be better'),
                  isNegative: true,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting || _overallRating == 0
                  ? null
                  : _submitReview,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Review', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }

  void _addFeedback(String text) {
    final current = _commentController.text;
    if (current.isEmpty) {
      _commentController.text = text;
    } else if (!current.contains(text)) {
      _commentController.text = '$current. $text';
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor 😞';
      case 2:
        return 'Poor 😕';
      case 3:
        return 'Average 😐';
      case 4:
        return 'Good 😊';
      case 5:
        return 'Excellent! 🤩';
      default:
        return 'Tap to rate';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final Function(int) onRatingChanged;

  const _StarRating({
    required this.rating,
    required this.size,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starNumber <= rating ? Icons.star : Icons.star_border,
              size: size,
              color: starNumber <= rating ? Colors.amber : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final int rating;
  final Function(int) onRatingChanged;

  const _RatingRow({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                return GestureDetector(
                  onTap: () => onRatingChanged(starNumber),
                  child: Icon(
                    starNumber <= rating ? Icons.star : Icons.star_border,
                    size: 24,
                    color: starNumber <= rating
                        ? Colors.amber
                        : Colors.grey[400],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isNegative;

  const _FeedbackChip({
    required this.label,
    required this.onTap,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isNegative
          ? Colors.red.withValues(alpha: 0.1)
          : Theme.of(context).primaryColor.withValues(alpha: 0.1),
    );
  }
}

/// Widget to display rating summary (for vendor/order details)
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalReviews;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.totalReviews,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: size),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.9),
        ),
        if (totalReviews != null) ...[
          Text(
            ' ($totalReviews)',
            style: TextStyle(color: Colors.grey[600], fontSize: size * 0.75),
          ),
        ],
      ],
    );
  }
}
