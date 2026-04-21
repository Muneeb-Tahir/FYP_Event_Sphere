// lib/pages/event_detail/comments_section.dart
// Comments section for event detail page

import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';

/// Comment data model for this widget
class EventComment {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String content;
  final DateTime createdAt;
  final bool isEdited;

  EventComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    required this.content,
    required this.createdAt,
    this.isEdited = false,
  });
}

/// Comments section header
class CommentsSectionHeader extends StatelessWidget {
  final int commentCount;
  final VoidCallback? onShowAll;

  const CommentsSectionHeader({
    super.key,
    required this.commentCount,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.chat_bubble_outline,
          color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Comments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$commentCount',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        if (onShowAll != null && commentCount > 3)
          TextButton(
            onPressed: onShowAll,
            child: const Text('Show All'),
          ),
      ],
    );
  }
}

/// Comment input field
class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final String? userProfileUrl;

  const CommentInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.isSubmitting = false,
    this.userProfileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
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
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            backgroundImage: userProfileUrl != null ? NetworkImage(userProfileUrl!) : null,
            child: userProfileUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                  color: isDark ? DarkColors.textTertiary : Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: isSubmitting ? null : onSubmit,
            icon: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Single comment card
class CommentCard extends StatelessWidget {
  final EventComment comment;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.isCurrentUser = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? DarkColors.surface.withOpacity(0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: comment.userProfileImageUrl != null
                    ? NetworkImage(comment.userProfileImageUrl!)
                    : null,
                child: comment.userProfileImageUrl == null
                    ? Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                          ),
                        ),
                        if (comment.isEdited) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? DarkColors.textTertiary : Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? DarkColors.textTertiary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: isDark ? DarkColors.textTertiary : Colors.grey,
                  ),
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: TextStyle(
              color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
              height: 1.3,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
