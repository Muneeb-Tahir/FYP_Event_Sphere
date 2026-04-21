// lib/widgets/dark_theme_wrapper.dart
// Reusable dark purple theme wrapper with particles and glow effects

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A wrapper widget that applies the MarryMint dark purple theme
/// with floating particles and pulsing glow effects to any screen.
class DarkThemeWrapper extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool showGlows;
  final bool enableScrolling;
  final Color? backgroundColor;

  const DarkThemeWrapper({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showGlows = true,
    this.enableScrolling = false,
    this.backgroundColor,
  });

  @override
  State<DarkThemeWrapper> createState() => _DarkThemeWrapperState();
}

class _DarkThemeWrapperState extends State<DarkThemeWrapper>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    if (widget.showParticles) {
      _initParticles();
    }

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    if (widget.showParticles) {
      _particleController.repeat();
    }

    if (widget.showGlows) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _initParticles() {
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 3,
        speed: 0.2 + _random.nextDouble() * 0.4,
        opacity: 0.15 + _random.nextDouble() * 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.backgroundColor ?? const Color(0xFF1A0F2E),
            const Color(0xFF0D0B14),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Particle background
          if (widget.showParticles)
            _buildParticleBackground(),

          // Glow effects
          if (widget.showGlows)
            _buildBackgroundGlows(),

          // Main content
          widget.child,
        ],
      ),
    );
  }

  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildBackgroundGlows() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.8 + _pulseController.value * 0.4;
        return Stack(
          children: [
            // Top-right purple glow
            Positioned(
              top: -80,
              right: -80,
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9D4EDD).withOpacity(0.2),
                        const Color(0xFF9D4EDD).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-left magenta glow
            Positioned(
              bottom: -60,
              left: -60,
              child: Transform.scale(
                scale: 1.2 - (_pulseController.value * 0.2),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE040FB).withOpacity(0.15),
                        const Color(0xFFE040FB).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Simple particle model
class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Particle painter
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final progress = (animationValue + particle.y) % 1.0;
      final x = particle.x * size.width +
                math.sin(progress * 2 * math.pi) * 15 * particle.speed;
      final y = (1 - progress) * size.height;

      final opacity = (particle.opacity * (1 - progress * 0.5)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF9D4EDD),
          const Color(0xFFE040FB),
          particle.x,
        )!.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // Soft glow
      final glowPaint = Paint()
        ..color = const Color(0xFF9D4EDD).withOpacity((opacity * 0.25).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(Offset(x, y), particle.size * 1.3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Dark themed app bar with glassmorphism effect
class DarkThemeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const DarkThemeAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E).withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF3D3557).withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2645),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          if (showBackButton) const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Dark themed card with glassmorphism
class DarkThemeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const DarkThemeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: const Color(0xFF3D3557).withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Dark themed button with gradient
class DarkThemeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const DarkThemeButton({
    super.key,
    required this.text,
    this.onTap,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: isOutlined ? null : const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
          color: isOutlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(26),
          border: isOutlined ? Border.all(
            color: const Color(0xFFB8A9C9).withOpacity(0.5),
            width: 1.5,
          ) : null,
          boxShadow: isOutlined ? null : [
            BoxShadow(
              color: const Color(0xFF9D4EDD).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: isOutlined ? const Color(0xFFB8A9C9) : Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: isOutlined ? const Color(0xFFB8A9C9) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

/// Dark theme text field
class DarkThemeTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const DarkThemeTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF9D4EDD),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.8),
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2E).withOpacity(0.8),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFFB8A9C9), size: 20) : null,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D3557)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D3557)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEC4899)),
        ),
      ),
    );
  }
}
