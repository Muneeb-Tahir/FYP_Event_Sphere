// lib/pages/change_password_page.dart
// Change password with Dark Purple Theme

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _particleController = AnimationController(duration: const Duration(seconds: 12), vsync: this)..repeat();
    _pulseController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..forward();
  }

  void _initParticles() {
    for (int i = 0; i < 8; i++) {
      _particles.add(_Particle(x: _random.nextDouble(), y: _random.nextDouble(), size: 2 + _random.nextDouble() * 2, speed: 0.2 + _random.nextDouble() * 0.3, opacity: 0.15 + _random.nextDouble() * 0.2));
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Password changed successfully!')]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: Stack(
        children: [
          _buildParticleBackground(),
          _buildBackgroundGlows(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) => CustomPaint(size: MediaQuery.of(context).size, painter: _ParticlePainter(particles: _particles, animationValue: _particleController.value)),
    );
  }

  Widget _buildBackgroundGlows() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.8 + _pulseController.value * 0.4;
        return Positioned(
          top: -50, right: -50,
          child: Transform.scale(scale: pulseValue, child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF9D4EDD).withOpacity(0.2), const Color(0xFF9D4EDD).withOpacity(0.0)])))),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E).withOpacity(0.9),
        border: Border(bottom: BorderSide(color: const Color(0xFF3D3557).withOpacity(0.5))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2D2645), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF60A5FA)),
                  SizedBox(width: 12),
                  Expanded(child: Text('Choose a strong password with at least 6 characters.', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Current Password
            _buildLabel('Current Password'),
            const SizedBox(height: 10),
            _buildPasswordField(_currentPasswordController, 'Enter current password', _showCurrentPassword, () => setState(() => _showCurrentPassword = !_showCurrentPassword), (value) {
              if (value == null || value.isEmpty) return 'Please enter your current password';
              return null;
            }),
            const SizedBox(height: 22),

            // New Password
            _buildLabel('New Password'),
            const SizedBox(height: 10),
            _buildPasswordField(_newPasswordController, 'Enter new password', _showNewPassword, () => setState(() => _showNewPassword = !_showNewPassword), (value) {
              if (value == null || value.isEmpty) return 'Please enter a new password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            }),
            const SizedBox(height: 22),

            // Confirm Password
            _buildLabel('Confirm New Password'),
            const SizedBox(height: 10),
            _buildPasswordField(_confirmPasswordController, 'Confirm new password', _showConfirmPassword, () => setState(() => _showConfirmPassword = !_showConfirmPassword), (value) {
              if (value == null || value.isEmpty) return 'Please confirm your new password';
              if (value != _newPasswordController.text) return 'Passwords do not match';
              return null;
            }),
            const SizedBox(height: 36),

            // Submit Button
            GestureDetector(
              onTap: _isLoading ? null : _changePassword,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_reset, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB8A9C9)));
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool showPassword, VoidCallback onToggle, String? Function(String?) validator) {
    return TextFormField(
      controller: controller,
      obscureText: !showPassword,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFF9D4EDD),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B5B7A)),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9D4EDD)),
        suffixIcon: IconButton(
          icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFB8A9C9)),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3D3557))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF3D3557))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;
  _ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (animationValue + p.y) % 1.0;
      final x = p.x * size.width + math.sin(progress * 2 * math.pi) * 15 * p.speed;
      final y = (1 - progress) * size.height;
      final opacity = (p.opacity * (1 - progress * 0.5)).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), p.size, Paint()..color = Color.lerp(const Color(0xFF9D4EDD), const Color(0xFFE040FB), p.x)!.withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.animationValue != animationValue;
}
