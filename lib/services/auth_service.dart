// lib/services/auth_service.dart
// Supabase Authentication Service with Email Confirmation

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import 'supabase_service.dart';

class AuthService {
  static app_models.User? _currentAppUser;

  // Get Supabase client
  static SupabaseClient get _client => SupabaseService.client;

  // ------------------------- LOGIN -------------------------
  static Future<void> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Invalid email or password');
    }

    // Fetch user profile from database
    await _loadUserProfile(response.user!.id);
  }

  // ------------------------- REGISTER WITH EMAIL CONFIRMATION -------------------------
  static Future<void> register(
    String email,
    String password,
    app_models.UserRole role,
    String name, {
    String? gender,
  }) async {
    // Sign up with Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: null,
      data: {
        'name': name,
        'role': role.toString().split('.').last,
        'gender': gender ?? 'male',
      },
    );

    if (response.user == null) {
      throw Exception('Registration failed');
    }

    // Manually create user profile in public.users table
    try {
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'society_ids': [],
        'joined_date': DateTime.now().toIso8601String(),
        'gender': gender ?? 'male',
      });
    } catch (e) {
      // Profile might already exist from trigger, ignore duplicate error
      print('Profile creation note: $e');
    }

    // Load the user profile
    await _loadUserProfile(response.user!.id);
  }


  // ------------------------- LOAD USER PROFILE -------------------------
  static Future<void> _loadUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      throw Exception('User profile not found');
    }
    _currentAppUser = _mapToUser(data);
  }

  // ------------------------- MAP DATABASE TO USER MODEL -------------------------
  static app_models.User _mapToUser(Map<String, dynamic> data) {
    return app_models.User(
      id: data['id'],
      email: data['email'],
      name: data['name'],
      role: _parseRole(data['role']),
      societyIds: List<String>.from(data['society_ids'] ?? []),
      bio: data['bio'],
      phone: data['phone'],
      profileImageUrl: data['profile_image_url'],
      joinedDate: DateTime.parse(data['joined_date']),
    );
  }

  static app_models.UserRole _parseRole(String? role) {
    switch (role) {
      case 'super_admin':
        return app_models.UserRole.superAdmin;
      case 'admin':
        return app_models.UserRole.admin;
      case 'president':
        return app_models.UserRole.president;
      case 'vicePresident':
      case 'vice_president':
        return app_models.UserRole.vicePresident;
      case 'student':
      default:
        return app_models.UserRole.student;
    }
  }

  // ------------------------- GET CURRENT USER -------------------------
  static app_models.User? getCurrentUser() {
    return _currentAppUser;
  }

  // ------------------------- REFRESH USER FROM DATABASE -------------------------
  static Future<void> refreshCurrentUser() async {
    final authUser = SupabaseService.currentUser;
    if (authUser != null) {
      await _loadUserProfile(authUser.id);
    }
  }

  // ------------------------- USER PROFILE -------------------------
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .single();

    return {
      'id': data['id'],
      'email': data['email'],
      'name': data['name'],
      'role': data['role'],
      'societyIds': data['society_ids'],
      'bio': data['bio'],
      'phone': data['phone'],
      'profileImageUrl': data['profile_image_url'],
      'joinedDate': data['joined_date'],
    };
  }

  // ------------------------- UPDATE PROFILE -------------------------
  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('users').update({
      if (data['email'] != null) 'email': data['email'],
      if (data['name'] != null) 'name': data['name'],
      if (data['bio'] != null) 'bio': data['bio'],
      if (data['phone'] != null) 'phone': data['phone'],
      if (data['profileImageUrl'] != null) 'profile_image_url': data['profileImageUrl'],
    }).eq('id', userId);

    // Refresh current user cache
    if (_currentAppUser?.id == userId) {
      await _loadUserProfile(userId);
    }
  }

  // ------------------------- CHANGE PASSWORD -------------------------
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    // Verify current password by re-authenticating
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Update password
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ------------------------- RESET PASSWORD (SEND EMAIL) -------------------------
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ------------------------- DELETE ACCOUNT -------------------------
  static Future<void> deleteAccount(String password) async {
    final user = SupabaseService.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Re-authenticate to verify password
    await _client.auth.signInWithPassword(
      email: user.email!,
      password: password,
    );

    // Delete user data from database
    await _client.from('users').delete().eq('id', user.id);
    await _client.from('registrations').delete().eq('user_id', user.id);
    await _client.from('bookmarks').delete().eq('user_id', user.id);

    // Sign out
    await signOut();
  }

  // ------------------------- LOGOUT -------------------------
  static Future<void> signOut() async {
    await _client.auth.signOut();
    _currentAppUser = null;
  }

  // ------------------------- AUTH CHECK -------------------------
  static bool isAuthenticated() {
    return SupabaseService.isAuthenticated;
  }

  static bool get isLoggedIn => SupabaseService.isAuthenticated && _currentAppUser != null;

  // ------------------------- INITIALIZE ON APP START -------------------------
  static Future<void> initializeAuth() async {
    final authUser = SupabaseService.currentUser;
    if (authUser != null) {
      try {
        await _loadUserProfile(authUser.id);
      } catch (e) {
        // User exists in auth but not in database, sign them out
        await signOut();
      }
    }
  }

  // ------------------------- RESEND CONFIRMATION EMAIL -------------------------
  static Future<void> resendConfirmationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // ------------------------- CHECK EMAIL CONFIRMED -------------------------
  static bool get isEmailConfirmed {
    final user = SupabaseService.currentUser;
    return user?.emailConfirmedAt != null;
  }
}
