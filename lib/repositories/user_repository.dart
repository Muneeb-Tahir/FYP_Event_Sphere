// lib/repositories/user_repository.dart
// User repository implementation

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../constants/role_constants.dart';
import '../utils/user_mapper.dart';
import '../core/result.dart';
import '../services/supabase_service.dart';
import '../services/logging_service.dart';
import 'base_repository.dart';

/// Repository for User data access
class UserRepository implements BaseRepository<app_models.User> {
  final SupabaseClient _client;

  UserRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  /// Get table reference
  SupabaseQueryBuilder get _users => _client.from('users');

  @override
  Future<Result<List<app_models.User>>> getAll() async {
    try {
      final data = await _users.select().order('name', ascending: true);
      final users = (data as List).map((e) => _mapToUser(e)).toList();
      LoggingService.database('select_all', 'users', count: users.length);
      return Success(users);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.getAll failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<app_models.User?>> getById(String id) async {
    try {
      final data = await _users.select().eq('id', id).maybeSingle();
      if (data == null) {
        return const Success(null);
      }
      LoggingService.database('select', 'users');
      return Success(_mapToUser(data));
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.getById failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<app_models.User>> create(app_models.User user) async {
    try {
      await _users.insert({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'role': RoleConstants.roleEnumToDb(user.role),
        'society_ids': user.societyIds,
        'bio': user.bio,
        'phone': user.phone,
        'profile_image_url': user.profileImageUrl,
        'joined_date': user.joinedDate.toIso8601String(),
      });
      LoggingService.database('insert', 'users');
      return Success(user);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.create failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<app_models.User>> update(String id, Map<String, dynamic> data) async {
    try {
      final updateData = <String, dynamic>{};

      if (data['name'] != null) updateData['name'] = data['name'];
      if (data['bio'] != null) updateData['bio'] = data['bio'];
      if (data['phone'] != null) updateData['phone'] = data['phone'];
      if (data['profile_image_url'] != null) updateData['profile_image_url'] = data['profile_image_url'];
      if (data['role'] != null) updateData['role'] = data['role'];

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _users.update(updateData).eq('id', id);

      final result = await getById(id);
      return result.when(
        success: (user) {
          if (user != null) {
            LoggingService.database('update', 'users');
            return Success(user);
          }
          return const Failure('User not found after update');
        },
        failure: (message, error) => Failure(message, error: error),
      );
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.update failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _users.delete().eq('id', id);
      LoggingService.database('delete', 'users');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.delete failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get users by role
  Future<Result<List<app_models.User>>> getByRole(app_models.UserRole role) async {
    try {
      final roleStr = role.toString().split('.').last;
      final data = await _users
          .select()
          .eq('role', roleStr)
          .order('name', ascending: true);

      final users = (data as List).map((e) => _mapToUser(e)).toList();
      LoggingService.database('select_by_role', 'users', count: users.length);
      return Success(users);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.getByRole failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Get users by society
  Future<Result<List<app_models.User>>> getBySociety(String societyId) async {
    try {
      final data = await _users
          .select()
          .contains('society_ids', [societyId])
          .order('name', ascending: true);

      final users = (data as List).map((e) => _mapToUser(e)).toList();
      LoggingService.database('select_by_society', 'users', count: users.length);
      return Success(users);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.getBySociety failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Search users by name or email
  Future<Result<List<app_models.User>>> search(String query) async {
    try {
      final data = await _users
          .select()
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .order('name', ascending: true);

      final users = (data as List).map((e) => _mapToUser(e)).toList();
      LoggingService.database('search', 'users', count: users.length);
      return Success(users);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.search failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Update user's society memberships
  Future<Result<void>> updateSocieties(String userId, List<String> societyIds) async {
    try {
      await _users.update({'society_ids': societyIds}).eq('id', userId);
      LoggingService.database('update_societies', 'users');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.updateSocieties failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
    }
  }

  /// Update user role (admin only)
  Future<Result<void>> updateRole(String userId, app_models.UserRole newRole) async {
    try {
      final roleStr = newRole.toString().split('.').last;
      await _users.update({'role': roleStr}).eq('id', userId);
      LoggingService.database('update_role', 'users');
      return const Success(null);
    } catch (e, stackTrace) {
      LoggingService.error('UserRepository.updateRole failed', e, stackTrace);
      return Failure(e.toString(), error: e, stackTrace: stackTrace);
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
