// ===============================
// FILE: lib/widgets/promo_code_widget.dart
// Promo Code Entry Widget for Checkout
// ===============================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Model for validated promo code response
class PromoCodeResult {
  final String code;
  final String description;
  final String discountType;
  final double discountValue;
  final double maxDiscount;
  final double minOrderAmount;
  final double calculatedDiscount;

  PromoCodeResult({
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrderAmount,
    required this.calculatedDiscount,
  });

  factory PromoCodeResult.fromJson(Map<String, dynamic> json) {
    return PromoCodeResult(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'percentage',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      maxDiscount: (json['maxDiscount'] ?? 0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      calculatedDiscount: (json['calculatedDiscount'] ?? 0).toDouble(),
    );
  }
}

/// Promo code widget for checkout flow
///
/// Usage:
/// ```dart
/// PromoCodeWidget(
///   orderAmount: 5000.0,
///   vendorId: 'vendor123',
///   baseUrl: 'http://localhost:5555/api',
///   authToken: 'your-auth-token',
///   onPromoApplied: (discount) {
///     setState(() => promoDiscount = discount);
///   },
///   onPromoRemoved: () {
///     setState(() => promoDiscount = 0);
///   },
/// )
/// ```
class PromoCodeWidget extends StatefulWidget {
  final double orderAmount;
  final String? vendorId;
  final String baseUrl;
  final String authToken;
  final Function(double discount) onPromoApplied;
  final VoidCallback onPromoRemoved;
  final Color? primaryColor;

  const PromoCodeWidget({
    super.key,
    required this.orderAmount,
    this.vendorId,
    required this.baseUrl,
    required this.authToken,
    required this.onPromoApplied,
    required this.onPromoRemoved,
    this.primaryColor,
  });

  @override
  State<PromoCodeWidget> createState() => _PromoCodeWidgetState();
}

class _PromoCodeWidgetState extends State<PromoCodeWidget> {
  final TextEditingController _codeController = TextEditingController();
  bool _isExpanded = false;
  bool _isLoading = false;
  String? _errorMessage;
  PromoCodeResult? _appliedPromo;

  Color get _primaryColor => widget.primaryColor ?? const Color(0xFFE53935);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validatePromo() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a promo code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/promo/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.authToken}',
        },
        body: json.encode({
          'code': code,
          'orderAmount': widget.orderAmount,
          'vendorId': widget.vendorId,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final promo = PromoCodeResult.fromJson(data['promo']);
        setState(() {
          _appliedPromo = promo;
          _isExpanded = false;
        });
        widget.onPromoApplied(promo.calculatedDiscount);
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Invalid promo code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to validate promo code';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _codeController.clear();
      _errorMessage = null;
    });
    widget.onPromoRemoved();
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedPromo != null) {
      return _buildAppliedPromoCard();
    }
    return _buildPromoEntry();
  }

  Widget _buildAppliedPromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_offer, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _appliedPromo!.code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Applied',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'You save ₦${_appliedPromo!.calculatedDiscount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removePromo,
            icon: const Icon(Icons.close, size: 20),
            color: Colors.grey[600],
            tooltip: 'Remove promo',
          ),
        ],
      ),
    );
  }

  Widget _buildPromoEntry() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header / Toggle
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    color: _primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Have a promo code?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expanded input section
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Enter code',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _primaryColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          onSubmitted: (_) => _validatePromo(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validatePromo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Apply',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Quick promo banner to show available promos
class AvailablePromoBanner extends StatelessWidget {
  final String promoCode;
  final String description;
  final VoidCallback onTap;
  final Color? accentColor;

  const AvailablePromoBanner({
    super.key,
    required this.promoCode,
    required this.description,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? const Color(0xFFE53935);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                promoCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

/// Checkout summary with promo discount
class CheckoutSummaryWithPromo extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double promoDiscount;
  final double serviceFee;

  const CheckoutSummaryWithPromo({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    this.promoDiscount = 0,
    this.serviceFee = 0,
  });

  double get total => subtotal + deliveryFee + serviceFee - promoDiscount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRow('Subtotal', subtotal),
          _buildRow('Delivery Fee', deliveryFee),
          if (serviceFee > 0) _buildRow('Service Fee', serviceFee),
          if (promoDiscount > 0) ...[
            _buildRow('Promo Discount', -promoDiscount, isDiscount: true),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₦${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDiscount ? Colors.green : Colors.grey[600],
            ),
          ),
          Text(
            isDiscount
                ? '-₦${amount.abs().toStringAsFixed(0)}'
                : '₦${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDiscount ? Colors.green : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
