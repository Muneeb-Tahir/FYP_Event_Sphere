// lib/pages/faq_page.dart
// FAQ/Help & Support page with Dark Purple Theme

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class FaqPageRedesigned extends StatefulWidget {
  const FaqPageRedesigned({super.key});

  @override
  State<FaqPageRedesigned> createState() => _FaqPageRedesignedState();
}

class _FaqPageRedesignedState extends State<FaqPageRedesigned> with TickerProviderStateMixin {
  final List<Map<String, String>> faqs = [
    {'q': 'How do I register for an event?', 'a': 'Navigate to the Events page, browse through available events, select one that interests you, and tap the "Register Now" button on the event details page.'},
    {'q': 'Can I unregister from an event?', 'a': 'Yes! You can visit the event details anytime and click the "Unregister from Event" button to remove your registration.'},
    {'q': 'How do I create an event?', 'a': 'Click the "Create Event" button on the Events page, fill in all required event details, and submit for approval. Admins will review and approve your event.'},
    {'q': 'What is the attendance marking system?', 'a': 'We use QR code scanning for attendance marking. Arrive at the event and let organizers scan your QR code to mark you as present.'},
    {'q': 'How do I bookmark events?', 'a': 'You can bookmark events by tapping the bookmark icon on any event card. Your bookmarks are saved in the Bookmarks section for easy access.'},
    {'q': 'How do societies work?', 'a': 'Societies are community groups that organize events and activities. You can join societies of interest and stay updated with their events.'},
  ];

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  void _initParticles() {
    for (int i = 0; i < 8; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 2,
        speed: 0.2 + _random.nextDouble() * 0.3,
        opacity: 0.15 + _random.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
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
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlePainter(particles: _particles, animationValue: _particleController.value),
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
            Positioned(
              top: -50,
              right: -50,
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF9D4EDD).withOpacity(0.2), const Color(0xFF9D4EDD).withOpacity(0.0)],
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
          const Text('Help & Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Contact section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.support_agent, size: 52, color: Colors.white),
              const SizedBox(height: 14),
              const Text('Need Help?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Contact us at support@eventsphere.com', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // FAQ Header
        const Row(children: [
          Icon(Icons.quiz_outlined, color: Color(0xFF9D4EDD), size: 22),
          SizedBox(width: 10),
          Text('Frequently Asked Questions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
        const SizedBox(height: 18),

        // FAQ items
        ...faqs.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              backgroundColor: const Color(0xFF1E1B2E),
              collapsedBackgroundColor: const Color(0xFF1E1B2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: const Color(0xFF3D3557).withOpacity(0.5))),
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: const Color(0xFF3D3557).withOpacity(0.5))),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.help_outline, color: Color(0xFF9D4EDD), size: 20),
              ),
              title: Text(entry.value['q']!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
              iconColor: const Color(0xFFB8A9C9),
              collapsedIconColor: const Color(0xFFB8A9C9),
              children: [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(entry.value['a']!, style: const TextStyle(color: Color(0xFFB8A9C9), height: 1.6, fontSize: 13)),
                ),
              ],
            ),
          ),
        )),

        const SizedBox(height: 24),

        // App info
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          ),
          child: const Column(children: [
            Icon(Icons.info_outline, color: Color(0xFFB8A9C9), size: 32),
            SizedBox(height: 12),
            Text('Event Sphere', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 4),
            Text('Version 1.0.0', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 13)),
          ]),
        ),
      ],
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
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFF9D4EDD), const Color(0xFFE040FB), p.x)!.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.animationValue != animationValue;
}
