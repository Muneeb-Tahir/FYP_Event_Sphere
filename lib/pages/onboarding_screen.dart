import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../constants/app_theme.dart';
import '../widgets/animated_button.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _backgroundController;

  final List<OnboardingData> onboardingData = [
    OnboardingData(
      title: 'Discover Events',
      subtitle: 'Find the perfect event that matches your interests and availability',
      icon: Icons.explore_rounded,
      gradient: AppGradients.primary,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Manage Easily',
      subtitle: 'Book tickets, manage your schedule, and get event updates all in one place',
      icon: Icons.dashboard_customize_rounded,
      gradient: AppGradients.secondary,
      color: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Connect & Share',
      subtitle: 'Join communities, invite friends, and share your favorite events',
      icon: Icons.people_alt_rounded,
      gradient: AppGradients.accent,
      color: AppColors.accent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        onboardingData[_currentPage].color.withOpacity(0.1),
                        const Color(0xFF0D0B14),
                        0.5,
                      )!,
                      const Color(0xFF0D0B14),
                    ],
                  ),
                ),
              );
            },
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (_, index) => _buildOnboardingPage(onboardingData[index]),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D0B14).withOpacity(0),
                    const Color(0xFF0D0B14),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: onboardingData.length,
                    effect: ExpandingDotsEffect(
                      dotColor: AppColors.border,
                      activeDotColor: onboardingData[_currentPage].color,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 10,
                      expansionFactor: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: _currentPage < onboardingData.length - 1
                ? GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFFB8A9C9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Icon container with gradient
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: AppDurations.slow,
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: data.gradient,
                boxShadow: [
                  BoxShadow(
                    color: data.color.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFB8A9C9),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isLastPage = _currentPage == onboardingData.length - 1;

    return Row(
      children: [
        // Back button
        if (_currentPage > 0)
          Expanded(
            child: AnimatedButton(
              text: 'Back',
              isOutlined: true,
              backgroundColor: const Color(0xFFB8A9C9),
              height: 54,
              borderRadius: 16,
              onPressed: () {
                _pageController.previousPage(
                  duration: AppDurations.normal,
                  curve: Curves.easeInOut,
                );
              },
            ),
          )
        else
          const Spacer(),

        if (_currentPage > 0) const SizedBox(width: 16),

        // Next/Get Started button
        Expanded(
          flex: 2,
          child: AnimatedButton(
            text: isLastPage ? 'Get Started' : 'Continue',
            gradient: onboardingData[_currentPage].gradient,
            height: 54,
            borderRadius: 16,
            icon: isLastPage ? Icons.arrow_forward_rounded : null,
            iconAfter: true,
            onPressed: () {
              if (isLastPage) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const WelcomeScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: AppDurations.slow,
                  ),
                );
              } else {
                _pageController.nextPage(
                  duration: AppDurations.normal,
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.color,
  });
}
