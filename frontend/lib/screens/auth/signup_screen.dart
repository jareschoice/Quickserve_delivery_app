// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../widgets/primary_button.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'consumer';
  bool _loading = false;
  String _appLabel = 'QuickServe';

  @override
  void initState() {
    super.initState();
    _loadRoleAndLabel();
  }

  Future<void> _loadRoleAndLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('role');
    if (savedRole != null && mounted) {
      setState(() {
        _role = savedRole;
        _appLabel = savedRole == 'vendor'
            ? 'QuickVendor'
            : savedRole == 'rider'
                ? 'QuickRide'
                : 'QuickServe';
      });
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullName.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty) {
      showSnack(context, 'Please fill all fields', error: true);
      return;
    }

    setState(() => _loading = true);
    final success = await AuthService().signup(
      _role,
      _fullName.text,
      _email.text,
      _password.text,
    );
    setState(() => _loading = false);

    if (success) {
      showSnack(context, 'Account created. Check your email for verification.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(email: _email.text),
        ),
      );
    } else {
      showSnack(context, 'Sign up failed. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_appLabel — Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'consumer', child: Text('Consumer')),
                DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                DropdownMenuItem(value: 'rider', child: Text('Rider')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'consumer'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              onPressed: _submit,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
