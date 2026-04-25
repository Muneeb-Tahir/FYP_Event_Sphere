// lib/pages/admin_dashboard_page.dart
// Mobile-First Admin Dashboard with Expense Analytics

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/expenses_bar_chart.dart';
import '../widgets/expense_category_donut.dart';
import '../widgets/expensive_events_list.dart';
import '../widgets/upcoming_event_admin_card.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  bool _isLoading = true;
  String? _error;

  // Stat data
  double _monthlyTotal = 0;
  double _annualTotal = 0;
  double _averagePerEvent = 0;
  double _mostExpensiveEventAmount = 0;

  // Chart data
  List<MonthlyExpenseData> _monthlyChartData = [];
  List<CategoryExpenseData> _categoryData = [];
  List<ExpensiveEventData> _expensiveEvents = [];
  List<UpcomingEventAdminData> _upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all analytics data in parallel
      final results = await Future.wait([
        ReportService.getMonthlyExpenseTotal(),
        ReportService.getAnnualExpenseTotal(),
        ReportService.getAverageExpensePerEvent(),
        ReportService.getMonthlyExpenses(months: 6),
        ReportService.getExpensesByCategory(),
        ReportService.getMostExpensiveEvents(limit: 3),
        ReportService.getUpcomingEventsWithBudget(limit: 5),
      ]);

      if (!mounted) return;

      final monthlyTotal = results[0] as double;
      final annualTotal = results[1] as double;
      final avgPerEvent = results[2] as double;
      final monthlyExpenses = results[3] as Map<String, double>;
      final categoryExpenses = results[4] as Map<String, double>;
      final expensiveEvents = results[5] as List<Map<String, dynamic>>;
      final upcomingEvents = results[6] as List<Map<String, dynamic>>;

      // Convert monthly expenses to chart data
      final monthlyChartData = monthlyExpenses.entries.map((e) =>
        MonthlyExpenseData(month: e.key, amount: e.value)
      ).toList();

      // Convert category expenses to chart data
      final categoryChartData = categoryExpenses.entries.map((e) =>
        CategoryExpenseData(
          category: e.key,
          amount: e.value,
          color: ExpenseCategoryColors.getColorForCategory(e.key),
        )
      ).toList();

      // Convert expensive events
      final expensiveEventsList = expensiveEvents.map((e) =>
        ExpensiveEventData(
          eventName: e['eventName'] as String,
          totalExpense: e['totalExpense'] as double,
        )
      ).toList();

      // Convert upcoming events
      final upcomingEventsList = upcomingEvents.map((e) =>
        UpcomingEventAdminData(
          eventId: e['eventId'] as String,
          title: e['title'] as String,
          date: e['date'] as DateTime,
          budget: e['budget'] as double,
          spent: e['spent'] as double,
          status: e['status'] as String,
        )
      ).toList();

      // Get most expensive event name
      String mostExpensiveEventName = '-';
      double mostExpensiveEventAmount = 0;
      if (expensiveEvents.isNotEmpty) {
        mostExpensiveEventName = expensiveEvents.first['eventName'] as String;
        mostExpensiveEventAmount = expensiveEvents.first['totalExpense'] as double;
      }

      setState(() {
        _monthlyTotal = monthlyTotal;
        _annualTotal = annualTotal;
        _averagePerEvent = avgPerEvent;
        _mostExpensiveEventAmount = mostExpensiveEventAmount;
        _monthlyChartData = monthlyChartData;
        _categoryData = categoryChartData;
        _expensiveEvents = expensiveEventsList;
        _upcomingEvents = upcomingEventsList;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) return 'Rs ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
    return 'Rs ${amount.toStringAsFixed(0)}';
  }

  Future<void> _onDateRangeChanged(DateTimeRange range) async {
    try {
      final monthlyExpenses = await ReportService.getMonthlyExpensesByDateRange(
        startDate: range.start,
        endDate: range.end,
      );

      if (!mounted) return;

      final monthlyChartData = monthlyExpenses.entries.map((e) =>
        MonthlyExpenseData(month: e.key, amount: e.value)
      ).toList();

      setState(() {
        _monthlyChartData = monthlyChartData;
      });
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/faq'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1B2E),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.pushNamed(context, '/account-settings');
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: const Color(0xFF9D4EDD),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          Text(
            'Welcome, ${ref.watch(currentUserProvider)?.name ?? 'Admin'}',
            style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Expense Overview',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Stat Cards - 2x2 Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              AdminStatCard(
                title: 'This Month',
                value: _formatCurrency(_monthlyTotal),
                icon: Icons.calendar_month,
                color: const Color(0xFF9D4EDD),
                isLoading: _isLoading,
              ),
              AdminStatCard(
                title: 'Annual Total',
                value: _formatCurrency(_annualTotal),
                icon: Icons.trending_up,
                color: const Color(0xFF3B82F6),
                isLoading: _isLoading,
              ),
              AdminStatCard(
                title: 'Most Expensive',
                value: _formatCurrency(_mostExpensiveEventAmount),
                icon: Icons.star,
                color: const Color(0xFFF59E0B),
                isLoading: _isLoading,
              ),
              AdminStatCard(
                title: 'Avg per Event',
                value: _formatCurrency(_averagePerEvent),
                icon: Icons.calculate,
                color: const Color(0xFF10B981),
                isLoading: _isLoading,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Monthly Expenses Chart
          ExpensesBarChart(
            data: _monthlyChartData,
            isLoading: _isLoading,
            onDateRangeChanged: _onDateRangeChanged,
          ),
          const SizedBox(height: 20),

          // Category Donut Chart
          ExpenseCategoryDonut(
            data: _categoryData,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),

          // Most Expensive Events
          ExpensiveEventsList(
            events: _expensiveEvents,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),

          // Upcoming Events Section
          if (_upcomingEvents.isNotEmpty || _isLoading) ...[
            const Text(
              'Upcoming Events',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._upcomingEvents.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UpcomingEventAdminCard(
                event: event,
                onTap: () => Navigator.pushNamed(context, '/event-detail', arguments: event.eventId),
              ),
            )),
          ],

          // Quick Actions
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
            'Quick Actions',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickActionButton(Icons.add_circle, 'Add Event', const Color(0xFF9D4EDD), () => Navigator.pushNamed(context, '/add-event'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickActionButton(Icons.receipt_long, 'Expenses', const Color(0xFF3B82F6), () => Navigator.pushNamed(context, '/expenses'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickActionButton(Icons.check_circle, 'Approvals', const Color(0xFF10B981), () => Navigator.pushNamed(context, '/event-approval'))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildQuickActionButton(Icons.how_to_reg, 'Attendance', const Color(0xFF22C55E), () => Navigator.pushNamed(context, '/event-attendance'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickActionButton(Icons.qr_code_scanner, 'Scan QR', const Color(0xFFF59E0B), () => Navigator.pushNamed(context, '/qr-scan'))),
              const SizedBox(width: 8),
              Expanded(child: _buildQuickActionButton(Icons.bar_chart, 'Reports', const Color(0xFFEC4899), () => Navigator.pushNamed(context, '/reports'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFFB8A9C9))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
