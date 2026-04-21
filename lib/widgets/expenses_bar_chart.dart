// lib/widgets/expenses_bar_chart.dart
// Monthly Expenses Bar Chart Widget using fl_chart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyExpenseData {
  final String month;
  final double amount;

  MonthlyExpenseData({required this.month, required this.amount});
}

class ExpensesBarChart extends StatefulWidget {
  final List<MonthlyExpenseData> data;
  final bool isLoading;
  final Color barColor;
  final Function(DateTimeRange)? onDateRangeChanged;

  const ExpensesBarChart({
    super.key,
    required this.data,
    this.isLoading = false,
    this.barColor = const Color(0xFF9D4EDD),
    this.onDateRangeChanged,
  });

  @override
  State<ExpensesBarChart> createState() => _ExpensesBarChartState();
}

class _ExpensesBarChartState extends State<ExpensesBarChart> {
  DateTimeRange? _selectedRange;
  String _rangeLabel = 'Last 6 Months';

  @override
  void initState() {
    super.initState();
    // Default to last 6 months
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month - 5, 1),
      end: now,
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _selectedRange,
      saveText: 'SELECT',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9D4EDD),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1B2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1B2E),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedRange = result;
        _rangeLabel = _formatDateRange(result);
      });
      widget.onDateRangeChanged?.call(result);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final startMonth = DateFormat('MMM').format(range.start);
    final endMonth = DateFormat('MMM').format(range.end);
    final startYear = range.start.year;
    final endYear = range.end.year;

    if (startYear == endYear) {
      return '$startMonth - $endMonth $endYear';
    } else {
      return '$startMonth $startYear - $endMonth $endYear';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final rawMaxAmount = widget.data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    // If all amounts are 0, show empty state
    if (rawMaxAmount == 0) {
      return _buildEmptyState();
    }

    final maxAmount = rawMaxAmount > 0 ? rawMaxAmount : 1000; // Default to 1000 if all zero

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
                'Monthly Expenses',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _showDateRangePicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3557),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF9D4EDD), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _rangeLabel,
                        style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Color(0xFFB8A9C9), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxAmount * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: const Color(0xFF3D3557),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Rs ${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < widget.data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              widget.data[index].month,
                              style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          _formatAmount(value),
                          style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF3D3557).withOpacity(0.3),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: widget.data.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: widget.barColor,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxAmount * 1.2,
                          color: const Color(0xFF3D3557).withOpacity(0.3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 500),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildLoadingState() {
    return Container(
      height: 280,
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
      height: 280,
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
            Icon(Icons.bar_chart, size: 48, color: Color(0xFF3D3557)),
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
