// lib/providers/society_provider.dart
// Riverpod providers for society management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/society_service.dart';

/// Provider for all societies list
final societiesProvider = FutureProvider<List<Society>>((ref) async {
  return await SocietyService.getAllSocieties();
});

/// Provider for a single society by ID
final societyProvider = FutureProvider.family<Society?, String>((ref, societyId) async {
  return await SocietyService.getSociety(societyId);
});

/// Provider for societies where user is president
final presidentSocietiesProvider = FutureProvider.family<List<Society>, String>((ref, presidentId) async {
  return await SocietyService.getSocietiesByPresident(presidentId);
});

/// Provider for user's joined societies
final userSocietiesProvider = FutureProvider.family<List<Society>, String>((ref, userId) async {
  return await SocietyService.getUserSocieties(userId);
});

/// Provider for society member count
final societyMemberCountProvider = FutureProvider.family<int, String>((ref, societyId) async {
  return await SocietyService.getMemberCount(societyId);
});

/// Provider for society members list
final societyMembersProvider = FutureProvider.family<List<SocietyMember>, String>((ref, societyId) async {
  return await SocietyService.getSocietyMembers(societyId);
});

/// State notifier for society operations
class SocietyNotifier extends StateNotifier<AsyncValue<List<Society>>> {
  SocietyNotifier() : super(const AsyncValue.loading()) {
    loadSocieties();
  }

  Future<void> loadSocieties() async {
    state = const AsyncValue.loading();
    try {
      final societies = await SocietyService.getAllSocieties();
      state = AsyncValue.data(societies);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await loadSocieties();
  }

  Future<bool> joinSociety(String societyId, String userId) async {
    try {
      await SocietyService.addMember(societyId, userId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> leaveSociety(String societyId, String userId) async {
    try {
      await SocietyService.removeMember(societyId, userId);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Society state notifier provider
final societyNotifierProvider = StateNotifierProvider<SocietyNotifier, AsyncValue<List<Society>>>((ref) {
  return SocietyNotifier();
});

/// Check if user is member of society
final isSocietyMemberProvider = FutureProvider.family<bool, ({String societyId, String userId})>((ref, params) async {
  return await SocietyService.isMember(params.societyId, params.userId);
});

/// Get member's role in society
final memberRoleProvider = FutureProvider.family<String?, ({String societyId, String userId})>((ref, params) async {
  final member = await SocietyService.getMemberRole(params.societyId, params.userId);
  return member?.societyRole;
});
