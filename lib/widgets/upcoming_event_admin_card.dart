// lib/widgets/upcoming_event_admin_card.dart
// Upcoming Event Admin Preview Card

import 'package:flutter/material.dart';

class UpcomingEventAdminData {
  final String eventId;
  final String title;
  final DateTime date;
  final double budget;
  final double spent;
  final String status; // approved, pending, cancelled

  UpcomingEventAdminData({
    required this.eventId,
    required this.title,
    required this.date,
    required this.budget,
    required this.spent,
    required this.status,
  });

  double get percentSpent => budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
}

class UpcomingEventAdminCard extends StatelessWidget {
  final UpcomingEventAdminData event;
  final VoidCallback? onTap;

  const UpcomingEventAdminCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(event.status),
              ],
            ),
            const SizedBox(height: 12),
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8A9C9)),
                const SizedBox(width: 6),
                Text(
                  _formatDate(event.date),
                  style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Budget Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Allocated',
                      style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                    ),
                    Text(
                      'Rs ${_formatAmount(event.budget)}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Amount Spent',
                      style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                    ),
                    Text(
                      'Rs ${_formatAmount(event.spent)}',
                      style: TextStyle(
                        color: _getSpentColor(event.percentSpent),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(event.percentSpent * 100).toStringAsFixed(0)}% spent',
                      style: TextStyle(
                        color: _getSpentColor(event.percentSpent),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rs ${_formatAmount(event.budget - event.spent)} remaining',
                      style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: event.percentSpent,
                    backgroundColor: const Color(0xFF3D3557),
                    valueColor: AlwaysStoppedAnimation<Color>(_getSpentColor(event.percentSpent)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green;
        label = 'Approved';
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange;
        label = 'Pending';
        break;
      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = const Color(0xFF3D3557);
        textColor = const Color(0xFFB8A9C9);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getSpentColor(double percent) {
    if (percent >= 0.9) return Colors.red;
    if (percent >= 0.7) return Colors.orange;
    return Colors.green;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
