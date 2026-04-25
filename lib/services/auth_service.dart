// lib/services/auth_service.dart
// Supabase Authentication Service with Email Confirmation

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../constants/role_constants.dart';
import '../utils/user_mapper.dart';
import 'supabase_service.dart';
import 'logging_service.dart';

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
    // Sign out any existing session first to prevent session bleed
    try {
      await _client.auth.signOut();
      _currentAppUser = null;
    } catch (_) {}

    // Sign up with Supabase Auth
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: null,
      data: {
        'name': name,
        'role': RoleConstants.roleEnumToDb(role),
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
        'role': RoleConstants.roleEnumToDb(role),
        'society_ids': [],
        'joined_date': DateTime.now().toIso8601String(),
        'gender': gender ?? 'male',
      });
    } catch (e) {
      // Profile might already exist from trigger, ignore duplicate error
      LoggingService.warning('Profile creation note: $e');
    }

    // Sign out after registration — user must log in manually
    // This prevents session bleed where new account inherits old session
    try {
      await _client.auth.signOut();
      _currentAppUser = null;
    } catch (_) {}
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
    return UserMapper.fromMapWithSocieties(
      data,
      List<String>.from(data['society_ids'] ?? []),
    );
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

    // Re-authenticate to verify current password
    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: currentPassword,
      );
    } on AuthException catch (_) {
      throw Exception('Current password is incorrect');
    }

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
    try {
      await _client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception('Password verification failed: ${e.message}');
    }

    // Delete user data from all related tables
    // Order matters: delete child records before parent
    await _client.from('event_reminders').delete().eq('user_id', user.id);
    await _client.from('event_feedback').delete().eq('user_id', user.id);
    await _client.from('event_waitlist').delete().eq('user_id', user.id);
    await _client.from('registrations').delete().eq('user_id', user.id);
    await _client.from('bookmarks').delete().eq('user_id', user.id);
    await _client.from('user_points').delete().eq('user_id', user.id);

    // Delete the auth user via server-side RPC
    // This calls a SECURITY DEFINER function that uses auth.admin API
    try {
      await _client.rpc('delete_user_account', params: {'user_id': user.id});
    } catch (e) {
      // If RPC doesn't exist, fall back to deleting the profile row
      // The auth user will remain but profile data is gone
      await _client.from('users').delete().eq('id', user.id);
    }

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
