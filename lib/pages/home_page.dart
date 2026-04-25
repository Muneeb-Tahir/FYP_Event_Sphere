import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/custom_bottom_nav.dart';
import 'my_events_page.dart';
import 'user_management_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late List<Animation<double>> _itemAnimations;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _itemAnimations = List.generate(8, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(index * 0.1, 0.6 + index * 0.05, curve: Curves.easeOutCubic),
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _staggerController.forward();
    });
  }

  void _initParticles() {
    for (int i = 0; i < 15; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 3,
        speed: 0.15 + _random.nextDouble() * 0.25,
        opacity: 0.1 + _random.nextDouble() * 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onNavigationItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() { _selectedIndex = index; });

    switch (index) {
      case 0: break;
      case 1: Navigator.pushNamed(context, '/events').then((_) { if (mounted) setState(() => _selectedIndex = 0); }); break;
      case 2: Navigator.pushNamed(context, '/societies').then((_) { if (mounted) setState(() => _selectedIndex = 0); }); break;
      case 3: Navigator.pushNamed(context, '/profile').then((_) { if (mounted) setState(() => _selectedIndex = 0); }); break;
    }
  }

  void _logout() async {
    // Use Riverpod provider to sign out
    await ref.read(authProvider.notifier).signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    // Use Riverpod provider instead of static AuthService
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      extendBody: true,
      body: Stack(
        children: [
          // Animated particle background
          _buildParticleBackground(),
          // Pulsing background glows
          _buildBackgroundGlows(),
          // Main content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(currentUser),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedItem(0, _buildRoleCard(currentUser)),
                      const SizedBox(height: 28),
                      _buildAnimatedItem(1, _buildQuickActionsHeader(currentUser)),
                      const SizedBox(height: 16),
                      _buildQuickActionsGrid(currentUser),
                      const SizedBox(height: 28),
                      const Text('Explore', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                      const SizedBox(height: 14),
                      _buildMenuOptions(currentUser),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavigationItemTapped,
        items: const [
          NavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
          NavBarItem(icon: Icons.event_outlined, activeIcon: Icons.event_rounded, label: 'Events'),
          NavBarItem(icon: Icons.group_outlined, activeIcon: Icons.group_rounded, label: 'Groups'),
          NavBarItem(icon: Icons.person_outlined, activeIcon: Icons.person_rounded, label: 'Profile'),
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
              top: -80,
              right: -80,
              child: Transform.scale(
                scale: pulseValue,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF9D4EDD).withOpacity(0.25), const Color(0xFF9D4EDD).withOpacity(0.0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: -60,
              child: Transform.scale(
                scale: 1.2 - (_pulseController.value * 0.2),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFFE040FB).withOpacity(0.18), const Color(0xFFE040FB).withOpacity(0.0)],
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

  Widget _buildHeader(User? currentUser) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D0B14),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1625), Color(0xFF0D0B14)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF9D4EDD).withOpacity(0.15)))),
              Positioned(bottom: -30, left: -30, child: Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE040FB).withOpacity(0.1)))),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FadeTransition(
                        opacity: _fadeController,
                        child: Row(
                          children: [
                            // Avatar - now shows profile image
                            _buildUserAvatar(currentUser, size: 56),
                            const SizedBox(width: 16),
                            // Greeting
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_getGreeting(), style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w400)),
                                  const SizedBox(height: 4),
                                  Text(currentUser?.name ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
                                ],
                              ),
                            ),
                            // Search button
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/search'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2645),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF3D3557)),
                                ),
                                child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Logout button
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2645),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF3D3557)),
                                ),
                                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable profile avatar widget that shows actual image or falls back to letter
  Widget _buildUserAvatar(User? user, {double size = 56, bool isCircular = true}) {
    final profileUrl = user?.profileImageUrl;

    // If we have an actual image URL
    if (profileUrl != null && profileUrl.startsWith('http')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCircular ? size : 14),
          child: CachedNetworkImage(
            imageUrl: profileUrl,
            width: size - 4,
            height: size - 4,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFF1E1B2E),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD))),
            ),
            errorWidget: (context, url, error) => _buildLetterAvatar(user, size: size - 4, isCircular: isCircular),
          ),
        ),
      );
    }

    // Fallback to letter avatar
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
        boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(14),
          color: const Color(0xFF1E1B2E),
        ),
        child: Center(child: Text((user?.name ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: const Color(0xFF9D4EDD)))),
      ),
    );
  }

  Widget _buildLetterAvatar(User? user, {double size = 52, bool isCircular = true}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(14),
        color: const Color(0xFF1E1B2E),
      ),
      child: Center(child: Text((user?.name ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: const Color(0xFF9D4EDD)))),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    if (index >= _itemAnimations.length) return child;
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
          child: Opacity(opacity: _itemAnimations[index].value, child: child),
        );
      },
    );
  }

  Widget _buildRoleCard(User? user) {
    return GestureDetector(
      onTap: () {
        if (user?.role.toString().contains('admin') == true) {
          Navigator.pushNamed(context, '/admin-dashboard');
        } else {
          Navigator.pushNamed(context, '/profile');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            // Profile image with rounded square shape
            _buildUserAvatar(user, size: 56, isCircular: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'Welcome!', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(user?.role.toString().split('.').last.toUpperCase() ?? 'USER', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF2D2645), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB8A9C9), size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsHeader(User? currentUser) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.3)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [const Color(0xFF9D4EDD).withOpacity(0.3), const Color(0xFFEC4899).withOpacity(0.2)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(currentUser?.role.toString().split('.').last ?? 'User', style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(User? currentUser) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.15,
      children: [
        _buildAnimatedItem(2, _buildQuickActionCard('Events', Icons.event_rounded, const [Color(0xFF8B5CF6), Color(0xFF6366F1)], '/events')),
        _buildAnimatedItem(3, _buildQuickActionCard('My Registrations', Icons.check_circle_rounded, const [Color(0xFF22C55E), Color(0xFF10B981)], '/registered-events')),
        if (currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)
          _buildAnimatedItem(4, _buildQuickActionCardWithNav('My Events', Icons.event_note_rounded, const [Color(0xFFEC4899), Color(0xFFF43F5E)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyEventsPage())))),
        if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin)
          _buildAnimatedItem(4, _buildQuickActionCard('Approvals', Icons.admin_panel_settings_rounded, const [Color(0xFFF59E0B), Color(0xFFEF4444)], '/event-approval')),
        if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin)
          _buildAnimatedItem(5, _buildQuickActionCardWithNav('Users', Icons.people_rounded, const [Color(0xFF9D4EDD), Color(0xFFE040FB)], () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage())))),
        _buildAnimatedItem(5, _buildQuickActionCard('Societies', Icons.group_rounded, const [Color(0xFF06B6D4), Color(0xFF0891B2)], '/societies')),
        if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin)
          _buildAnimatedItem(6, _buildQuickActionCard('Dashboard', Icons.dashboard_rounded, const [Color(0xFFEC4899), Color(0xFFBE185D)], '/admin-dashboard')),
        _buildAnimatedItem(7, _buildQuickActionCard('Bookmarks', Icons.bookmark_rounded, const [Color(0xFFF59E0B), Color(0xFFD97706)], '/bookmarks')),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, List<Color> colors, String route) {
    return Semantics(
      button: true,
      label: '$title. Double tap to open',
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 26)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Row(children: [Text('Open', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.8), size: 14)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCardWithNav(String title, IconData icon, List<Color> colors, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: '$title. Double tap to open',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 26)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, letterSpacing: -0.2)),
              const SizedBox(height: 4),
              Row(children: [Text('Open', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.8), size: 14)]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOptions(User? currentUser) {
    return Column(
      children: [
        if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)
          _buildMenuOption('Expenses', 'Track and manage spending', Icons.account_balance_wallet_rounded, const Color(0xFF22C55E), '/expenses'),
        _buildMenuOption('FAQ', 'Find answers to common questions', Icons.help_rounded, const Color(0xFF3B82F6), '/faq'),
        if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)
          _buildMenuOption('QR Scanner', 'Scan event QR codes', Icons.qr_code_scanner_rounded, const Color(0xFF06B6D4), '/qr-scan'),
        _buildMenuOption('Chatbot', 'Get instant help', Icons.smart_toy_rounded, const Color(0xFFEC4899), '/chatbot'),
      ],
    );
  }

  Widget _buildMenuOption(String title, String subtitle, IconData icon, Color color, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.15)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF2D2645), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB8A9C9), size: 14),
                ),
              ],
            ),
          ),
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
      final x = p.x * size.width + math.sin(progress * 2 * math.pi) * 20 * p.speed;
      final y = (1 - progress) * size.height;
      final opacity = (p.opacity * (1 - progress * 0.5)).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), p.size, Paint()..color = Color.lerp(const Color(0xFF9D4EDD), const Color(0xFFE040FB), p.x)!.withOpacity(opacity));
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.animationValue != animationValue;
}
