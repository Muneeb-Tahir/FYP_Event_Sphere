// lib/pages/attended_events_page.dart
// Attended Events with Dark Purple Theme

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_stats_service.dart';
import '../services/event_service.dart';
import '../providers/auth_provider.dart';
import '../models/event.dart';

class AttendedEventsPage extends ConsumerStatefulWidget {
  const AttendedEventsPage({super.key});

  @override
  ConsumerState<AttendedEventsPage> createState() => _AttendedEventsPageState();
}

class _AttendedEventsPageState extends ConsumerState<AttendedEventsPage> with TickerProviderStateMixin {
  List<Event> _attendedEvents = [];
  bool _isLoading = true;

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _loadAttendedEvents();

    _particleController = AnimationController(duration: const Duration(seconds: 12), vsync: this)..repeat();
    _pulseController = AnimationController(duration: const Duration(seconds: 3), vsync: this)..repeat(reverse: true);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this)..forward();
  }

  void _initParticles() {
    for (int i = 0; i < 10; i++) {
      _particles.add(_Particle(x: _random.nextDouble(), y: _random.nextDouble(), size: 2 + _random.nextDouble() * 2, speed: 0.2 + _random.nextDouble() * 0.3, opacity: 0.15 + _random.nextDouble() * 0.25));
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendedEvents() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final attendedIds = await UserStatsService.getAttendedEventIds(user.id);
      final allEvents = await EventService.getAllEvents();

      setState(() {
        _attendedEvents = allEvents.where((e) => attendedIds.contains(e.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingState()
                        : _attendedEvents.isEmpty
                            ? _buildEmptyState()
                            : _buildEventsList(),
                  ),
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
        return Stack(
          children: [
            Positioned(top: -60, right: -60, child: Transform.scale(scale: pulseValue, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF9D4EDD).withOpacity(0.2), const Color(0xFF9D4EDD).withOpacity(0.0)]))))),
            Positioned(bottom: 150, left: -50, child: Transform.scale(scale: 1.2 - (_pulseController.value * 0.2), child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFE040FB).withOpacity(0.15), const Color(0xFFE040FB).withOpacity(0.0)]))))),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Attended Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_attendedEvents.length} Events', style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF1E1B2E), borderRadius: BorderRadius.circular(16)),
        child: const CircularProgressIndicator(color: Color(0xFF9D4EDD), strokeWidth: 3),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF22C55E).withOpacity(0.2), const Color(0xFF10B981).withOpacity(0.1)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 56, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 24),
          const Text('No events attended yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Events you attend will appear here', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 14)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/events'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Discover Events', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendedEvents.length,
      itemBuilder: (context, index) => _buildEventCard(_attendedEvents[index]),
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: event.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Attended badge
            Container(
              width: 80,
              height: 105,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 30),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Text('Attended', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(event.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9D4EDD))),
                    ),
                    const SizedBox(height: 10),
                    Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFB8A9C9)),
                        const SizedBox(width: 6),
                        Text(_formatDate(event.date), style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                        const SizedBox(width: 14),
                        const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFB8A9C9)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(event.venue, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
