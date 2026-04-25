// lib/pages/login_page.dart
// Enhanced Event Sphere Login Page with dramatic animations

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../widgets/glass_card.dart';
import '../utils/validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  String error = '';
  bool loading = false;
  bool obscurePassword = true;

  late AnimationController _backgroundController;
  late AnimationController _formController;
  late Animation<double> _formSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _formController.forward();
    });
  }

  void _login() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      // Use Riverpod auth provider instead of AuthService directly
      // This ensures the auth state is updated across all widgets
      final result = await ref.read(authProvider.notifier).signIn(
        emailController.text.trim(),
        passwordController.text,
      );

      result.when(
        success: (_) {
          Navigator.pushReplacementNamed(context, '/home');
        },
        failure: (errorMessage, _) {
          setState(() {
            error = errorMessage;
          });
          _shakeError();
        },
      );
    } catch (e) {
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
      // Shake animation for error
      _shakeError();
    }

    setState(() {
      loading = false;
    });
  }

  void _shakeError() {
    // Trigger rebuild for shake effect
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _backgroundController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0B14),  // Deep purple-black
              Color(0xFF1A0F2E),  // Dark purple
              Color(0xFF2D1B4E),  // Slightly lighter purple
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            ..._buildAnimatedBackground(),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.top,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo section
                        _buildLogo(),

                        const SizedBox(height: 40),

                        // Login form
                        AnimatedBuilder(
                          animation: _formController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _formSlide.value),
                              child: Opacity(
                                opacity: _formFade.value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildLoginForm(),
                        ),

                        const SizedBox(height: 24),

                        // Register link
                        _buildRegisterLink(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedBackground() {
    return [
      // Large gradient orb top-right - Purple glow
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _backgroundController.value * 2 * math.pi * 0.1,
              child: child,
            );
          },
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9D4EDD).withOpacity(0.4),  // Purple
                  const Color(0xFF9D4EDD).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      // Bottom-left orb - Magenta glow
      Positioned(
        bottom: -150,
        left: -100,
        child: AnimatedBuilder(
          animation: _backgroundController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                math.sin(_backgroundController.value * 2 * math.pi) * 20,
                math.cos(_backgroundController.value * 2 * math.pi) * 20,
              ),
              child: child,
            );
          },
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFE040FB).withOpacity(0.25),  // Magenta
                  const Color(0xFFE040FB).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Column(
        children: [
          // App icon with purple glow - modern stacked design
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9D4EDD), Color(0xFFE040FB)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9D4EDD).withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFFE040FB).withOpacity(0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating sparkle effect
                Transform.rotate(
                  angle: 0.4,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 50,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                // Main diamond/sphere icon
                const Icon(
                  Icons.diamond_outlined,
                  size: 38,
                  color: Colors.white,
                ),
                // Top sparkle
                Positioned(
                  top: 12,
                  right: 15,
                  child: Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Script-style app name
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFE040FB), Colors.white, Color(0xFF9D4EDD)],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'EventSphere',
              style: GoogleFonts.pacifico(
                fontSize: 42,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                letterSpacing: 1,
                shadows: [
                  Shadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tagline
          Text(
            'Discover amazing events and connect',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 28,
      blur: 25,
      child: Column(
        children: [
          // Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE0E7FF)],
            ).createShader(bounds),
            child: const Text(
              "Welcome Back",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to continue",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),

          // Form wrapper for validation
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Email field
                _buildTextField(
                  controller: emailController,
                  focusNode: _emailFocus,
                  label: 'Email Address',
                  hint: 'your@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),

                // Password field
                _buildPasswordField(),
              ],
            ),
          ),

          // Error message
          if (error.isNotEmpty)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppDurations.fast,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(math.sin(value * 4 * math.pi) * 5, 0),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Login button - Purple gradient style
          AnimatedButton(
            text: 'Sign In',
            onPressed: loading ? null : _login,
            isLoading: loading,
            width: double.infinity,
            height: 56,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],  // Purple to Pink
            ),
            textColor: Colors.white,
            borderRadius: 28,
            icon: Icons.arrow_forward_rounded,
            iconAfter: true,
          ),

          // Forgot Password
          const SizedBox(height: 16),
          TextButton(
            onPressed: _showForgotPasswordDialog,
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    bool sendingReset = false;
    String? resetError;
    bool resetSuccess = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF3D3557).withOpacity(0.5)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Text(
                'Reset Password',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!resetSuccess) ...[
                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFF9D4EDD),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'your@email.com',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.6), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                  ),
                ),
                if (resetError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(resetError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Success state
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF22C55E), size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Email Sent!',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check your inbox for a password reset link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!resetSuccess) ...[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: sendingReset ? null : () async {
                    final email = resetEmailController.text.trim();
                    if (email.isEmpty) {
                      setDialogState(() => resetError = 'Please enter your email address');
                      return;
                    }
                    if (!email.contains('@')) {
                      setDialogState(() => resetError = 'Please enter a valid email address');
                      return;
                    }

                    setDialogState(() { sendingReset = true; resetError = null; });

                    try {
                      await AuthService.resetPassword(email);
                      setDialogState(() { resetSuccess = true; sendingReset = false; });
                    } catch (e) {
                      setDialogState(() {
                        sendingReset = false;
                        resetError = e.toString().replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: sendingReset
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      validator: validator,
      enableInteractiveSelection: true,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      focusNode: _passwordFocus,
      obscureText: obscurePassword,
      validator: Validators.password,
      enableInteractiveSelection: true,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => obscurePassword = !obscurePassword),
          icon: Icon(
            obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/register'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            children: const [
              TextSpan(text: "Don't have an account? "),
              TextSpan(
                text: "Sign up",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccounts() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      blur: 15,
      backgroundColor: const Color(0xFF1E1B2E).withOpacity(0.8),  // Dark purple
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D4EDD).withOpacity(0.3),  // Purple accent
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Demo Accounts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDemoAccountRow('👨‍🎓', 'Student', 'student@example.com'),
          _buildDemoAccountRow('👔', 'President', 'president@example.com'),
          _buildDemoAccountRow('⚙️', 'Admin', 'admin@example.com'),
          const SizedBox(height: 8),
          Text(
            'Password: any',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccountRow(String emoji, String role, String email) {
    return GestureDetector(
      onTap: () {
        emailController.text = email;
        passwordController.text = 'demo';
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text(
              '$role:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
