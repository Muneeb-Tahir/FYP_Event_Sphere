// lib/models/society.dart
// Society model - No changes needed, already clean

class Society {
  final String id;
  final String name;
  final String? description;
  final String presidentId;

  Society({
    required this.id,
    required this.name,
    this.description,
    required this.presidentId,
  });
}