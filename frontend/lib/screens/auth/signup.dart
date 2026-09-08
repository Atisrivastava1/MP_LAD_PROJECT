import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../auditor/auditor_dashboard.dart';
import '../data_manager/data_manager_dashboard.dart';

/// Sign Up Screen — new user registration.
/// Fields map to the users DB table:
/// user_id, name, username, password_hash, role, department, email, is_active, created_at, updated_at
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  String _selectedRole = 'Auditor';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final success = await ApiService.signup(
          name: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole == 'Data Manager' ? 'DATA_MANAGER' : 'AUDITOR',
          department: _departmentController.text.trim(),
        );

        if (!mounted) return;
        
        if (success) {
          Widget destination;
          if (ApiService.currentUser?.role == 'DATA_MANAGER') {
            destination = const DataManagerDashboardScreen();
          } else {
            destination = const AuditorDashboardScreen();
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up failed: User may already exist.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign up error: ')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // -- Desktop Layout --------------------------------------------------------
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Branding Panel (50%)
        Expanded(
          child: Container(
            color: const Color(0xFF0B1F3A),
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 48),
                const Text(
                  'Secure - Transparent - Accountable',
                  style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Sign Up Panel (50%)
        Expanded(
          child: Container(
            color: const Color(0xFFF5F7FA), // Light background for desktop form
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Container(
                  width: 440, // Fixed width card
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildForm(isDark: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Mobile Layout ---------------------------------------------------------
  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(isMobile: true),
            const SizedBox(height: 32),
            _buildForm(isDark: true),
            const SizedBox(height: 24),
            const Text(
              'Secure - Transparent - Accountable',
              style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({bool isMobile = false}) {
    return Column(
      children: [
        Image.asset('assets/images/emblem.png', height: isMobile ? 80 : 140),
        SizedBox(height: isMobile ? 24 : 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/logo.png',
                  height: isMobile ? 56 : 64, width: isMobile ? 56 : 64, fit: BoxFit.cover),
            ),
            SizedBox(width: isMobile ? 14 : 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MPLADS SENTINEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Create your account',
                  style: TextStyle(color: Colors.white70, fontSize: isMobile ? 12 : 14),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm({required bool isDark}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDark) ...[
            const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1F3A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
          
          _buildTextField(
            controller: _nameController,
            label: 'Full Name *',
            icon: Icons.person_outline,
            isDark: isDark,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _usernameController,
            label: 'Username *',
            icon: Icons.alternate_email,
            isDark: isDark,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _emailController,
            label: 'Email Address *',
            icon: Icons.email_outlined,
            isDark: isDark,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildRoleDropdown(isDark: isDark),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _departmentController,
            label: 'Department (Optional)',
            icon: Icons.business_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password *',
            obscureText: _obscurePassword,
            isDark: isDark,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password *',
            obscureText: _obscureConfirm,
            isDark: isDark,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 32),
          
          _buildSubmitButton(),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Already have an account?", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Sign In', style: TextStyle(color: Color(0xFF2F6FED), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration(label, icon, isDark),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required bool isDark,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration(label, Icons.lock_outline, isDark).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown({required bool isDark}) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      dropdownColor: isDark ? const Color(0xFF14284A) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
      decoration: _inputDecoration('Select Role', Icons.people_outline, isDark),
      items: const [
        DropdownMenuItem(value: 'Auditor', child: Text('Auditor')),
        DropdownMenuItem(value: 'Data Manager', child: Text('Data Manager')),
      ],
      onChanged: (value) => setState(() => _selectedRole = value!),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F6FED),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('CREATE ACCOUNT',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 16)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
      prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.grey.shade500),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F7FA),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2F6FED)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
