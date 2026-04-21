// lib/pages/profile/profile_settings_tile.dart
// Settings tile widget for profile page

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// Settings tile for profile page
class ProfileSettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;
  final bool showDivider;

  const ProfileSettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? DarkColors.primary : AppColors.primary);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB8A9C9),
            ),
          ),
          trailing: trailing ??
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFB8A9C9),
              ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            color: isDark ? DarkColors.border : AppTheme.borderColor,
          ),
      ],
    );
  }
}

/// Settings group container
class ProfileSettingsGroup extends StatelessWidget {
  final String? title;
  final List<ProfileSettingsTile> tiles;

  const ProfileSettingsGroup({
    super.key,
    this.title,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? DarkColors.textTertiary : Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? DarkColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: tiles
                .asMap()
                .entries
                .map((entry) => ProfileSettingsTile(
                      key: ValueKey(entry.key),
                      title: entry.value.title,
                      subtitle: entry.value.subtitle,
                      icon: entry.value.icon,
                      onTap: entry.value.onTap,
                      iconColor: entry.value.iconColor,
                      trailing: entry.value.trailing,
                      showDivider: entry.key < tiles.length - 1,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
