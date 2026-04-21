// lib/models/user.dart
// Enhanced User model with profile fields and serialization

import '../constants/role_constants.dart';

enum UserRole { student, vicePresident, president, admin, superAdmin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final List<String> societyIds;

  // Profile fields
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final String? gender;
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
    this.gender,
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  // Create from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Unknown',
      role: RoleConstants.dbToRoleEnum(map['role'] ?? 'student'),
      societyIds: map['society_ids'] != null
          ? List<String>.from(map['society_ids'])
          : [],
      bio: map['bio'],
      phone: map['phone'],
      profileImageUrl: map['profile_image_url'],
      gender: map['gender'],
      joinedDate: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': RoleConstants.roleEnumToDb(role),
      'bio': bio,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'gender': gender,
    };
  }

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
    String? gender,
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
      gender: gender ?? this.gender,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, role: ${RoleConstants.roleEnumToDb(role)})';
}