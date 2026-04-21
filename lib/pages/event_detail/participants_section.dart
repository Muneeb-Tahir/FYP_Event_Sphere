// lib/pages/event_detail/participants_section.dart
// Participants list section for event detail page

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// Participant data model
class Participant {
  final String id;
  final String name;
  final String? email;
  final String? profileImageUrl;
  final bool isCheckedIn;
  final DateTime registeredAt;

  Participant({
    required this.id,
    required this.name,
    this.email,
    this.profileImageUrl,
    this.isCheckedIn = false,
    required this.registeredAt,
  });
}

/// Participants section header with count
class ParticipantsSectionHeader extends StatelessWidget {
  final int currentCount;
  final int? maxCapacity;
  final VoidCallback? onShowAll;

  const ParticipantsSectionHeader({
    super.key,
    required this.currentCount,
    this.maxCapacity,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = maxCapacity != null && currentCount >= maxCapacity!;

    return Row(
      children: [
        Icon(
          Icons.people,
          color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Participants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isFull
                ? AppColors.danger.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            maxCapacity != null
                ? '$currentCount / $maxCapacity'
                : '$currentCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isFull ? AppColors.danger : AppColors.success,
            ),
          ),
        ),
        if (isFull) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'FULL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onShowAll != null)
          TextButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View All'),
          ),
      ],
    );
  }
}

/// Participant avatar row (preview)
class ParticipantsPreview extends StatelessWidget {
  final List<Participant> participants;
  final int maxDisplay;
  final VoidCallback? onTap;

  const ParticipantsPreview({
    super.key,
    required this.participants,
    this.maxDisplay = 5,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCount = participants.length > maxDisplay ? maxDisplay : participants.length;
    final extraCount = participants.length - maxDisplay;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Stacked avatars
            SizedBox(
              width: (displayCount * 30.0) + 20,
              height: 40,
              child: Stack(
                children: [
                  for (int i = 0; i < displayCount; i++)
                    Positioned(
                      left: i * 24.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? DarkColors.background : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: _getAvatarColor(i),
                          backgroundImage: participants[i].profileImageUrl != null
                              ? NetworkImage(participants[i].profileImageUrl!)
                              : null,
                          child: participants[i].profileImageUrl == null
                              ? Text(
                                  participants[i].name.isNotEmpty
                                      ? participants[i].name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  if (extraCount > 0)
                    Positioned(
                      left: displayCount * 24.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? DarkColors.background : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark ? DarkColors.surface : Colors.grey[300],
                          child: Text(
                            '+$extraCount',
                            style: TextStyle(
                              color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark ? DarkColors.textTertiary : Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.categoryTech,
      AppColors.categoryCultural,
    ];
    return colors[index % colors.length];
  }
}

/// Single participant list item
class ParticipantListTile extends StatelessWidget {
  final Participant participant;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ParticipantListTile({
    super.key,
    required this.participant,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: participant.profileImageUrl != null
                ? NetworkImage(participant.profileImageUrl!)
                : null,
            child: participant.profileImageUrl == null
                ? Text(
                    participant.name.isNotEmpty
                        ? participant.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (participant.isCheckedIn)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? DarkColors.background : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        participant.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
        ),
      ),
      subtitle: participant.email != null
          ? Text(
              participant.email!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? DarkColors.textTertiary : Colors.grey,
              ),
            )
          : null,
      trailing: trailing ??
          (participant.isCheckedIn
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Checked In',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null),
    );
  }
}
