// lib/models/user.dart
// Enhanced User model with profile fields

enum UserRole { student, vicePresident, president, admin, superAdmin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final List<String> societyIds;

  // New profile fields
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final DateTime joinedDate;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.societyIds,
    this.bio,
    this.phone,
    this.profileImageUrl,
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    List<String>? societyIds,
    String? bio,
    String? phone,
    String? profileImageUrl,
    DateTime? joinedDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      societyIds: societyIds ?? this.societyIds,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}