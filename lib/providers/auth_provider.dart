// lib/providers/auth_provider.dart
// Riverpod providers for authentication state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../utils/user_mapper.dart';
import '../services/supabase_service.dart';
import '../services/logging_service.dart';
import '../core/result.dart';

/// Auth state that tracks both loading and user state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final app_models.User user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Auth notifier that manages authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial()) {
    _initialize();
  }

  SupabaseClient get _client => SupabaseService.client;

  /// Initialize auth state on app start
  Future<void> _initialize() async {
    state = const AuthLoading();
    try {
      final authUser = SupabaseService.currentUser;
      if (authUser != null) {
        final user = await _loadUserProfile(authUser.id);
        if (user != null) {
          state = AuthAuthenticated(user);
          LoggingService.auth('Session restored', userId: authUser.id);
        } else {
          await _client.auth.signOut();
          state = const AuthUnauthenticated();
        }
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      LoggingService.error('Auth initialization failed', e);
      state = const AuthUnauthenticated();
    }
  }

  /// Sign in with email and password
  Future<Result<app_models.User>> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        state = const AuthError('Invalid email or password');
        return const Failure('Invalid email or password');
      }

      final user = await _loadUserProfile(response.user!.id);
      if (user == null) {
        state = const AuthError('User profile not found');
        return const Failure('User profile not found');
      }

      state = AuthAuthenticated(user);
      LoggingService.auth('Sign in', userId: user.id, success: true);
      return Success(user);
    } catch (e) {
      LoggingService.error('Sign in failed', e);
      state = AuthError(e.toString());
      return Failure(e.toString(), error: e);
    }
  }

  /// Register a new user
  Future<Result<app_models.User>> register({
    required String email,
    required String password,
    required String name,
    required app_models.UserRole role,
    String? gender,
  }) async {
    state = const AuthLoading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString().split('.').last,
          'gender': gender ?? 'male',
        },
      );

      if (response.user == null) {
        state = const AuthError('Registration failed');
        return const Failure('Registration failed');
      }

      // Create user profile
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': name,
        'role': role.toString().split('.').last,
        'society_ids': [],
        'joined_date': DateTime.now().toIso8601String(),
        'gender': gender ?? 'male',
      });

      final user = await _loadUserProfile(response.user!.id);
      if (user == null) {
        state = const AuthError('Failed to load user profile');
        return const Failure('Failed to load user profile');
      }

      state = AuthAuthenticated(user);
      LoggingService.auth('Registration', userId: user.id, success: true);
      return Success(user);
    } catch (e) {
      LoggingService.error('Registration failed', e);
      state = AuthError(e.toString());
      return Failure(e.toString(), error: e);
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    final userId = state is AuthAuthenticated
        ? (state as AuthAuthenticated).user.id
        : null;
    try {
      await _client.auth.signOut();
      state = const AuthUnauthenticated();
      LoggingService.auth('Sign out', userId: userId, success: true);
    } catch (e) {
      LoggingService.error('Sign out failed', e);
    }
  }

  /// Refresh user profile from database
  Future<void> refreshUser() async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      final user = await _loadUserProfile(currentUser.id);
      if (user != null) {
        state = AuthAuthenticated(user);
      }
    }
  }

  /// Update user profile
  Future<Result<app_models.User>> updateProfile(Map<String, dynamic> data) async {
    if (state is! AuthAuthenticated) {
      return const Failure('Not authenticated');
    }

    final currentUser = (state as AuthAuthenticated).user;
    try {
      await _client.from('users').update(data).eq('id', currentUser.id);
      await refreshUser();
      LoggingService.database('update', 'users');
      return Success((state as AuthAuthenticated).user);
    } catch (e) {
      LoggingService.error('Profile update failed', e);
      return Failure(e.toString(), error: e);
    }
  }

  /// Load user profile from database
  Future<app_models.User?> _loadUserProfile(String userId) async {
    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return _mapToUser(data);
    } catch (e) {
      LoggingService.error('Load profile failed', e);
      return null;
    }
  }

  /// Map database record to User model
  app_models.User _mapToUser(Map<String, dynamic> data) {
    return UserMapper.fromMapWithSocieties(
      data,
      List<String>.from(data['society_ids'] ?? []),
    );
  }
}

// ==================== Providers ====================

/// Main auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for current user (nullable)
final currentUserProvider = Provider<app_models.User?>((ref) {
  final authState = ref.watch(authProvider);
  return switch (authState) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Convenience provider for loading status
final isAuthLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthLoading;
});
