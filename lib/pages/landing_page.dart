// lib/pages/landing_page.dart
// Promotional landing page for web - "Coming Soon" style

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0D0D1A),
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                  ]
                : [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                    Colors.white,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            ..._buildBackgroundElements(isDark),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: size.height),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? size.width * 0.15 : 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo and branding
                          _buildLogo(isDark),
                          const SizedBox(height: 40),

                          // Main headline
                          _buildHeadline(isDark, isWide),
                          const SizedBox(height: 20),

                          // Subheadline
                          _buildSubheadline(isDark, isWide),
                          const SizedBox(height: 50),

                          // Coming Soon Badge
                          _buildComingSoonBadge(),
                          const SizedBox(height: 50),

                          // Features preview
                          _buildFeaturesPreview(isDark, isWide),
                          const SizedBox(height: 50),

                          // CTA Buttons
                          _buildCTASection(isDark, isWide),
                          const SizedBox(height: 60),

                          // Footer
                          _buildFooter(isDark),
                        ],
                      ),
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

  List<Widget> _buildBackgroundElements(bool isDark) {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: -150,
        left: -150,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value * 0.9,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.2),
                      AppColors.secondary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildLogo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.95 + 0.05,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.event_available_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeadline(bool isDark, bool isWide) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(bounds),
      child: Text(
        'Event Sphere',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isWide ? 64 : 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildSubheadline(bool isDark, bool isWide) {
    return Text(
      'Your Ultimate Campus Event Management Platform',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isWide ? 24 : 18,
        color: isDark ? DarkColors.textSecondary : AppColors.textSecondary,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
    );
  }

  Widget _buildComingSoonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent,
            AppColors.accent.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'STILL IN PRODUCTION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesPreview(bool isDark, bool isWide) {
    final features = [
      {'icon': Icons.event_rounded, 'title': 'Event Management', 'desc': 'Create & manage events'},
      {'icon': Icons.qr_code_scanner_rounded, 'title': 'QR Check-in', 'desc': 'Seamless attendance'},
      {'icon': Icons.analytics_rounded, 'title': 'Analytics', 'desc': 'Track performance'},
      {'icon': Icons.notifications_rounded, 'title': 'Notifications', 'desc': 'Stay updated'},
    ];

    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: features.map((feature) {
        return Container(
          width: isWide ? 200 : 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? DarkColors.border : AppColors.border,
            ),
            boxShadow: isDark ? null : AppShadows.medium,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                feature['title'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? DarkColors.textPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature['desc'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? DarkColors.textSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCTASection(bool isDark, bool isWide) {
    return Column(
      children: [
        Text(
          'Check Out Our App',
          style: TextStyle(
            fontSize: isWide ? 28 : 22,
            fontWeight: FontWeight.bold,
            color: isDark ? DarkColors.textPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Experience the future of campus event management',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? DarkColors.textSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            // Launch App Button
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Launch App',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Learn More Button
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('📧 Contact: team@eventsphere.app'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: isDark ? DarkColors.surface : AppColors.primary,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? DarkColors.textPrimary : AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                side: BorderSide(
                  color: isDark ? DarkColors.border : AppColors.primary,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Contact Us',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Divider(
          color: isDark ? DarkColors.border : AppColors.border,
          height: 1,
        ),
        const SizedBox(height: 24),
        Text(
          '© 2024 Event Sphere. All rights reserved.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? DarkColors.textTertiary : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Made with ❤️ for Campus Communities',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? DarkColors.textTertiary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
