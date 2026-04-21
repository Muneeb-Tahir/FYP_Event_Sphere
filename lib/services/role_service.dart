// lib/services/role_service.dart
// Secure role management service using RPC

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import '../constants/role_constants.dart';

/// Service for managing user roles securely via RPC
class RoleService {
  static final _supabase = Supabase.instance.client;

  /// Change a user's role via secure RPC
  /// Throws PostgrestException on failure with detailed error message
  static Future<void> changeUserRole(String targetUserId, String newRole) async {
    try {
      await _supabase.rpc(
        'change_user_role',
        params: {
          'target_user_id': targetUserId,
          'new_role': newRole,
        },
      );
    } on PostgrestException catch (e) {
      // Re-throw with cleaner message
      throw Exception(e.message);
    }
  }

  /// Submit a role upgrade request
  static Future<void> requestRoleUpgrade({
    required String requestedRole,
    String? reason,
  }) async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    // Only allow requesting vice_president or president
    if (requestedRole != RoleConstants.vicePresident &&
        requestedRole != RoleConstants.president) {
      throw Exception('Can only request vice_president or president roles');
    }

    await _supabase.from('role_requests').insert({
      'user_id': currentUser.id,
      'requested_role': requestedRole,
      'reason': reason,
    });
  }

  /// Get pending role requests (for admins)
  static Future<List<RoleRequest>> getPendingRequests() async {
    final response = await _supabase
        .from('role_requests')
        .select('*, users!role_requests_user_id_fkey(id, name, email, role)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List).map((json) => RoleRequest.fromJson(json)).toList();
  }

  /// Get all role requests (for admins)
  static Future<List<RoleRequest>> getAllRequests() async {
    final response = await _supabase
        .from('role_requests')
        .select('*, users!role_requests_user_id_fkey(id, name, email, role)')
        .order('created_at', ascending: false);

    return (response as List).map((json) => RoleRequest.fromJson(json)).toList();
  }

  /// Get current user's role requests
  static Future<List<RoleRequest>> getMyRequests() async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) return [];

    final response = await _supabase
        .from('role_requests')
        .select()
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    return (response as List).map((json) => RoleRequest.fromJson(json)).toList();
  }

  /// Approve a role request (admin only)
  static Future<void> approveRequest(String requestId) async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    // Get the request details
    final requestResponse = await _supabase
        .from('role_requests')
        .select()
        .eq('id', requestId)
        .single();

    final request = RoleRequest.fromJson(requestResponse);

    // Change the user's role via RPC
    await changeUserRole(request.userId, request.requestedRole);

    // Update request status
    await _supabase.from('role_requests').update({
      'status': 'approved',
      'reviewed_by': currentUser.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Reject a role request (admin only)
  static Future<void> rejectRequest(String requestId) async {
    final currentUser = AuthService.getCurrentUser();
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    await _supabase.from('role_requests').update({
      'status': 'rejected',
      'reviewed_by': currentUser.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Get role change audit log (admin only)
  static Future<List<RoleChange>> getRoleChangeLog({int limit = 50}) async {
    final response = await _supabase
        .from('role_changes')
        .select('*, target:users!role_changes_target_user_fkey(name, email), changer:users!role_changes_changed_by_fkey(name)')
        .order('changed_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => RoleChange.fromJson(json)).toList();
  }
}

/// Model for role upgrade requests
class RoleRequest {
  final String id;
  final String userId;
  final String requestedRole;
  final String? reason;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? userProfile;

  RoleRequest({
    required this.id,
    required this.userId,
    required this.requestedRole,
    this.reason,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.userProfile,
  });

  factory RoleRequest.fromJson(Map<String, dynamic> json) {
    return RoleRequest(
      id: json['id'],
      userId: json['user_id'],
      requestedRole: json['requested_role'],
      reason: json['reason'],
      status: json['status'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      userProfile: json['users'],
    );
  }

  String get userName => userProfile?['name'] ?? 'Unknown';
  String get userEmail => userProfile?['email'] ?? '';
  String get currentRole => userProfile?['role'] ?? 'student';

  String get displayRequestedRole => RoleConstants.getDisplayName(requestedRole);
  String get displayCurrentRole => RoleConstants.getDisplayName(currentRole);

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

/// Model for role change audit log
class RoleChange {
  final String id;
  final String targetUserId;
  final String oldRole;
  final String newRole;
  final String changedBy;
  final DateTime changedAt;
  final Map<String, dynamic>? targetProfile;
  final Map<String, dynamic>? changerProfile;

  RoleChange({
    required this.id,
    required this.targetUserId,
    required this.oldRole,
    required this.newRole,
    required this.changedBy,
    required this.changedAt,
    this.targetProfile,
    this.changerProfile,
  });

  factory RoleChange.fromJson(Map<String, dynamic> json) {
    return RoleChange(
      id: json['id'],
      targetUserId: json['target_user'],
      oldRole: json['old_role'],
      newRole: json['new_role'],
      changedBy: json['changed_by'],
      changedAt: DateTime.parse(json['changed_at']),
      targetProfile: json['target'],
      changerProfile: json['changer'],
    );
  }

  String get targetName => targetProfile?['name'] ?? 'Unknown';
  String get targetEmail => targetProfile?['email'] ?? '';
  String get changerName => changerProfile?['name'] ?? 'System';

  String get displayOldRole => RoleConstants.getDisplayName(oldRole);
  String get displayNewRole => RoleConstants.getDisplayName(newRole);
}
