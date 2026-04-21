// lib/services/report_service.dart
// Real-time Dashboard Stats from Supabase

import 'supabase_service.dart';

class EventReport {
  final String eventId;
  final String eventTitle;
  final int totalRegistrations;
  final int totalAttendees;
  final double attendanceRate;
  final double totalExpenses;
  final DateTime eventDate;

  EventReport({
    required this.eventId,
    required this.eventTitle,
    required this.totalRegistrations,
    required this.totalAttendees,
    required this.attendanceRate,
    required this.totalExpenses,
    required this.eventDate,
  });
}

class DashboardStats {
  final int totalEvents;
  final int pendingEvents;
  final int approvedEvents;
  final int rejectedEvents;
  final int totalUsers;
  final int totalSocieties;
  final double totalExpenses;
  final int totalRegistrations;

  DashboardStats({
    required this.totalEvents,
    required this.pendingEvents,
    required this.approvedEvents,
    required this.rejectedEvents,
    required this.totalUsers,
    required this.totalSocieties,
    required this.totalExpenses,
    required this.totalRegistrations,
  });
}

class Expense {
  final String id;
  final String title;
  final double amount;
  final String? category;
  final String? description;
  final String? eventTitle;
  final bool approved;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    this.category,
    this.description,
    this.eventTitle,
    required this.approved,
    required this.createdAt,
  });
}

class ReportService {
  // ===================== GET REAL-TIME DASHBOARD STATS =====================
  static Future<DashboardStats> getDashboardStats() async {
    try {
      // Get total events
      final eventsData = await SupabaseService.client.from('events').select('id, approval_status');
      final events = eventsData as List;
      final totalEvents = events.length;
      final pendingEvents = events.where((e) => e['approval_status'] == 'pending').length;
      final approvedEvents = events.where((e) => e['approval_status'] == 'approved').length;
      final rejectedEvents = events.where((e) => e['approval_status'] == 'rejected').length;

      // Get total users
      final usersData = await SupabaseService.client.from('users').select('id');
      final totalUsers = (usersData as List).length;

      // Get total societies
      final societiesData = await SupabaseService.client.from('societies').select('id');
      final totalSocieties = (societiesData as List).length;

      // Get total registrations
      final registrationsData = await SupabaseService.client.from('registrations').select('id');
      final totalRegistrations = (registrationsData as List).length;

      // Get total expenses
      double totalExpenses = 0;
      try {
        final expensesData = await SupabaseService.client.from('expenses').select('amount');
        for (var expense in (expensesData as List)) {
          totalExpenses += (expense['amount'] as num).toDouble();
        }
      } catch (_) {}

      return DashboardStats(
        totalEvents: totalEvents,
        pendingEvents: pendingEvents,
        approvedEvents: approvedEvents,
        rejectedEvents: rejectedEvents,
        totalUsers: totalUsers,
        totalSocieties: totalSocieties,
        totalExpenses: totalExpenses,
        totalRegistrations: totalRegistrations,
      );
    } catch (e) {
      // Return zeros if error
      return DashboardStats(
        totalEvents: 0,
        pendingEvents: 0,
        approvedEvents: 0,
        rejectedEvents: 0,
        totalUsers: 0,
        totalSocieties: 0,
        totalExpenses: 0,
        totalRegistrations: 0,
      );
    }
  }

  // ===================== GET EVENT REPORTS =====================
  static Future<List<EventReport>> getEventReports({
    DateTime? startDate,
    DateTime? endDate,
    String? societyId,
  }) async {
    try {
      final data = await SupabaseService.client
          .from('events')
          .select('id, title, date')
          .eq('approval_status', 'approved')
          .order('date', ascending: false);

      List<EventReport> reports = [];
      for (var event in (data as List)) {
        // Get registrations count
        final regs = await SupabaseService.client
            .from('registrations')
            .select('id, checked_in')
            .eq('event_id', event['id']);

        final totalReg = (regs as List).length;
        final attended = regs.where((r) => r['checked_in'] == true).length;
        final rate = totalReg > 0 ? (attended / totalReg) * 100 : 0.0;

        // Get expenses
        double expenses = 0;
        try {
          final expData = await SupabaseService.client
              .from('expenses')
              .select('amount')
              .eq('event_id', event['id']);
          for (var exp in (expData as List)) {
            expenses += (exp['amount'] as num).toDouble();
          }
        } catch (_) {}

        reports.add(EventReport(
          eventId: event['id'],
          eventTitle: event['title'] ?? 'Untitled',
          totalRegistrations: totalReg,
          totalAttendees: attended,
          attendanceRate: rate,
          totalExpenses: expenses,
          eventDate: DateTime.tryParse(event['date'] ?? '') ?? DateTime.now(),
        ));
      }
      return reports;
    } catch (e) {
      return [];
    }
  }

