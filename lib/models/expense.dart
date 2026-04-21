// lib/models/expense.dart
// Expense model with serialization

class Expense {
  final String id;
  final String eventId;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? createdBy;

  const Expense({
    required this.id,
    required this.eventId,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.createdBy,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date'] ?? map['created_at'] ?? DateTime.now().toIso8601String()),
      createdBy: map['created_by'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Expense copyWith({
    String? id,
    String? eventId,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    String? createdBy,
  }) {
    return Expense(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  String toString() => 'Expense(id: $id, category: $category, amount: $amount)';
}