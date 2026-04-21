// lib/pages/notification_settings_page.dart
// Notification preferences with Dark Purple Theme

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> with TickerProviderStateMixin {
  late NotificationSettings _settings;
  bool _isSaving = false;

  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();
    _settings = SettingsService.notificationSettings;

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
    _particleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.updateNotificationSettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Settings saved!')]),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
    setState(() => _isSaving = false);
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
          top: -50,
          right: -50,
          child: Transform.scale(
            scale: pulseValue,
            child: Container(width: 180, height: 180, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF9D4EDD).withOpacity(0.2), const Color(0xFF9D4EDD).withOpacity(0.0)]))),
          ),
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
          const Expanded(child: Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white))),
          GestureDetector(
            onTap: _isSaving ? null : _saveSettings,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Info banner
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
              Expanded(child: Text('Manage what notifications you receive.', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13))),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionTitle('Push Notifications'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSwitchTile('New Events', 'Get notified when new events are created', Icons.celebration, _settings.newEvents, (v) => setState(() => _settings = _settings.copyWith(newEvents: v))),
          _divider(),
          _buildSwitchTile('Event Reminders', 'Get notified before events start', Icons.event, _settings.eventReminders, (v) => setState(() => _settings = _settings.copyWith(eventReminders: v))),
          _divider(),
          _buildSwitchTile('New Announcements', 'Stay updated with latest news', Icons.campaign, _settings.newAnnouncements, (v) => setState(() => _settings = _settings.copyWith(newAnnouncements: v))),
          _divider(),
          _buildSwitchTile('Poll Notifications', 'Get notified about new polls', Icons.poll, _settings.pollNotifications, (v) => setState(() => _settings = _settings.copyWith(pollNotifications: v))),
          _divider(),
          _buildSwitchTile('Chat Messages', 'Receive chatbot responses', Icons.chat, _settings.chatMessages, (v) => setState(() => _settings = _settings.copyWith(chatMessages: v))),
        ]),
        const SizedBox(height: 24),

        _buildSectionTitle('Email Notifications'),
        const SizedBox(height: 12),
        _buildSettingsCard([
          _buildSwitchTile('Email Notifications', 'Receive updates via email', Icons.email, _settings.emailNotifications, (v) => setState(() => _settings = _settings.copyWith(emailNotifications: v))),
        ]),
      ],
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0xFF3D3557).withOpacity(0.5));

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB8A9C9), letterSpacing: 0.5));
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF9D4EDD)),
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