  // ===================== GET RECENT EXPENSES =====================
  static Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select('*, events(title)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List).map((item) => Expense(
        id: item['id'],
        title: item['title'] ?? 'Untitled',
        amount: (item['amount'] as num).toDouble(),
        category: item['category'],
        description: item['description'],
        eventTitle: item['events']?['title'],
        approved: item['approved'] ?? false,
        createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // ===================== CREATE EXPENSE =====================
  static Future<void> createExpense({
    required String title,
    required double amount,
    String? category,
    String? description,
    String? eventId,
    String? createdBy,
  }) async {
    await SupabaseService.client.from('expenses').insert({
      'title': title,
      'amount': amount,
      'category': category,
      'description': description,
      'event_id': eventId,
      'created_by': createdBy,
      'approved': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ===================== APPROVE EXPENSE =====================
  static Future<void> approveExpense(String expenseId) async {
    await SupabaseService.client
        .from('expenses')
        .update({'approved': true})
        .eq('id', expenseId);
  }

  // ===================== DELETE EXPENSE =====================
  static Future<void> deleteExpense(String expenseId) async {
    await SupabaseService.client.from('expenses').delete().eq('id', expenseId);
  }

  // ===================== GET ALL EXPENSES =====================
  static Future<List<Expense>> getAllExpenses() async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select('*, events(title)')
          .order('created_at', ascending: false);

      return (data as List).map((item) => Expense(
        id: item['id'],
        title: item['title'] ?? 'Untitled',
        amount: (item['amount'] as num).toDouble(),
        category: item['category'],
        description: item['description'],
        eventTitle: item['events']?['title'],
        approved: item['approved'] ?? false,
        createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // ===================== GET EXPENSES STREAM (REAL-TIME) =====================
  static Stream<List<Expense>> getExpensesStream() {
    return SupabaseService.client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((item) => Expense(
              id: item['id'],
              title: item['title'] ?? 'Untitled',
              amount: (item['amount'] as num).toDouble(),
              category: item['category'],
              description: item['description'],
              eventTitle: null, // Stream doesn't support joins
              approved: item['approved'] ?? false,
              createdAt: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
            )).toList());
  }

  // ===================== ADMIN DASHBOARD ANALYTICS =====================

  /// Get monthly expense totals for the last N months
  static Future<Map<String, double>> getMonthlyExpenses({int months = 6}) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - months + 1, 1);

      final data = await SupabaseService.client
          .from('expenses')
          .select('amount, created_at')
          .eq('approved', true)
          .gte('created_at', startDate.toIso8601String());

      Map<String, double> monthlyTotals = {};
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      // Initialize all months with 0
      for (int i = 0; i < months; i++) {
        final date = DateTime(now.year, now.month - months + 1 + i, 1);
        final key = monthNames[date.month - 1];
        monthlyTotals[key] = 0;
      }

      // Sum up expenses by month
      for (var expense in (data as List)) {
        final createdAt = DateTime.tryParse(expense['created_at'] ?? '');
        if (createdAt != null) {
          final key = monthNames[createdAt.month - 1];
          final amount = (expense['amount'] as num).toDouble();
          monthlyTotals[key] = (monthlyTotals[key] ?? 0) + amount;
        }
      }

      return monthlyTotals;
    } catch (e) {
      return {};
    }
  }

  /// Get monthly expense totals for a specific date range
  static Future<Map<String, double>> getMonthlyExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select('amount, created_at')
          .eq('approved', true)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      Map<String, double> monthlyTotals = {};
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

      // Initialize all months in the range with 0
      DateTime current = DateTime(startDate.year, startDate.month, 1);
      while (current.isBefore(endDate) || current.month == endDate.month && current.year == endDate.year) {
        final key = monthNames[current.month - 1];
        monthlyTotals[key] = 0;
        current = DateTime(current.year, current.month + 1, 1);
      }

      // Sum up expenses by month
      for (var expense in (data as List)) {
        final createdAt = DateTime.tryParse(expense['created_at'] ?? '');
        if (createdAt != null) {
          final key = monthNames[createdAt.month - 1];
          final amount = (expense['amount'] as num).toDouble();
          monthlyTotals[key] = (monthlyTotals[key] ?? 0) + amount;
        }
      }

      return monthlyTotals;
    } catch (e) {
      return {};
    }
  }

  /// Get expenses grouped by category
  static Future<Map<String, double>> getExpensesByCategory() async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select('amount, category')
          .eq('approved', true);

