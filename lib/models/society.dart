// lib/models/society.dart
// Society model with serialization

class Society {
  final String id;
  final String name;
  final String? description;
  final String presidentId;
  final String? logoUrl;
  final String? category;
  final DateTime? createdAt;

  const Society({
    required this.id,
    required this.name,
    this.description,
    required this.presidentId,
    this.logoUrl,
    this.category,
    this.createdAt,
  });

  factory Society.fromMap(Map<String, dynamic> map) {
    return Society(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      presidentId: map['president_id'] ?? '',
      logoUrl: map['logo_url'],
      category: map['category'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'president_id': presidentId,
      'logo_url': logoUrl,
      'category': category,
    };
  }

  Society copyWith({
    String? id,
    String? name,
    String? description,
    String? presidentId,
    String? logoUrl,
    String? category,
    DateTime? createdAt,
  }) {
    return Society(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      presidentId: presidentId ?? this.presidentId,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Society(id: $id, name: $name)';
}