// lib/pages/expenses_page.dart
// Real-time Expenses Page with Supabase

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/report_service.dart';
import '../providers/auth_provider.dart';

class ExpensesPageRedesigned extends ConsumerStatefulWidget {
  const ExpensesPageRedesigned({super.key});

  @override
  ConsumerState<ExpensesPageRedesigned> createState() => _ExpensesPageRedesignedState();
}

class _ExpensesPageRedesignedState extends ConsumerState<ExpensesPageRedesigned> {
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _subscribeToExpenseChanges();
  }

  @override
  void dispose() {
    // Supabase automatically cleans up subscriptions when the widget is disposed
    super.dispose();
  }

  void _subscribeToExpenseChanges() {
    // Subscribe to real-time changes on the expenses table
    ReportService.getExpensesStream().listen((expenses) {
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadExpenses() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final expenses = await ReportService.getAllExpenses();
      if (mounted) setState(() { _expenses = expenses; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load: $e'; _isLoading = false; });
    }
  }

  double _calculateTotal() => _expenses.fold(0, (sum, e) => sum + e.amount);
  double _calculateApproved() => _expenses.where((e) => e.approved).fold(0, (sum, e) => sum + e.amount);
  double _calculatePending() => _expenses.where((e) => !e.approved).fold(0, (sum, e) => sum + e.amount);

  String _formatCurrency(double amount) {
    // Format with comma separators for thousands
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return 'Rs. $formatted';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  Future<void> _addExpense() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Other';
    String? selectedEventId;
    final categories = ['Venue', 'Décor', 'Logistics', 'Printing', 'Food', 'Transport', 'Equipment', 'Refreshments', 'Other'];

    // Load events for dropdown
    List<Map<String, dynamic>> events = [];
    try {
      final eventsData = await ReportService.getAllEventsForDropdown();
      events = eventsData;
    } catch (_) {}

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          title: const Text('Add Expense', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Dropdown
                DropdownButtonFormField<String>(
                  value: selectedEventId,
                  decoration: InputDecoration(
                    labelText: 'Select Event',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    prefixIcon: const Icon(Icons.event_rounded, color: Color(0xFF9D4EDD)),
                    filled: true,
                    fillColor: const Color(0xFF2A2640),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3654), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: const Color(0xFF2A2640),
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9D4EDD)),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  hint: const Text('Choose an event', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 15)),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.public_rounded, size: 18, color: Color(0xFFB8A9C9)),
                          SizedBox(width: 12),
                          Text('No Event (General)', style: TextStyle(color: Color(0xFFB8A9C9))),
                        ],
                      ),
                    ),
                    ...events.map((e) => DropdownMenuItem<String>(
                      value: e['eventId'] as String,
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_rounded, size: 18, color: Color(0xFF9D4EDD)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e['title'] as String,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (val) => setDialogState(() {
                    selectedEventId = val;
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF9D4EDD)),
                    filled: true,
                    fillColor: const Color(0xFF2A2640),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3654), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (Rs.)',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF9D4EDD)),
                    filled: true,
                    fillColor: const Color(0xFF2A2640),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3654), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF9D4EDD)),
                    filled: true,
                    fillColor: const Color(0xFF2A2640),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3654), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  dropdownColor: const Color(0xFF2A2640),
                  borderRadius: BorderRadius.circular(12),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9D4EDD)),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description_rounded, color: Color(0xFF9D4EDD)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2640),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF3D3654), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? 0;
      if (amount <= 0 || titleController.text.isEmpty) {
        _showSnackBar('Please enter title and valid amount', isError: true);
        return;
      }

      try {
        await ReportService.createExpense(
          title: titleController.text,
          amount: amount,
          category: selectedCategory,
          description: descController.text.isEmpty ? null : descController.text,
          eventId: selectedEventId,
          createdBy: ref.read(currentUserProvider)?.id,
        );
        _showSnackBar('Expense added!');
        _loadExpenses();
      } catch (e) {
        _showSnackBar('Failed to add: $e', isError: true);
      }
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await ReportService.deleteExpense(id);
      _showSnackBar('Expense deleted');
      _loadExpenses();
    } catch (e) {
      _showSnackBar('Failed to delete: $e', isError: true);
    }
  }

  Future<void> _approveExpense(Expense expense) async {
    try {
      await ReportService.approveExpense(expense.id);
      _showSnackBar('Expense approved!');
      _loadExpenses();
    } catch (e) {
      _showSnackBar('Failed to approve: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Expenses', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _isLoading ? null : _loadExpenses)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          : _error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_error!, style: const TextStyle(color: Colors.red)), const SizedBox(height: 16), ElevatedButton(onPressed: _loadExpenses, child: const Text('Retry'))]))
              : RefreshIndicator(
                  onRefresh: _loadExpenses,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(child: _buildSummaryCard('Total', _formatCurrency(_calculateTotal()), Colors.blue, isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSummaryCard('Approved', _formatCurrency(_calculateApproved()), Colors.green, isDark)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSummaryCard('Pending', _formatCurrency(_calculatePending()), Colors.orange, isDark)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Expenses List
                        const Text('All Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),

                        if (_expenses.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: const Color(0xFF1E1B2E), borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: Column(children: [
                              Icon(Icons.receipt_long, size: 48, color: Color(0xFFB8A9C9)),
                              SizedBox(height: 12),
                              Text('No expenses yet', style: TextStyle(color: Color(0xFFB8A9C9))),
                            ])),
                          )
                        else
                          ..._expenses.map((expense) => _buildExpenseCard(expense, isDark)),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: _addExpense,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFB8A9C9))),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: expense.approved ? Border.all(color: Colors.green, width: 1) : Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (expense.approved ? Colors.green : Colors.orange).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.receipt, color: expense.approved ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                Row(
                  children: [
                    if (expense.category != null) Text('${expense.category}', style: const TextStyle(fontSize: 11, color: Color(0xFFB8A9C9))),
                    if (expense.eventTitle != null) Text(' • ${expense.eventTitle}', style: const TextStyle(fontSize: 11, color: Color(0xFFB8A9C9))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: expense.approved
                          ? Colors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      expense.approved ? 'Approved' : 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        color: expense.approved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _deleteExpense(expense.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Delete', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