      Map<String, double> categoryTotals = {};

      for (var expense in (data as List)) {
        final category = expense['category'] ?? 'Other';
        final amount = (expense['amount'] as num).toDouble();
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      return {};
    }
  }

  /// Get most expensive events (top N by total expense)
  static Future<List<Map<String, dynamic>>> getMostExpensiveEvents({int limit = 5}) async {
    try {
      // Get all events with their expenses
      final eventsData = await SupabaseService.client
          .from('events')
          .select('id, title');

      List<Map<String, dynamic>> eventExpenses = [];

      for (var event in (eventsData as List)) {
        final expensesData = await SupabaseService.client
            .from('expenses')
            .select('amount')
            .eq('event_id', event['id'])
            .eq('approved', true);

        double total = 0;
        for (var exp in (expensesData as List)) {
          total += (exp['amount'] as num).toDouble();
        }

        if (total > 0) {
          eventExpenses.add({
            'eventId': event['id'],
            'eventName': event['title'] ?? 'Untitled',
            'totalExpense': total,
          });
        }
      }

      // Sort by total expense descending
      eventExpenses.sort((a, b) => (b['totalExpense'] as double).compareTo(a['totalExpense'] as double));

      return eventExpenses.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all events for dropdown selection (used in expense form)
  static Future<List<Map<String, dynamic>>> getAllEventsForDropdown() async {
    try {
      final eventsData = await SupabaseService.client
          .from('events')
          .select('id, title, date')
          .order('date', ascending: false);

      return (eventsData as List).map((event) => {
        'eventId': event['id'] as String,
        'title': event['title'] ?? 'Untitled',
        'date': DateTime.tryParse(event['date'] ?? '') ?? DateTime.now(),
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get upcoming events with budget information
  static Future<List<Map<String, dynamic>>> getUpcomingEventsWithBudget({int limit = 5}) async {
    try {
      final now = DateTime.now();
      final eventsData = await SupabaseService.client
          .from('events')
          .select('id, title, date, approval_status, budget')
          .gte('date', now.toIso8601String())
          .order('date', ascending: true)
          .limit(limit);

      List<Map<String, dynamic>> result = [];

      for (var event in (eventsData as List)) {
        // Get spent amount for this event
        double spent = 0;
        try {
          final expensesData = await SupabaseService.client
              .from('expenses')
              .select('amount')
              .eq('event_id', event['id']);

          for (var exp in (expensesData as List)) {
            spent += (exp['amount'] as num).toDouble();
          }
        } catch (_) {}

        result.add({
          'eventId': event['id'],
          'title': event['title'] ?? 'Untitled',
          'date': DateTime.tryParse(event['date'] ?? '') ?? now,
          'status': event['approval_status'] ?? 'pending',
          'budget': (event['budget'] as num?)?.toDouble() ?? 0,
          'spent': spent,
        });
      }

      return result;
    } catch (e) {
      return [];
    }
  }

  /// Get total expenses for current year
  static Future<double> getAnnualExpenseTotal() async {
    try {
      final startOfYear = DateTime(DateTime.now().year, 1, 1);

      final data = await SupabaseService.client
          .from('expenses')
          .select('amount')
          .eq('approved', true)
          .gte('created_at', startOfYear.toIso8601String());

      double total = 0;
      for (var expense in (data as List)) {
        total += (expense['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get total expenses for current month
  static Future<double> getMonthlyExpenseTotal() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final data = await SupabaseService.client
          .from('expenses')
          .select('amount')
          .eq('approved', true)
          .gte('created_at', startOfMonth.toIso8601String());

      double total = 0;
      for (var expense in (data as List)) {
        total += (expense['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Get average expense per event
  static Future<double> getAverageExpensePerEvent() async {
    try {
      // Get events with expenses
      final eventsData = await SupabaseService.client
          .from('events')
          .select('id');

      if ((eventsData as List).isEmpty) return 0;

      final expensesData = await SupabaseService.client
          .from('expenses')
          .select('amount')
          .eq('approved', true);

      double totalExpenses = 0;
      for (var exp in (expensesData as List)) {
        totalExpenses += (exp['amount'] as num).toDouble();
      }

      // Get unique events with expenses
      final eventsWithExpenses = await SupabaseService.client
          .from('expenses')
          .select('event_id')
          .eq('approved', true);

      final uniqueEventIds = (eventsWithExpenses as List)
          .map((e) => e['event_id'])
          .toSet()
          .length;

      if (uniqueEventIds == 0) return 0;
      return totalExpenses / uniqueEventIds;
    } catch (e) {
      return 0;
    }
  }
}
