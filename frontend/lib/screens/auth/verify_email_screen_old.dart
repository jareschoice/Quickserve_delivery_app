import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../home/consumer_home.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get otpCode => _otpControllers.map((c) => c.text).join();

  void showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (otpCode.length != 6) {
      showSnack('Please enter the complete 6-digit code', error: true);
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      // For demo purposes, any 6-digit code works
      // In production, this will verify the actual OTP sent via email
      final success = await AuthService().verifyOTP(
        email: widget.email,
        otp: otpCode,
      );

      if (success) {
        showSnack('✅ Email verified successfully!');
        // Navigate to home screen
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ConsumerHome()),
          (route) => false,
        );
      } else {
        showSnack('Verification failed. Please try again.', error: true);
      }
    } catch (e) {
      showSnack('Verification failed: ${e.toString()}', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _loading = true);

    try {
      final success = await AuthService().resendOTP(email: widget.email);
      if (success) {
        showSnack('New OTP sent to ${widget.email}');
        // Clear current OTP input
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      } else {
        showSnack('Failed to resend OTP', error: true);
      }
    } catch (e) {
      showSnack('Error: ${e.toString()}', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          if (otpCode.length == 6) {
            _verifyOTP();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            // Icon and Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 60,
                color: Colors.green[600],
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'We sent a verification code to\n${widget.email}\n\n(Demo: Enter any 6-digit code)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOTPField(index)),
            ),
            
            const SizedBox(height: 32),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Verify Code',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Resend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: _loading ? null : _resendOTP,
                  child: const Text(
                    'Resend',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
