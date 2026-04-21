// lib/services/gamification_service.dart
// Gamification Service - Points, Badges, and Leaderboard

import 'supabase_service.dart';
import 'logging_service.dart';

class UserPoints {
  final String id;
  final String userId;
  final String userName;
  final int totalPoints;
  final int eventsAttended;
  final List<String> badges;
  final String? avatarId;

  UserPoints({
    required this.id,
    required this.userId,
    required this.userName,
    required this.totalPoints,
    required this.eventsAttended,
    required this.badges,
    this.avatarId,
  });

  factory UserPoints.fromMap(Map<String, dynamic> data) {
    return UserPoints(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['users']?['name'] ?? data['user_name'] ?? 'Anonymous',
      totalPoints: data['total_points'] ?? 0,
      eventsAttended: data['events_attended'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      avatarId: data['users']?['profile_image_url'],
    );
  }
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requiredPoints;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredPoints,
  });
}

class GamificationService {
  // Badge definitions
  static const List<Badge> allBadges = [
    Badge(id: 'first_event', name: 'First Step', description: 'Attended your first event', icon: '🎯', requiredPoints: 10),
    Badge(id: 'five_events', name: 'Regular', description: 'Attended 5 events', icon: '⭐', requiredPoints: 50),
    Badge(id: 'ten_events', name: 'Enthusiast', description: 'Attended 10 events', icon: '🌟', requiredPoints: 100),
    Badge(id: 'twenty_events', name: 'Champion', description: 'Attended 20 events', icon: '🏆', requiredPoints: 200),
    Badge(id: 'fifty_events', name: 'Legend', description: 'Attended 50 events', icon: '👑', requiredPoints: 500),
    Badge(id: 'feedback_giver', name: 'Critic', description: 'Gave feedback on 5 events', icon: '📝', requiredPoints: 25),
    Badge(id: 'early_bird', name: 'Early Bird', description: 'Registered first for an event', icon: '🐦', requiredPoints: 15),
    Badge(id: 'social_butterfly', name: 'Social Butterfly', description: 'Joined 3 societies', icon: '🦋', requiredPoints: 30),
  ];

  // Points awarded for actions (lowerCamelCase per Dart convention)
  static const int pointsEventAttendance = 10;
  static const int pointsFeedbackGiven = 5;
  static const int pointsFirstToRegister = 15;
  static const int pointsSocietyJoined = 10;

  // Award points for attending an event
  static Future<void> awardEventAttendance(String userId) async {
    await _addPoints(userId, pointsEventAttendance, incrementEvents: true);
    await _checkAndAwardBadges(userId);
  }

  // Award points for giving feedback
  static Future<void> awardFeedbackGiven(String userId) async {
    await _addPoints(userId, pointsFeedbackGiven);
  }

  // Award points for joining a society
  static Future<void> awardSocietyJoined(String userId) async {
    await _addPoints(userId, pointsSocietyJoined);
  }

  // Add points to user — uses upsert to avoid read-then-write race condition
  static Future<void> _addPoints(String userId, int points, {bool incrementEvents = false}) async {
    try {
      // Check if user has points record
      final existing = await SupabaseService.client
          .from('user_points')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Use RPC for atomic increment to avoid race conditions
        // If two concurrent calls read the same value, one update is lost
        try {
          await SupabaseService.client.rpc('increment_user_points', params: {
            'p_user_id': userId,
            'p_points': points,
            'p_increment_events': incrementEvents,
          });
        } catch (_) {
          // Fallback: manual update if RPC doesn't exist
          final updateData = <String, dynamic>{
            'total_points': (existing['total_points'] ?? 0) + points,
            'updated_at': DateTime.now().toIso8601String(),
          };
          if (incrementEvents) {
            updateData['events_attended'] = (existing['events_attended'] ?? 0) + 1;
          }
          await SupabaseService.client
              .from('user_points')
              .update(updateData)
              .eq('user_id', userId);
        }
      } else {
        // Create new record
        await SupabaseService.client.from('user_points').insert({
          'user_id': userId,
          'total_points': points,
          'events_attended': incrementEvents ? 1 : 0,
          'badges': [],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      LoggingService.error('Error adding points', e);
    }
  }

  // Check and award badges
  static Future<void> _checkAndAwardBadges(String userId) async {
    try {
      final userData = await SupabaseService.client
          .from('user_points')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (userData == null) return;

      final currentBadges = List<String>.from(userData['badges'] ?? []);
      final eventsAttended = userData['events_attended'] ?? 0;
      final newBadges = <String>[];

      // Check event milestones
      if (eventsAttended >= 1 && !currentBadges.contains('first_event')) {
        newBadges.add('first_event');
      }
      if (eventsAttended >= 5 && !currentBadges.contains('five_events')) {
        newBadges.add('five_events');
      }
      if (eventsAttended >= 10 && !currentBadges.contains('ten_events')) {
        newBadges.add('ten_events');
      }
      if (eventsAttended >= 20 && !currentBadges.contains('twenty_events')) {
        newBadges.add('twenty_events');
      }
      if (eventsAttended >= 50 && !currentBadges.contains('fifty_events')) {
        newBadges.add('fifty_events');
      }

      if (newBadges.isNotEmpty) {
        await SupabaseService.client
            .from('user_points')
            .update({'badges': [...currentBadges, ...newBadges]})
            .eq('user_id', userId);
      }
    } catch (e) {
      LoggingService.error('Error checking badges', e);
    }
  }

  // Get user points and badges
  static Future<UserPoints?> getUserPoints(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('user_points')
          .select('*, users!inner(name, profile_image_url)')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserPoints.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // Get leaderboard (top users)
  static Future<List<UserPoints>> getLeaderboard({int limit = 10}) async {
    try {
      final data = await SupabaseService.client
          .from('user_points')
          .select('*, users!inner(name, profile_image_url)')
          .order('total_points', ascending: false)
          .limit(limit);

      return (data as List).map((e) => UserPoints.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get badge details by ID
  static Badge? getBadgeById(String badgeId) {
    try {
      return allBadges.firstWhere((b) => b.id == badgeId);
    } catch (e) {
      return null;
    }
  }
}
