// lib/services/committee_service.dart
// Event Committee Management Service

import 'supabase_service.dart';
import 'logging_service.dart';

class CommitteeMember {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String role; // 'head', 'coordinator', 'volunteer'
  final String? responsibilities;
  final DateTime joinedAt;

  CommitteeMember({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.role,
    this.responsibilities,
    required this.joinedAt,
  });

  factory CommitteeMember.fromMap(Map<String, dynamic> data) {
    return CommitteeMember(
      id: data['id'] ?? '',
      eventId: data['event_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['users']?['name'] ?? 'Unknown',
      userImageUrl: data['users']?['profile_image_url'],
      role: data['role'] ?? 'volunteer',
      responsibilities: data['responsibilities'],
      joinedAt: DateTime.tryParse(data['joined_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get roleDisplay {
    switch (role) {
      case 'head': return '👑 Head';
      case 'coordinator': return '📋 Coordinator';
      case 'volunteer': return '🙋 Volunteer';
      default: return role;
    }
  }

  int get rolePriority {
    switch (role) {
      case 'head': return 0;
      case 'coordinator': return 1;
      case 'volunteer': return 2;
      default: return 3;
    }
  }
}

class CommitteeService {
  /// Add a member to the committee
  static Future<bool> addMember({
    required String eventId,
    required String userId,
    required String role,
    String? responsibilities,
  }) async {
    try {
      await SupabaseService.client.from('event_committees').upsert({
        'event_id': eventId,
        'user_id': userId,
        'role': role,
        'responsibilities': responsibilities,
        'joined_at': DateTime.now().toIso8601String(),
      }, onConflict: 'event_id,user_id');
      return true;
    } catch (e) {
      LoggingService.error('Error adding committee member', e);
      return false;
    }
  }

  /// Remove a member from the committee
  static Future<bool> removeMember(String eventId, String userId) async {
    try {
      await SupabaseService.client
          .from('event_committees')
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      LoggingService.error('Error removing committee member', e);
      return false;
    }
  }

  /// Update member role or responsibilities
  static Future<bool> updateMember({
    required String eventId,
    required String userId,
    String? role,
    String? responsibilities,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (role != null) updateData['role'] = role;
      if (responsibilities != null) updateData['responsibilities'] = responsibilities;

      await SupabaseService.client
          .from('event_committees')
          .update(updateData)
          .eq('event_id', eventId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      LoggingService.error('Error updating committee member', e);
      return false;
    }
  }

  /// Get all committee members for an event
  static Future<List<CommitteeMember>> getEventCommittee(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_committees')
          .select('*, users(name, profile_image_url)')
          .eq('event_id', eventId)
          .order('joined_at', ascending: true);

      final members = (data as List).map((e) => CommitteeMember.fromMap(e)).toList();
      // Sort by role priority
      members.sort((a, b) => a.rolePriority.compareTo(b.rolePriority));
      return members;
    } catch (e) {
      LoggingService.error('Error fetching committee', e);
      return [];
    }
  }

  /// Get committee member count
  static Future<int> getCommitteeCount(String eventId) async {
    try {
      final data = await SupabaseService.client
          .from('event_committees')
          .select('id')
          .eq('event_id', eventId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user is a committee member
  static Future<CommitteeMember?> getUserCommitteeRole(String eventId, String userId) async {
    try {
      final data = await SupabaseService.client
          .from('event_committees')
          .select('*, users(name, profile_image_url)')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return data != null ? CommitteeMember.fromMap(data) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get all committees user is part of
  static Future<List<CommitteeMember>> getUserCommittees(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('event_committees')
          .select('*, events(title, date)')
          .eq('user_id', userId)
          .order('joined_at', ascending: false);

      return (data as List).map((e) => CommitteeMember.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
