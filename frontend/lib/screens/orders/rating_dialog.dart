import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';

/// Rating Dialog - Shows after order delivery to rate vendor and rider
class RatingDialog extends StatefulWidget {
  final String orderId;
  final String? vendorId;
  final String? vendorName;
  final String? riderId;
  final String? riderName;

  const RatingDialog({
    super.key,
    required this.orderId,
    this.vendorId,
    this.vendorName,
    this.riderId,
    this.riderName,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _vendorRating = 5.0;
  double _riderRating = 5.0;
  final TextEditingController _vendorComment = TextEditingController();
  final TextEditingController _riderComment = TextEditingController();
  bool _submitting = false;
  int _currentStep = 0; // 0 = vendor, 1 = rider

  @override
  void dispose() {
    _vendorComment.dispose();
    _riderComment.dispose();
    super.dispose();
  }

  Future<void> _submitRatings() async {
    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final api = ApiClient();

      // Submit vendor rating
      if (widget.vendorId != null) {
        await api.postJson('/reviews', {
          'orderId': widget.orderId,
          'targetType': 'vendor',
          'targetId': widget.vendorId,
          'rating': _vendorRating.round(),
          'comment': _vendorComment.text.trim(),
        }, token: token);
      }

      // Submit rider rating
      if (widget.riderId != null) {
        await api.postJson('/reviews', {
          'orderId': widget.orderId,
          'targetType': 'rider',
          'targetId': widget.riderId,
          'rating': _riderRating.round(),
          'comment': _riderComment.text.trim(),
        }, token: token);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0x1AFF6B00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFF6B00),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rate Your Experience',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps us improve',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Step indicator
              if (widget.vendorId != null && widget.riderId != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(0, 'Restaurant'),
                    Container(
                      width: 40,
                      height: 2,
                      color: _currentStep >= 1
                          ? const Color(0xFFFF6B00)
                          : Colors.grey[300],
                    ),
                    _buildStepIndicator(1, 'Rider'),
                  ],
                ),
              const SizedBox(height: 20),

              // Rating content
              if (_currentStep == 0 && widget.vendorId != null)
                _buildVendorRating()
              else if (_currentStep == 1 && widget.riderId != null)
                _buildRiderRating()
              else if (widget.vendorId != null)
                _buildVendorRating()
              else if (widget.riderId != null)
                _buildRiderRating(),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_currentStep == 1) {
                                setState(() => _currentStep = 0);
                              } else {
                                Navigator.of(context).pop(false);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_currentStep == 1 ? 'Back' : 'Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_currentStep == 0 && widget.riderId != null) {
                                setState(() => _currentStep = 1);
                              } else {
                                _submitRatings();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              (_currentStep == 0 && widget.riderId != null)
                                  ? 'Next'
                                  : 'Submit',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF6B00) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? const Color(0xFFFF6B00) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorRating() {
    return Column(
      children: [
        Icon(Icons.storefront, size: 40, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          widget.vendorName ?? 'Restaurant',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        RatingBar.builder(
          initialRating: _vendorRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 40,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, _) =>
              const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
          onRatingUpdate: (rating) {
            setState(() => _vendorRating = rating);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_vendorRating),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _vendorComment,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your experience (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildRiderRating() {
    return Column(
      children: [
        Icon(Icons.delivery_dining, size: 40, color: Colors.grey[700]),
        const SizedBox(height: 8),
        Text(
          widget.riderName ?? 'Delivery Rider',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        RatingBar.builder(
          initialRating: _riderRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemSize: 40,
          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
          itemBuilder: (context, _) =>
              const Icon(Icons.star_rounded, color: Color(0xFFFFB800)),
          onRatingUpdate: (rating) {
            setState(() => _riderRating = rating);
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_riderRating),
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _riderComment,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'How was the delivery? (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excellent! 🌟';
    if (rating >= 4) return 'Great! 😊';
    if (rating >= 3) return 'Good 👍';
    if (rating >= 2) return 'Fair 😐';
    return 'Poor 😞';
  }
}

/// Helper function to show rating dialog after order delivery
Future<bool?> showRatingDialog(
  BuildContext context, {
  required String orderId,
  String? vendorId,
  String? vendorName,
  String? riderId,
  String? riderName,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => RatingDialog(
      orderId: orderId,
      vendorId: vendorId,
      vendorName: vendorName,
      riderId: riderId,
      riderName: riderName,
    ),
  );
}
