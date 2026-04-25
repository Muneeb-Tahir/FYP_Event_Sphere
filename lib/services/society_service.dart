// lib/services/society_service.dart
// Society Management Service with Supabase

import 'supabase_service.dart';

class Society {
  final String id;
  final String name;
  final String? description;
  final String? presidentId;
  final String? logoUrl;
  final String? category;
  final DateTime createdAt;
  final int memberCount;

  Society({
    required this.id,
    required this.name,
    this.description,
    this.presidentId,
    this.logoUrl,
    this.category,
    DateTime? createdAt,
    this.memberCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Society.fromMap(Map<String, dynamic> data, {int members = 0}) {
    return Society(
      id: data['id'],
      name: data['name'] ?? 'Unknown Society',
      description: data['description'],
      presidentId: data['president_id'],
      logoUrl: data['logo_url'],
      category: data['category'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      memberCount: members,
    );
  }
}

class SocietyMember {
  final String id;
  final String societyId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userImage;
  final DateTime joinedAt;
  final String societyRole; // member, vice_president, president

  SocietyMember({
    required this.id,
    required this.societyId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userImage,
    required this.joinedAt,
    this.societyRole = 'member',
  });
}

class SocietyService {
  // ===================== GET ALL SOCIETIES =====================
  static Future<List<Society>> getAllSocieties() async {
    final data = await SupabaseService.client
        .from('societies')
        .select('*, society_members(count)')
        .order('name');

    return (data as List).map((item) {
      final count = _extractCount(item);
      return Society.fromMap(item, members: count);
    }).toList();
  }

  /// Extract member count from joined count query result
  static int _extractCount(Map<String, dynamic> item) {
    try {
      final members = item['society_members'];
      if (members is List && members.isNotEmpty) {
        return members[0]['count'] as int? ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // ===================== GET SOCIETY BY ID =====================
  static Future<Society?> getSociety(String societyId) async {
    try {
      final data = await SupabaseService.client
          .from('societies')
          .select()
          .eq('id', societyId)
          .single();

      final count = await getMemberCount(societyId);
      return Society.fromMap(data, members: count);
    } catch (e) {
      return null;
    }
  }

  // ===================== CREATE SOCIETY (Admin only) =====================
  static Future<void> createSociety({
    required String name,
    String? description,
    String? presidentId,
    String? logoUrl,
    String? category,
  }) async {
    await SupabaseService.client.from('societies').insert({
      'name': name,
      'description': description,
      'president_id': presidentId,
      'logo_url': logoUrl,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ===================== UPDATE SOCIETY =====================
  static Future<void> updateSociety(String societyId, Map<String, dynamic> updates) async {
    final data = <String, dynamic>{};
    if (updates['name'] != null) data['name'] = updates['name'];
    if (updates.containsKey('description')) data['description'] = updates['description'];
    if (updates.containsKey('president_id')) data['president_id'] = updates['president_id'];
    if (updates.containsKey('logo_url')) data['logo_url'] = updates['logo_url'];

    await SupabaseService.client.from('societies').update(data).eq('id', societyId);
  }

  // ===================== DELETE SOCIETY (Admin only) =====================
  static Future<void> deleteSociety(String societyId) async {
    // First remove all members
    await SupabaseService.client.from('society_members').delete().eq('society_id', societyId);
    // Then delete society
    await SupabaseService.client.from('societies').delete().eq('id', societyId);
  }

  // ===================== ASSIGN PRESIDENT =====================
  static Future<void> assignPresident(String societyId, String userId) async {
    await SupabaseService.client
        .from('societies')
        .update({'president_id': userId})
        .eq('id', societyId);
  }

  // ===================== CLEAR PRESIDENT (Demote) =====================
  static Future<void> clearPresident(String societyId) async {
    await SupabaseService.client
        .from('societies')
        .update({'president_id': null})
        .eq('id', societyId);
  }


  // ===================== GET SOCIETIES BY PRESIDENT =====================
  static Future<List<Society>> getSocietiesByPresident(String presidentId) async {
    final data = await SupabaseService.client
        .from('societies')
        .select('*, society_members(count)')
        .eq('president_id', presidentId)
        .order('name');

    return (data as List).map((item) {
      final count = _extractCount(item);
      return Society.fromMap(item, members: count);
    }).toList();
  }

  // ===================== MEMBER MANAGEMENT =====================

  // Get member count
  static Future<int> getMemberCount(String societyId) async {
    try {
      final data = await SupabaseService.client
          .from('society_members')
          .select('id')
          .eq('society_id', societyId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Get society members with user details
  static Future<List<SocietyMember>> getSocietyMembers(String societyId) async {
    try {
      final data = await SupabaseService.client
          .from('society_members')
          .select('*, users!inner(name, email, profile_image_url)')
          .eq('society_id', societyId);

      return (data as List).map((item) {
        // Get name, fallback to email prefix if null/empty
        String userName = item['users']['name'] ?? '';
        if (userName.isEmpty && item['users']['email'] != null) {
          userName = item['users']['email'].toString().split('@').first;
        }
        if (userName.isEmpty) userName = 'Unknown';

        return SocietyMember(
          id: item['id'],
          societyId: item['society_id'],
          userId: item['user_id'],
          userName: userName,
          userEmail: item['users']['email'] ?? '',
          userImage: item['users']['profile_image_url'],
          joinedAt: DateTime.tryParse(item['joined_at'] ?? '') ?? DateTime.now(),
          societyRole: item['role'] ?? 'member',
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Update member role in society AND update user's global role
  static Future<void> updateMemberRole(String societyId, String userId, String role) async {
    // Update society_members table
    await SupabaseService.client
        .from('society_members')
        .update({'role': role})
        .eq('society_id', societyId)
        .eq('user_id', userId);

    // Also update the user's global role in users table
    // President/Vice President promotions should reflect globally
    if (role == 'president') {
      await SupabaseService.client
          .from('users')
          .update({'role': 'president'})
          .eq('id', userId);
    } else if (role == 'vice_president') {
      await SupabaseService.client
          .from('users')
          .update({'role': 'vice_president'})
          .eq('id', userId);
    } else if (role == 'member') {
      // When demoting to member, check if they are president/VP of any OTHER society
      // If not, revert their global role to student
      final otherLeaderRoles = await SupabaseService.client
          .from('society_members')
          .select('role')
          .eq('user_id', userId)
          .neq('society_id', societyId)
          .inFilter('role', ['president', 'vice_president']);

      // If they have no other leadership roles, demote to student
      if ((otherLeaderRoles as List).isEmpty) {
        await SupabaseService.client
            .from('users')
            .update({'role': 'student'})
            .eq('id', userId);
      }
    }
  }

  // Add member to society
  static Future<void> addMember(String societyId, String userId) async {
    // Check if already a member
    final existing = await SupabaseService.client
        .from('society_members')
        .select('id')
        .eq('society_id', societyId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('User is already a member of this society');
    }

    await SupabaseService.client.from('society_members').insert({
      'society_id': societyId,
      'user_id': userId,
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  // Remove member from society
  static Future<void> removeMember(String societyId, String userId) async {
    await SupabaseService.client
        .from('society_members')
        .delete()
        .eq('society_id', societyId)
        .eq('user_id', userId);
  }

  // Check if user is member
  static Future<bool> isMember(String societyId, String userId) async {
    try {
      final data = await SupabaseService.client
          .from('society_members')
          .select('id')
          .eq('society_id', societyId)
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's societies
  static Future<List<Society>> getUserSocieties(String userId) async {
    try {
      final memberData = await SupabaseService.client
          .from('society_members')
          .select('society_id')
          .eq('user_id', userId);

      if ((memberData as List).isEmpty) return [];

      final societyIds = memberData.map((m) => m['society_id'] as String).toList();

      final societies = await SupabaseService.client
          .from('societies')
          .select('*, society_members(count)')
          .inFilter('id', societyIds)
          .order('name');

      return (societies as List).map((item) {
        final count = _extractCount(item);
        return Society.fromMap(item, members: count);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ===================== LEAVE SOCIETY VALIDATION =====================

  /// Get member's role in a society
  static Future<SocietyMember?> getMemberRole(String societyId, String userId) async {
    try {
      final data = await SupabaseService.client
          .from('society_members')
          .select('*, users(id, name, email)')
          .eq('society_id', societyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return SocietyMember(
        id: data['id'],
        societyId: data['society_id'],
        userId: data['user_id'],
        societyRole: data['role'] ?? 'member',
        userName: data['users']?['name'] ?? 'Unknown',
        userEmail: data['users']?['email'] ?? '',
        joinedAt: data['joined_at'] != null ? DateTime.parse(data['joined_at']) : DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if society has other leadership (president or admin) besides the given user
  static Future<bool> _hasOtherLeadership(String societyId, String excludeUserId) async {
    try {
      final data = await SupabaseService.client
          .from('society_members')
          .select('id, role')
          .eq('society_id', societyId)
          .neq('user_id', excludeUserId)
          .inFilter('role', ['president', 'admin', 'President', 'Admin']);

      return (data as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if user can leave society based on their role
  /// Returns: {'canLeave': bool, 'reason': String?}
  static Future<Map<String, dynamic>> canLeaveSociety(String societyId, String userId) async {
    final member = await getMemberRole(societyId, userId);

    if (member == null) {
      return {'canLeave': false, 'reason': 'You are not a member of this society'};
    }

    final role = member.societyRole.toLowerCase();

    switch (role) {
      case 'member':
        // Students/members can always leave
        return {'canLeave': true};

      case 'vice-president':
      case 'vp':
        // Vice-President can leave only if there's a president or admin
        final hasLeadership = await _hasOtherLeadership(societyId, userId);
        if (hasLeadership) {
          return {'canLeave': true};
        } else {
          return {
            'canLeave': false,
            'reason': 'Cannot leave: No other leadership exists in this society. Please request admin approval or ensure a replacement is assigned first.'
          };
        }

      case 'president':
        // President cannot leave directly
        return {
          'canLeave': false,
          'reason': 'Presidents cannot leave directly. Please transfer presidency to another member or request admin approval.'
        };

      default:
        return {'canLeave': true};
    }
  }
}
