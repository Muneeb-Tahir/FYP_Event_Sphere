// lib/widgets/expense_category_donut.dart
// Expense Category Donut Chart Widget using fl_chart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryExpenseData {
  final String category;
  final double amount;
  final Color color;

  CategoryExpenseData({
    required this.category,
    required this.amount,
    required this.color,
  });
}

class ExpenseCategoryDonut extends StatefulWidget {
  final List<CategoryExpenseData> data;
  final bool isLoading;

  const ExpenseCategoryDonut({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  State<ExpenseCategoryDonut> createState() => _ExpenseCategoryDonutState();
}

class _ExpenseCategoryDonutState extends State<ExpenseCategoryDonut> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final total = widget.data.map((e) => e.amount).reduce((a, b) => a + b);

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
          const Text(
            'Expenses by Category',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut Chart
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildSections(total),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final percent = (item.amount / total * 100).toStringAsFixed(0);
                    final isSelected = index == touchedIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFFB8A9C9),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFFB8A9C9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == touchedIndex;
      final radius = isTouched ? 35.0 : 28.0;
      final percent = (item.amount / total * 100);

      return PieChartSectionData(
        color: item.color,
        value: item.amount,
        title: isTouched ? '${percent.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLoadingState() {
    return Container(
      height: 220,
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
      height: 220,
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
            Icon(Icons.pie_chart_outline, size: 48, color: Color(0xFF3D3557)),
            SizedBox(height: 12),
            Text(
              'No category data available',
              style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// Default category colors - unique colors for each category
class ExpenseCategoryColors {
  static const Color venue = Color(0xFF9D4EDD);       // Purple
  static const Color decor = Color(0xFFEC4899);       // Pink
  static const Color logistics = Color(0xFF3B82F6);   // Blue
  static const Color printing = Color(0xFF10B981);    // Emerald Green
  static const Color food = Color(0xFFF59E0B);        // Amber/Orange
  static const Color transport = Color(0xFF6366F1);   // Indigo (different from Blue)
  static const Color equipment = Color(0xFFEF4444);   // Red
  static const Color refreshments = Color(0xFF14B8A6);// Teal (different from Purple)
  static const Color other = Color(0xFF6B7280);       // Gray

  static Color getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return venue;
      case 'decor':
      case 'décor':
      case 'decoration':
        return decor;
      case 'logistics':
        return logistics;
      case 'printing':
      case 'marketing':
        return printing;
      case 'food':
      case 'catering':
        return food;
      case 'transport':
      case 'transportation':
        return transport;
      case 'equipment':
        return equipment;
      case 'refreshments':
        return refreshments;
      default:
        return other;
    }
  }
}
