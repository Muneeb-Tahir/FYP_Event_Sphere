// lib/pages/event_detail/feedback_section.dart
// Feedback and rating section for event detail page

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../widgets/star_rating.dart';

/// Event feedback data model for this widget
class EventFeedback {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  EventFeedback({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}

/// Feedback section header with average rating
class FeedbackSectionHeader extends StatelessWidget {
  final double averageRating;
  final int feedbackCount;
  final VoidCallback? onAddFeedback;

  const FeedbackSectionHeader({
    super.key,
    required this.averageRating,
    required this.feedbackCount,
    this.onAddFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rating display
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StarRating(rating: averageRating, size: 20),
                ],
              ),
              Text(
                '$feedbackCount ${feedbackCount == 1 ? 'review' : 'reviews'}',
                style: TextStyle(
                  color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Add review button
          if (onAddFeedback != null)
            ElevatedButton.icon(
              onPressed: onAddFeedback,
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text('Add Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? DarkColors.primary : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single feedback card
class FeedbackCard extends StatelessWidget {
  final EventFeedback feedback;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.isCurrentUser = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: feedback.userProfileImageUrl != null
                    ? NetworkImage(feedback.userProfileImageUrl!)
                    : null,
                child: feedback.userProfileImageUrl == null
                    ? Text(
                        feedback.userName.isNotEmpty
                            ? feedback.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(feedback.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? DarkColors.textTertiary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              StarRating(rating: feedback.rating.toDouble(), size: 14),
            ],
          ),
          if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              feedback.comment!,
              style: TextStyle(
                color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          // Edit/Delete buttons for current user
          if (isCurrentUser && (onEdit != null || onDelete != null)) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} year(s) ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min(s) ago';
    return 'Just now';
  }
}
