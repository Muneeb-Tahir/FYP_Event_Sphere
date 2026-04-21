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

  // Database reference helpers
  static get users => client.from('users');
  static get events => client.from('events');
  static get registrations => client.from('registrations');
  static get bookmarks => client.from('bookmarks');
  static get announcements => client.from('announcements');
  static get expenses => client.from('expenses');
  static get polls => client.from('polls');
  static get societies => client.from('societies');
}
