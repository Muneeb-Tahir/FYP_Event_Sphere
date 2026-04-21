// lib/pages/privacy_settings_page.dart
// Privacy settings screen with dark theme support

import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/settings_service.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  late PrivacySettings _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = SettingsService.privacySettings;
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await SettingsService.updatePrivacySettings(_settings);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Privacy settings saved!')]),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF3D3557), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveSettings,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD)))
                : const Text('Save', style: TextStyle(color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.info.withOpacity(isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.info.withOpacity(0.3))),
            child: const Row(children: [Icon(Icons.shield_outlined, color: AppColors.info), SizedBox(width: 12), Expanded(child: Text('Control who can see your information.', style: TextStyle(color: AppColors.info, fontSize: 13)))]),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Profile Visibility', isDark),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile('Public Profile', 'Allow others to view your profile', Icons.visibility, _settings.profileVisible, (v) => setState(() => _settings = _settings.copyWith(profileVisible: v)), isDark),
            Divider(height: 1, color: isDark ? DarkColors.border : null),
            _buildSwitchTile('Show Email', 'Display email on your profile', Icons.email, _settings.showEmail, (v) => setState(() => _settings = _settings.copyWith(showEmail: v)), isDark),
            Divider(height: 1, color: isDark ? DarkColors.border : null),
            _buildSwitchTile('Show Phone', 'Display phone number on profile', Icons.phone, _settings.showPhone, (v) => setState(() => _settings = _settings.copyWith(showPhone: v)), isDark),
            Divider(height: 1, color: isDark ? DarkColors.border : null),
            _buildSwitchTile('Show Societies', 'Display your society memberships', Icons.groups, _settings.showSocieties, (v) => setState(() => _settings = _settings.copyWith(showSocieties: v)), isDark),
          ], isDark),
          const SizedBox(height: 24),

          _buildSectionTitle('Communication', isDark),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildSwitchTile('Allow Direct Messages', 'Let others send you messages', Icons.message, _settings.allowDirectMessages, (v) => setState(() => _settings = _settings.copyWith(allowDirectMessages: v)), isDark),
          ], isDark),
          const SizedBox(height: 24),

          _buildSectionTitle('Your Data', isDark),
          const SizedBox(height: 12),
          _buildSettingsCard([
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.download, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Download My Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
              subtitle: const Text('Get a copy of your data', style: TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFB8A9C9)),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export will be available soon!'), behavior: SnackBarBehavior.floating)),
            ),
          ], isDark),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB8A9C9), letterSpacing: 0.5));
  }

  Widget _buildSettingsCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1B2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5))),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF9D4EDD), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF9D4EDD)),
    );
  }
}
