// lib/services/user_service.dart
// User Management Service for Admin RBAC

import 'supabase_service.dart';

class UserInfo {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? bio;
  final String? phone;
  final String? profileImageUrl;
  final DateTime joinedDate;

  UserInfo({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.bio,
    this.phone,
    this.profileImageUrl,
    required this.joinedDate,
  });

  factory UserInfo.fromMap(Map<String, dynamic> data) {
    return UserInfo(
      id: data['id'],
      email: data['email'] ?? '',
      name: data['name'] ?? 'Unknown',
      role: data['role'] ?? 'student',
      bio: data['bio'],
      phone: data['phone'],
      profileImageUrl: data['profile_image_url'],
      joinedDate: DateTime.tryParse(data['joined_date'] ?? '') ?? DateTime.now(),
    );
  }
}

class UserService {
  // Get all users (Admin only)
  static Future<List<UserInfo>> getAllUsers() async {
    final data = await SupabaseService.client
        .from('users')
        .select()
        .order('joined_date', ascending: false);

    return (data as List).map((e) => UserInfo.fromMap(e)).toList();
  }

  // Search users by name or email
  static Future<List<UserInfo>> searchUsers(String query) async {
    final data = await SupabaseService.client
        .from('users')
        .select()
        .or('name.ilike.%$query%,email.ilike.%$query%')
        .order('name');

    return (data as List).map((e) => UserInfo.fromMap(e)).toList();
  }

  // Get users by role
  static Future<List<UserInfo>> getUsersByRole(String role) async {
    final data = await SupabaseService.client
        .from('users')
        .select()
        .eq('role', role)
        .order('name');

    return (data as List).map((e) => UserInfo.fromMap(e)).toList();
  }

  // Update user role (Admin only)
  static Future<void> updateUserRole(String userId, String newRole) async {
    await SupabaseService.client
        .from('users')
        .update({'role': newRole, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // Delete user (Admin only) - uses secure RPC to delete from auth and all tables
  static Future<void> deleteUser(String userId) async {
    await SupabaseService.client
        .rpc('delete_user_completely', params: {'target_user_id': userId});
  }

  // Get user by ID
  static Future<UserInfo?> getUserById(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserInfo.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Get user count by role
  static Future<Map<String, int>> getUserCountsByRole() async {
    final students = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('role', 'student');

    final vicePresidents = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('role', 'vice_president');

    final presidents = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('role', 'president');

    final admins = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('role', 'admin');

    final superAdmins = await SupabaseService.client
        .from('users')
        .select('id')
        .eq('role', 'super_admin');

    return {
      'student': (students as List).length,
      'vice_president': (vicePresidents as List).length,
      'president': (presidents as List).length,
      'admin': (admins as List).length,
      'super_admin': (superAdmins as List).length,
    };
  }
}
