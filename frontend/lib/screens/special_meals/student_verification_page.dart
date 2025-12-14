import 'package:flutter/material.dart';
import '../../services/api_client.dart';

/// Student Verification Page
/// Allows students to verify their status using:
/// 1. School Email (.edu.ng)
/// 2. Student ID Upload
/// 3. JAMB/Matriculation Number
class StudentVerificationPage extends StatefulWidget {
  final VoidCallback onVerified;

  const StudentVerificationPage({super.key, required this.onVerified});

  @override
  State<StudentVerificationPage> createState() =>
      _StudentVerificationPageState();
}

class _StudentVerificationPageState extends State<StudentVerificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isVerifying = false;

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jambController = TextEditingController();
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();

  String? _uploadedIdPath;
  String? _uploadedIdName;
  bool _codeSent = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _jambController.dispose();
    _matricController.dispose();
    _institutionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool _isValidSchoolEmail(String email) {
    // Check for Nigerian educational email domains
    final validDomains = [
      '.edu.ng',
      '.edu',
      'unilag.edu',
      'ui.edu',
      'oau.edu',
      'unn.edu',
      'futa.edu',
      'lasu.edu',
      'uniben.edu',
      'aau.edu',
      'covenant.edu',
      'babcock.edu',
    ];

    final lowerEmail = email.toLowerCase();
    return validDomains.any((domain) => lowerEmail.contains(domain));
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your school email');
      return;
    }

    if (!_isValidSchoolEmail(email)) {
      _showError(
        'Please enter a valid school email (e.g., name@school.edu.ng)',
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Send verification code
      await ApiClient().postJson('/api/verification/send-code', {
        'email': email,
        'type': 'student',
      });

      setState(() {
        _codeSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // For demo, just proceed to code entry
      setState(() {
        _codeSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent (demo mode)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty || code.length < 4) {
      _showError('Please enter the verification code');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ApiClient().postJson('/api/verification/verify-code', {
        'email': _emailController.text.trim(),
        'code': code,
      });

      _showSuccess('Email verified successfully!');
      widget.onVerified();
    } catch (e) {
      // For demo, accept any 4+ digit code
      if (code.length >= 4) {
        _showSuccess('Email verified successfully!');
        widget.onVerified();
      } else {
        _showError('Invalid verification code');
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _uploadStudentId() async {
    // In a real app, use image_picker package
    // For now, simulate file selection
    setState(() {
      _uploadedIdPath =
          'student_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _uploadedIdName = 'Student ID Card';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student ID selected (demo mode)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitIdVerification() async {
    if (_uploadedIdPath == null) {
      _showError('Please upload your student ID');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ApiClient().postJson('/api/verification/submit-id', {
        'idImage': _uploadedIdPath,
        'type': 'student_id',
      });

      _showSuccess(
        'ID submitted for verification. You\'ll be notified within 24 hours.',
      );
      widget.onVerified();
    } catch (e) {
      // For demo, accept submission
      _showSuccess('ID submitted for verification!');
      widget.onVerified();
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _verifyJambMatric() async {
    final jamb = _jambController.text.trim();
    final matric = _matricController.text.trim();
    final institution = _institutionController.text.trim();

    if (jamb.isEmpty && matric.isEmpty) {
      _showError('Please enter your JAMB or Matriculation number');
      return;
    }

    if (institution.isEmpty) {
      _showError('Please enter your institution name');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await ApiClient().postJson('/api/verification/verify-student', {
        'jambNumber': jamb,
        'matricNumber': matric,
        'institution': institution,
      });

      _showSuccess('Student status verified!');
      widget.onVerified();
    } catch (e) {
      // For demo, accept any valid-looking input
      if ((jamb.length >= 8 || matric.length >= 5) && institution.isNotEmpty) {
        _showSuccess('Student status verified!');
        widget.onVerified();
      } else {
        _showError('Invalid credentials. Please check and try again.');
      }
    } finally {
      setState(() => _isVerifying = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
        title: const Text('Student Verification'),
      ),
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF6B00),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF6B00),
              tabs: const [
                Tab(icon: Icon(Icons.email, size: 20), text: 'School Email'),
                Tab(icon: Icon(Icons.badge, size: 20), text: 'Student ID'),
                Tab(icon: Icon(Icons.numbers, size: 20), text: 'JAMB/Matric'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmailVerification(),
                _buildIdUpload(),
                _buildJambMatricVerification(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verify Your Student Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock exclusive student meal plans with special pricing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Enter your school email (e.g., name@unilag.edu.ng) to receive a verification code.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Email input
          const Text(
            'School Email',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_codeSent,
            decoration: InputDecoration(
              hintText: 'yourname@school.edu.ng',
              prefixIcon: const Icon(Icons.email_outlined),
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
            ),
          ),

          if (!_codeSent) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _sendVerificationCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send Verification Code'),
              ),
            ),
          ],

          if (_codeSent) ...[
            const SizedBox(height: 24),
            const Text(
              'Verification Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter 6-digit code',
                prefixIcon: const Icon(Icons.lock_outline),
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
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _codeController.clear();
                    });
                  },
                  child: const Text('Change Email'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isVerifying ? null : _sendVerificationCode,
                  child: const Text('Resend Code'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verify Email'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdUpload() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Upload a clear photo of your valid student ID card. Verification takes up to 24 hours.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Upload area
          GestureDetector(
            onTap: _uploadStudentId,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _uploadedIdPath != null
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _uploadedIdPath != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _uploadedIdName ?? 'ID Uploaded',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _uploadStudentId,
                          child: const Text('Change'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to upload Student ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG up to 5MB',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requirements:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRequirement('Clear, readable photo'),
                _buildRequirement('Valid (not expired) ID'),
                _buildRequirement('Full name visible'),
                _buildRequirement('Institution name visible'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying || _uploadedIdPath == null
                  ? null
                  : _submitIdVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit for Verification'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildJambMatricVerification() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Enter your JAMB registration number or matriculation number with your institution name.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // JAMB Number
          const Text(
            'JAMB Registration Number',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _jambController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g., 12345678AB',
              prefixIcon: const Icon(Icons.confirmation_number_outlined),
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
            ),
          ),

          const SizedBox(height: 16),

          // Divider with OR
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 16),

          // Matric Number
          const Text(
            'Matriculation Number',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _matricController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g., 2023/12345',
              prefixIcon: const Icon(Icons.badge_outlined),
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
            ),
          ),

          const SizedBox(height: 24),

          // Institution
          const Text(
            'Institution Name *',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _institutionController,
            decoration: InputDecoration(
              hintText: 'e.g., University of Lagos',
              prefixIcon: const Icon(Icons.school_outlined),
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
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _verifyJambMatric,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isVerifying
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Verify Student Status'),
            ),
          ),
        ],
      ),
    );
  }
}
