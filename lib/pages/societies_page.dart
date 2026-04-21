// lib/pages/societies_page.dart
// Societies List with Dark Purple Theme

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/society_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/haptic_feedback.dart';
import 'society_detail_page.dart';
import 'society_management_page.dart';

class SocietiesPage extends ConsumerStatefulWidget {
  const SocietiesPage({super.key});

  @override
  ConsumerState<SocietiesPage> createState() => _SocietiesPageState();
}

class _SocietiesPageState extends ConsumerState<SocietiesPage> with TickerProviderStateMixin {
  List<Society> _societies = [];
  List<Society> _mySocieties = [];
  bool _loading = true;
  User? _currentUser;

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _currentUser = ref.read(currentUserProvider);
    _loadSocieties();

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

  Future<void> _loadSocieties() async {
    setState(() => _loading = true);
    try {
      final all = await SocietyService.getAllSocieties();
      List<Society> my = [];

      if (_currentUser != null) {
        if (_currentUser!.role == UserRole.president) {
          my = await SocietyService.getSocietiesByPresident(_currentUser!.id);
        } else if (_currentUser!.role == UserRole.student) {
          my = await SocietyService.getUserSocieties(_currentUser!.id);
        }
      }

      setState(() { _societies = all; _mySocieties = my; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRole.admin || _currentUser?.role == UserRole.superAdmin;
    final isPresident = _currentUser?.role == UserRole.president || _currentUser?.role == UserRole.vicePresident;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      floatingActionButton: isAdmin ? _buildFab() : null,
      body: Stack(
        children: [
          _buildParticleBackground(),
          _buildBackgroundGlows(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeController,
              child: Column(
                children: [
                  _buildAppBar(isAdmin),
                  Expanded(
                    child: _loading
                        ? _buildLoadingState()
                        : RefreshIndicator(
                            onRefresh: _loadSocieties,
                            color: const Color(0xFF9D4EDD),
                            child: _buildContent(isPresident),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () async {
        HapticUtils.mediumImpact();
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SocietyManagementPage()));
        _loadSocieties();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('New Society', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
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

  Widget _buildAppBar(bool isAdmin) {
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
          const Expanded(child: Text('Societies', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
          if (isAdmin)
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SocietyManagementPage()));
                _loadSocieties();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2D2645), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.settings, size: 20, color: Color(0xFFB8A9C9)),
              ),
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

  Widget _buildContent(bool isPresident) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Societies section
          if ((isPresident || _currentUser?.role == UserRole.student) && _mySocieties.isNotEmpty) ...[
            Text(isPresident ? 'My Societies (President)' : 'My Societies', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 14),
            ..._mySocieties.map((s) => _buildSocietyCard(s, highlight: true)),
            const SizedBox(height: 28),
          ],

          // All Societies
          const Text('All Societies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 14),

          if (_societies.isEmpty)
            _buildEmptyState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.85),
              itemCount: _societies.length,
              itemBuilder: (context, idx) => _buildGridCard(_societies[idx]),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isAdmin = _currentUser?.role == UserRole.admin || _currentUser?.role == UserRole.superAdmin;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF9D4EDD).withOpacity(0.2), const Color(0xFFE040FB).withOpacity(0.1)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_outlined, size: 52, color: Color(0xFF9D4EDD)),
          ),
          const SizedBox(height: 20),
          const Text('No Societies Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            isAdmin ? 'Click the button below to create your first society!' : 'Check back soon for available societies.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB8A9C9)),
          ),
        ],
      ),
    );
  }

  Widget _buildSocietyCard(Society society, {bool highlight = false}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SocietyDetailPage(societyId: society.id)));
        _loadSocieties();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(18),
          border: highlight ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(society.name[0], style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(society.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${society.memberCount} members', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(Society society) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SocietyDetailPage(societyId: society.id)));
        _loadSocieties();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            Positioned(right: -15, top: -15, child: Icon(Icons.group, size: 90, color: const Color(0xFF9D4EDD).withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(society.name[0].toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(society.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: Color(0xFFB8A9C9)),
                          const SizedBox(width: 4),
                          Text('${society.memberCount} members', style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                        ],
                      ),
                    ],
                  ),
                ],
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
