// lib/services/supabase_service.dart
// Centralized Supabase client access and helper functions

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Get current auth user
  static User? get currentUser => client.auth.currentUser;

  // Get auth state stream
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Database reference helpers — explicit return types for IDE support
  static SupabaseQueryBuilder get users => client.from('users');
  static SupabaseQueryBuilder get events => client.from('events');
  static SupabaseQueryBuilder get registrations => client.from('registrations');
  static SupabaseQueryBuilder get bookmarks => client.from('bookmarks');
  static SupabaseQueryBuilder get announcements => client.from('announcements');
  static SupabaseQueryBuilder get expenses => client.from('expenses');
  static SupabaseQueryBuilder get polls => client.from('polls');
  static SupabaseQueryBuilder get societies => client.from('societies');
  static SupabaseQueryBuilder get eventReactions => client.from('event_reactions');
}
