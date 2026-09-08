import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'auditor_dashboard.dart';
import 'data_manager_dashboard.dart';

/// Login / Role Selection screen — first screen in the app flow.
/// Order: Logo -> Username -> Password -> Forgot Password link
///        -> Role -> Login button.
///
/// After login, routes to the correct dashboard based on role:
///   Auditor -> AuditorDashboardScreen
///   Data Officer -> DataManagerDashboardScreen
///   (other roles fall back to AuditorDashboardScreen for now,
///    since their dedicated dashboards aren't part of this prototype)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showForgotPassword = false;
  String? _selectedRole;

  final List<String> _roles = const [
    'Data Manager',
    'Auditor',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await ApiService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
      );

      if (!mounted) return;

      Widget destination;
      switch (user.role) {
        case 'Data Manager':
          destination = const DataManagerDashboardScreen();
          break;
        default:
          destination = const AuditorDashboardScreen();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F3A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Check if it's desktop width
            if (constraints.maxWidth >= 900) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }

  // ── Desktop Layout ────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Branding Panel (50%)
        Expanded(
          child: Container(
            color: const Color(0xFF0B1F3A),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 48),
                const Text(
                  'Secure · Transparent · Accountable',
                  style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.5),
                ),
              ],
            ),
          ),
        ),
        // Right Login Panel (50%)
        Expanded(
          child: Container(
            color: const Color(0xFFF5F7FA), // Light background for desktop login form
            child: Center(
              child: Container(
                width: 400, // Fixed width card
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1F3A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _buildUsernameField(isDark: false),
                      const SizedBox(height: 16),
                      _buildPasswordField(isDark: false),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleDropdown(isDark: false),
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?", style: TextStyle(color: Colors.black54, fontSize: 13)),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed('/signup'),
                            child: const Text('Sign Up', style: TextStyle(color: Color(0xFF2F6FED), fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              _buildLogo(),
              const SizedBox(height: 32),
              _buildUsernameField(isDark: true),
              const SizedBox(height: 16),
              _buildPasswordField(isDark: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _showForgotPassword = !_showForgotPassword),
                  child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70)),
                ),
              ),
              if (_showForgotPassword) _buildForgotPasswordField(isDark: true),
              const SizedBox(height: 16),
              _buildRoleDropdown(isDark: true),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: Colors.white54, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/signup'),
                    child: const Text('Sign Up', style: TextStyle(color: Color(0xFF2F6FED), fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Secure · Transparent · Accountable',
                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.shield_outlined, size: 40, color: Color(0xFF0B1F3A)),
        ),
        const SizedBox(height: 16),
        const Text(
          'MPLADS SENTINEL',
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        const Text(
          'AI-Based Fraud & Anomaly Detection',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildUsernameField({required bool isDark}) {
    return TextFormField(
      controller: _usernameController,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration('Username', Icons.person_outline, isDark),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Username is required' : null,
    );
  }

  Widget _buildPasswordField({required bool isDark}) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: _inputDecoration('Password', Icons.lock_outline, isDark).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
    );
  }

  Widget _buildRoleDropdown({required bool isDark}) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      dropdownColor: isDark ? const Color(0xFF14284A) : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
      decoration: _inputDecoration('Select Role', Icons.people_outline, isDark),
      items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
      onChanged: (value) => setState(() => _selectedRole = value),
    );
  }

  Widget _buildForgotPasswordField({required bool isDark}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          TextFormField(
            controller: _forgotEmailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _inputDecoration('Enter your email address', Icons.email_outlined, isDark),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: backend — POST /api/auth/forgot-password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset link sent to your email.')),
                );
                setState(() => _showForgotPassword = false);
                _forgotEmailController.clear();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2F6FED)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Send Reset Link', style: TextStyle(color: Color(0xFF2F6FED))),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
            : const Text('LOGIN',
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
