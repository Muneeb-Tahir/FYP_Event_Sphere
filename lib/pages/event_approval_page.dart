import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/report_service.dart';
import '../constants/app_theme.dart';
import 'event_approval_detail_page.dart';

class EventApprovalPage extends StatefulWidget {
  const EventApprovalPage({super.key});

  @override
  State<EventApprovalPage> createState() => _EventApprovalPageState();
}

class _EventApprovalPageState extends State<EventApprovalPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Expense> _pendingExpenses = [];
  bool _loadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingExpenses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingExpenses() async {
    try {
      final expenses = await ReportService.getAllExpenses();
      if (mounted) {
        setState(() {
          _pendingExpenses = expenses.where((e) => !e.approved).toList();
          _loadingExpenses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingExpenses = false);
    }
  }

  Future<void> _approveExpense(Expense expense) async {
    try {
      await ReportService.approveExpense(expense.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Expense approved!')]),
          backgroundColor: Colors.green,
        ),
      );
      _loadPendingExpenses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return 'Rs. $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3557),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Approvals', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF9D4EDD),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFB8A9C9),
          tabs: const [
            Tab(text: 'Events', icon: Icon(Icons.event, size: 20)),
            Tab(text: 'Expenses', icon: Icon(Icons.receipt_long, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsTab(),
          _buildExpensesTab(),
        ],
      ),
    );
  }

  // Events Tab - existing functionality
  Widget _buildEventsTab() {
    return StreamBuilder<List<Event>>(
      stream: EventService.getPendingEventsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
        }

        var pendingEvents = snapshot.data!;
        if (pendingEvents.isEmpty) {
          return _buildEmptyState('Events', Icons.event_available, 'No pending event approvals');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pendingEvents.length,
          itemBuilder: (context, idx) => _buildEventCard(context, pendingEvents[idx]),
        );
      },
    );
  }

  // Expenses Tab - new functionality
  Widget _buildExpensesTab() {
    if (_loadingExpenses) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
    }

    if (_pendingExpenses.isEmpty) {
      return _buildEmptyState('Expenses', Icons.receipt_long, 'No pending expense approvals');
    }

    return RefreshIndicator(
      onRefresh: _loadPendingExpenses,
      color: const Color(0xFF9D4EDD),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingExpenses.length,
        itemBuilder: (context, idx) => _buildExpenseCard(_pendingExpenses[idx]),
      ),
    );
  }

  Widget _buildEmptyState(String type, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppTheme.successColor),
          ),
          const SizedBox(height: 20),
          const Text('All caught up!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (expense.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                            child: Text(expense.category!, style: const TextStyle(fontSize: 11, color: Color(0xFF9D4EDD))),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (expense.eventTitle != null)
                          Flexible(
                            child: Text('• ${expense.eventTitle}', style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9)), overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(_formatCurrency(expense.amount), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          if (expense.description != null && expense.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(expense.description!, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 13)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectExpense(expense),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveExpense(expense),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rejectExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Reject Expense', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to reject "${expense.title}"?', style: const TextStyle(color: Color(0xFFB8A9C9))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ReportService.deleteExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense rejected'), backgroundColor: Colors.orange),
        );
        _loadPendingExpenses();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () => _openEventDetails(context, event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.cornerRadiusLarge),
                  topRight: Radius.circular(AppTheme.cornerRadiusLarge),
                ),
                child: Image.network(
                  event.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: _getCategoryColor(event.category).withOpacity(0.1),
                    child: Center(
                      child: Icon(Icons.event, size: 40, color: _getCategoryColor(event.category)),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Header Row
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Pending Review',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(event.category),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Event title
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Event details
              _buildDetailRow(Icons.location_on_outlined, event.venue),
              const SizedBox(height: 6),
              _buildDetailRow(Icons.calendar_today, _formatDate(event.date)),
              const SizedBox(height: 12),

              // Tap to view hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF9D4EDD).withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: const Color(0xFF9D4EDD).withOpacity(0.7),
                  ),
                ],
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEventDetails(BuildContext context, Event event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventApprovalDetailPage(event: event),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFB8A9C9)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFB8A9C9),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech': return AppColors.categoryTech;
      case 'sports': return AppColors.categorySports;
      case 'cultural': return AppColors.categoryCultural;
      case 'academic': return AppColors.categoryAcademic;
      case 'music': return AppColors.categoryMusic;
      default: return AppColors.primary;
    }
  }
}
