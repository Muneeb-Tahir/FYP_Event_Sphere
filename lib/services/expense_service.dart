// lib/services/expense_service.dart
// MOCK SERVICE - No Firebase/Supabase

import '../models/expense.dart';
import 'dart:async';

class ExpenseService {
  static final List<Expense> _expenses = [
    Expense(
      id: 'exp1',
      eventId: 'event1',
      amount: 500,
      category: 'Venue',
      description: 'Hall rental',
      date: DateTime.now(),
    ),
    Expense(
      id: 'exp2',
      eventId: 'event1',
      amount: 200,
      category: 'Refreshments',
      description: 'Tea and snacks',
      date: DateTime.now(),
    ),
  ];

  // Stream all expenses (initial + periodic updates)
  static Stream<List<Expense>> getExpensesStream() async* {
    // Emit initial list immediately
    yield List.from(_expenses);

    // Emit updated list every 2 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 2))) {
      yield List.from(_expenses);
    }
  }

  // Get expenses for a specific event
  static Stream<List<Expense>> getEventExpensesStream(String eventId) {
    return getExpensesStream().map(
      (expenses) => expenses.where((e) => e.eventId == eventId).toList(),
    );
  }

  // Add new expense
  static Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _expenses.add(expense);
  }

  // Delete expense
  static Future<void> deleteExpense(String expenseId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.removeWhere((e) => e.id == expenseId);
  }
}
