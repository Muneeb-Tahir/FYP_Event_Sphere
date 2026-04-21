// lib/services/expense_service.dart
// Expense service using Supabase

import '../models/expense.dart';
import 'supabase_service.dart';
import 'logging_service.dart';
import 'dart:async';

class ExpenseService {
  // ------------------------- STREAM ALL EXPENSES -------------------------
  static Stream<List<Expense>> getExpensesStream() {
    return SupabaseService.client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((data) => data.map((e) => Expense.fromMap(e)).toList());
  }

  // ------------------------- GET EVENT EXPENSES STREAM -------------------------
  static Stream<List<Expense>> getEventExpensesStream(String eventId) {
    return SupabaseService.client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .map((data) => data.map((e) => Expense.fromMap(e)).toList());
  }

  // ------------------------- GET EVENT EXPENSES -------------------------
  static Future<List<Expense>> getEventExpenses(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('expenses')
          .select()
          .eq('event_id', eventId)
          .order('date', ascending: false);

      return (data as List).map((e) => Expense.fromMap(e)).toList();
    } catch (e) {
      LoggingService.error('Error fetching expenses', e);
      return [];
    }
  }

  // ------------------------- ADD EXPENSE -------------------------
  static Future<void> addExpense(Expense expense) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final data = expense.toMap();
    data.remove('id'); // Let DB generate UUID
    data['created_by'] = userId;

    await SupabaseService.client.from('expenses').insert(data);
    LoggingService.info('Expense added: ${expense.category} - ${expense.amount}');
  }

  // ------------------------- UPDATE EXPENSE -------------------------
  static Future<void> updateExpense(Expense expense) async {
    await SupabaseService.client
        .from('expenses')
        .update(expense.toMap())
        .eq('id', expense.id);

    LoggingService.info('Expense updated: ${expense.id}');
  }

  // ------------------------- DELETE EXPENSE -------------------------
  static Future<void> deleteExpense(String expenseId) async {
    await SupabaseService.client
        .from('expenses')
        .delete()
        .eq('id', expenseId);

    LoggingService.info('Expense deleted: $expenseId');
  }

  // ------------------------- GET TOTAL FOR EVENT -------------------------
  static Future<double> getEventTotal(String eventId) async {
    final expenses = await getEventExpenses(eventId);
    return expenses.fold<double>(0, (sum, e) => sum + e.amount);
  }
}
