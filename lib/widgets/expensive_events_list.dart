// lib/widgets/expensive_events_list.dart
// Most Expensive Events List Widget

import 'package:flutter/material.dart';

class ExpensiveEventData {
  final String eventName;
  final double totalExpense;
  final String? date;
  final Color? color;

  ExpensiveEventData({
    required this.eventName,
    required this.totalExpense,
    this.date,
    this.color,
  });
}

class ExpensiveEventsList extends StatelessWidget {
  final List<ExpensiveEventData> events;
  final bool isLoading;
  final int maxItems;

  const ExpensiveEventsList({
    super.key,
    required this.events,
    this.isLoading = false,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (events.isEmpty) {
      return _buildEmptyState();
    }

    final displayEvents = events.take(maxItems).toList();
    final maxExpense = displayEvents.map((e) => e.totalExpense).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Most Expensive Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Top ${displayEvents.length}',
                style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...displayEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final percent = event.totalExpense / maxExpense;
            final color = event.color ?? _getColorForRank(index);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event.eventName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs ${_formatAmount(event.totalExpense)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: const Color(0xFF3D3557),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getColorForRank(int index) {
    const colors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFC0C0C0), // Silver
      Color(0xFFCD7F32), // Bronze
      Color(0xFF9D4EDD), // Purple
      Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Color(0xFF3D3557)),
            SizedBox(height: 12),
            Text(
              'No expense data available',
              style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
