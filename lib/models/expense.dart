// lib/models/expense.dart
// Expense model - No changes needed, already clean

class Expense {
  final String id;
  final String eventId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  Expense({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });
}