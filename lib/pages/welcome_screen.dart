// lib/pages/welcome_screen.dart
// Premium Welcome Screen - MarryMint Style with Particle Effects

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;

  // Particles data
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Initialize particles
    _initParticles();

    // Floating animation for event cards
    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Pulse animation for glow effects
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController.forward();
  }

  void _initParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.2 + _random.nextDouble() * 0.5,
        opacity: 0.2 + _random.nextDouble() * 0.5,
        angle: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
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
              Color(0xFF1A0F2E),  // Dark purple top
              Color(0xFF0D0B14),  // Deep purple-black
              Color(0xFF0D0B14),  // Deep purple-black bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Floating particles
            _buildParticles(size),

            // Background glow effects with pulse
            _buildBackgroundGlows(),

            // Floating event cards
            _buildFloatingCards(size),

            // Sparkle effects
            _buildSparkles(size),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // App branding
                    _buildBranding(),

                    const SizedBox(height: 16),

                    // Tagline
                    _buildTagline(),

                    const Spacer(flex: 1),

                    // Action buttons
                    _buildActionButtons(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: ParticlePainter(
            particles: _particles,
            animationValue: _particleController.value,
          ),
        );
      },
    );
  }

  Widget _buildSparkles(Size size) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            final offset = (_particleController.value + index * 0.125) % 1.0;
            final x = (index % 4) * (size.width / 4) + 30;
            final y = (index ~/ 4) * (size.height / 3) + 100;
            final opacity = (0.3 + 0.4 * math.sin(offset * 2 * math.pi)).clamp(0.0, 1.0);

            return Positioned(
              left: x + math.sin(offset * 2 * math.pi) * 20,
              top: y + math.cos(offset * 2 * math.pi) * 15,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  Icons.star,
                  size: 8 + (index % 3) * 4,
                  color: index % 2 == 0
                    ? const Color(0xFF9D4EDD)
                    : const Color(0xFFE040FB),
                ),
              ),
            );
          }),
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
            // Top-left purple glow
            Positioned(
              top: -100,
              left: -100,
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9D4EDD).withOpacity(0.35),
                        const Color(0xFF9D4EDD).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-right magenta glow
            Positioned(
              bottom: -50,
              right: -50,
              child: Transform.scale(
                scale: 1.2 - (_pulseController.value * 0.2),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE040FB).withOpacity(0.25),
                        const Color(0xFFE040FB).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Center purple glow
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7B2CBF).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingCards(Size size) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatValue = math.sin(_floatController.value * math.pi) * 12;
        final rotateValue = math.sin(_floatController.value * math.pi) * 0.02;

        return Stack(
          children: [
            // Left floating card
            Positioned(
              top: 80 + floatValue,
              left: 20,
              child: Transform.rotate(
                angle: -0.1 + rotateValue,
                child: _buildEventCard(
                  'Rooftop Paint Night',
                  'Friday, August 9',
                  '2,000+ Like This Event',
                  const Color(0xFF1E1B2E),
                  Icons.palette,
                ),
              ),
            ),
            // Right floating card
            Positioned(
              top: 140 - floatValue,
              right: 20,
              child: Transform.rotate(
                angle: 0.08 - rotateValue,
                child: _buildEventCard(
                  'Indie Music Meetup',
                  'Brooklyn, New York',
                  '2,000+ Like This Event',
                  const Color(0xFF1E1B2E),
                  Icons.music_note,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(String title, String subtitle, String likes, Color bgColor, IconData icon) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3D3557).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D4EDD).withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event image placeholder with icon
          Container(
            height: 85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 10,
                color: Color(0xFFB8A9C9),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB8A9C9),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.favorite,
                size: 12,
                color: Color(0xFFEC4899),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  likes,
                  style: const TextStyle(
                    color: Color(0xFFB8A9C9),
                    fontSize: 8,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity = 0.5 + _pulseController.value * 0.3;

        return Column(
          children: [
            // Script-style app name with animated gradient glow
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE040FB), Colors.white, Color(0xFF9D4EDD)],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                'EventSphere',
                style: GoogleFonts.pacifico(
                  fontSize: 52,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(157, 78, 221, glowIntensity),
                      blurRadius: 35,
                    ),
                    Shadow(
                      color: Color.fromRGBO(224, 64, 251, glowIntensity * 0.5),
                      blurRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTagline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'Discover spontaneous, local experiences and\nconnect in real life with people who match your energy.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
          height: 1.6,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Login button - Ghost style with hover effect
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFB8A9C9).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFFB8A9C9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Register button - Gradient style with glow
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/register'),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9D4EDD).withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle model
class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double angle;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

// Particle painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate animated position
      final progress = (animationValue + particle.angle / (2 * math.pi)) % 1.0;
      final x = particle.x * size.width +
                math.sin(progress * 2 * math.pi) * 30 * particle.speed;
      final y = (particle.y * size.height - progress * size.height * 0.5) % size.height;

      // Fade based on position
      final opacity = particle.opacity * (1 - (y / size.height) * 0.5);

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF9D4EDD),
          const Color(0xFFE040FB),
          particle.x,
        )!.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // Add glow effect
      final glowOpacity = (opacity * 0.3).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = const Color(0xFF9D4EDD).withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), particle.size * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
