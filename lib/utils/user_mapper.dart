// lib/utils/user_mapper.dart
// Centralized user mapping utility — single source of truth
// Replaces duplicated _parseRole() and _mapToUser() in:
//   - auth_service.dart
//   - auth_provider.dart
//   - user_repository.dart

import '../models/user.dart';
import '../constants/role_constants.dart';

/// Centralized utility for mapping database rows to User objects.
/// Use this instead of inline _parseRole / _mapToUser methods.
class UserMapper {
  /// Parse a database role string to a UserRole enum
  /// Uses RoleConstants.dbToRoleEnum as the single source of truth
  static UserRole parseRole(String? role) {
    return RoleConstants.dbToRoleEnum(role ?? 'student');
  }

  /// Convert a UserRole enum to a database string
  /// Uses RoleConstants.roleEnumToDb — never use role.toString().split('.').last
  static String roleToDbString(UserRole role) {
    return RoleConstants.roleEnumToDb(role);
  }

  /// Map a Supabase row (Map) to a User object
  static User fromMap(Map<String, dynamic> data) {
    return User.fromMap(data);
  }

  /// Map a Supabase row to a User, with society IDs from a separate query
  static User fromMapWithSocieties(Map<String, dynamic> data, List<String> societyIds) {
    return User(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? 'Unknown',
      role: parseRole(data['role']),
      societyIds: societyIds,
      bio: data['bio'],
      phone: data['phone'],
      profileImageUrl: data['profile_image_url'],
      gender: data['gender'],
      joinedDate: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
    );
  }

  /// Create user insert data for registration
  static Map<String, dynamic> toInsertMap({
    required String id,
    required String email,
    required String name,
    UserRole role = UserRole.student,
    String? gender,
  }) {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': roleToDbString(role),
      'gender': gender,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}
