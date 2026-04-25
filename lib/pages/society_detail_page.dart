// lib/pages/society_detail_page.dart
// Society Detail - View and manage members with roles (President/Admin)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/society_service.dart';
import '../services/user_service.dart';
import '../services/avatar_service.dart';
import '../services/event_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../constants/app_theme.dart';

class SocietyDetailPage extends ConsumerStatefulWidget {
  final String societyId;
  const SocietyDetailPage({super.key, required this.societyId});

  @override
  ConsumerState<SocietyDetailPage> createState() => _SocietyDetailPageState();
}

class _SocietyDetailPageState extends ConsumerState<SocietyDetailPage> {
  Society? _society;
  List<SocietyMember> _members = [];
  List<Event> _events = [];
  bool _loading = true;
  User? _currentUser;

  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final society = await SocietyService.getSociety(widget.societyId);
      final members = await SocietyService.getSocietyMembers(widget.societyId);
      final events = await EventService.getEventsBySociety(widget.societyId);
      setState(() { _society = society; _members = members; _events = events; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load: $e');
    }
  }

  bool get _canManageMembers {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin || _currentUser!.role == UserRole.superAdmin) return true;
    if ((_currentUser!.role == UserRole.president || _currentUser!.role == UserRole.vicePresident) && _society?.presidentId == _currentUser!.id) return true;
    return false;
  }

  bool get _isAdmin => _currentUser?.role == UserRole.admin || _currentUser?.role == UserRole.superAdmin;

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  // ===================== LEAVE SOCIETY =====================
  Future<void> _leaveSociety() async {
    if (_currentUser == null) return;

    // Check if user can leave based on their role
    final result = await SocietyService.canLeaveSociety(widget.societyId, _currentUser!.id);

    if (result['canLeave'] != true) {
      // Show error message explaining why they can't leave
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cannot Leave', style: TextStyle(color: Colors.orange)),
            ],
          ),
          content: Text(
            result['reason'] ?? 'You cannot leave this society at this time.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm leave dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Leave Society', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to leave "${_society?.name ?? 'this society'}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SocietyService.removeMember(widget.societyId, _currentUser!.id);
        _showSuccess('You have left the society');
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showError('Failed to leave: $e');
      }
    }
  }

  Future<void> _navigateToCreateEvent() async {
    // Navigate to add event page with society pre-selected
    final result = await Navigator.pushNamed(
      context,
      '/add-event',
      arguments: {'societyId': widget.societyId, 'societyName': _society?.name},
    );

    // Refresh data when returning (in case event was created)
    if (result == true || result == null) {
      _loadData();
    }
  }

  Future<void> _addMember() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get ALL users (not just students) for admin
    final allUsers = await UserService.getAllUsers();
    final memberIds = _members.map((m) => m.userId).toSet();
    final available = allUsers.where((u) => !memberIds.contains(u.id)).toList();

    if (available.isEmpty) {
      _showError('No users available to add');
      return;
    }

    // Multi-select dialog
    final selectedUsers = await showDialog<List<String>>(
      context: context,
      builder: (context) => _BulkAddMembersDialog(
        availableUsers: available,
        isDark: isDark,
        getRoleColor: _getRoleColor,
      ),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      try {
        int successCount = 0;
        for (final userId in selectedUsers) {
          try {
            await SocietyService.addMember(widget.societyId, userId);
            successCount++;
          } catch (e) {
            // Continue with next user if one fails
          }
        }
        _showSuccess('$successCount member(s) added!');
        _loadData();
      } catch (e) {
        _showError('$e');
      }
    }
  }


  Future<void> _changeMemberRole(SocietyMember member) async {

    // Determine current role based on societyRole field
    String currentRole = member.societyRole;
    // If this member is the society president (based on society.president_id), treat as president
    if (_society?.presidentId == member.userId) {
      currentRole = 'president';
    }

    final roles = [
      {'key': 'member', 'label': 'Member', 'color': Colors.blue, 'icon': Icons.person},
      {'key': 'vice_president', 'label': 'Vice President', 'color': Colors.purple, 'icon': Icons.star_half},
      {'key': 'president', 'label': 'President', 'color': Colors.orange, 'icon': Icons.stars},
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Change Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(member.userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Current: ${currentRole.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}',
                style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
            const SizedBox(height: 16),
            ...roles.map((role) {
              final isSelected = role['key'] == currentRole;
              final roleColor = role['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  tileColor: isSelected ? roleColor.withOpacity(0.15) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isSelected ? roleColor : const Color(0xFF3D3557), width: isSelected ? 2 : 1),
                  ),
                  leading: Icon(role['icon'] as IconData, color: roleColor),
                  title: Text(role['label'] as String, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle, color: roleColor) : null,
                  onTap: isSelected ? null : () => Navigator.pop(context, role['key'] as String),
                ),
              );
            }),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );

    if (selected != null && selected != currentRole) {
      try {
        // Update the member's role in society_members table
        await SocietyService.updateMemberRole(widget.societyId, member.userId, selected);

        // If promoting to president, update society.president_id
        if (selected == 'president') {
          await SocietyService.assignPresident(widget.societyId, member.userId);
        }

        // If demoting FROM president, clear society.president_id
        if (currentRole == 'president' && selected != 'president') {
          await SocietyService.clearPresident(widget.societyId);
        }

        final roleLabel = selected.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        _showSuccess('${member.userName} is now $roleLabel!');
        _loadData();
      } catch (e) {
        _showError('Failed to change role: $e');
      }
    }
  }



  Future<void> _removeMember(SocietyMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Remove Member', style: TextStyle(color: Colors.red)),
        content: Text('Remove ${member.userName} from this society?', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Remove', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SocietyService.removeMember(widget.societyId, member.userId);
        _showSuccess('Member removed');
        _loadData();
      } catch (e) {
        _showError('$e');
      }
    }
  }

  // Delete multiple selected members
  Future<void> _deleteSelectedMembers() async {
    if (_selectedMemberIds.isEmpty) return;

    final count = _selectedMemberIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Remove Members', style: TextStyle(color: Colors.red)),
        content: Text('Remove $count selected member${count > 1 ? 's' : ''} from this society?',
          style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove $count', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      int successCount = 0;
      int failCount = 0;

      for (final userId in _selectedMemberIds.toList()) {
        try {
          await SocietyService.removeMember(widget.societyId, userId);
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      _selectedMemberIds.clear();
      _isSelectionMode = false;

      if (failCount == 0) {
        _showSuccess('$successCount member${successCount > 1 ? 's' : ''} removed');
      } else {
        _showError('Removed $successCount, failed $failCount');
      }

      _loadData();
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'president': return Colors.orange;
      case 'student': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'President': return Icons.stars;
      case 'Vice President': return Icons.star_half;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [AppTheme.primaryColor, AppTheme.accentColor, Colors.orange, Colors.teal];
    final color = _society != null ? colors[_society!.name.hashCode.abs() % colors.length] : AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          : _society == null
              ? const Center(child: Text('Society not found', style: TextStyle(color: Colors.white)))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: color,
                      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      actions: [
                        // Show Leave button only if current user is a member
                        if (_currentUser != null && _members.any((m) => m.userId == _currentUser!.id))
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Colors.white),
                            tooltip: 'Leave Society',
                            onPressed: _leaveSociety,
                          ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_society!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                          ),
                          child: Center(child: Icon(Icons.groups, color: Colors.white.withOpacity(0.2), size: 100)),
                        ),
                      ),
                    ),

                    // Stats
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Members', _members.length, Icons.people, isDark),
                            _buildStat('Events', _events.length, Icons.event, isDark),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Spacer(),
                            // Selection mode toggle for admins
                            if (_canManageMembers && _members.length > 1)
                              IconButton(
                                onPressed: () => setState(() {
                                  _isSelectionMode = !_isSelectionMode;
                                  if (!_isSelectionMode) _selectedMemberIds.clear();
                                }),
                                icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist,
                                  color: _isSelectionMode ? Colors.red : const Color(0xFF9D4EDD)),
                                tooltip: _isSelectionMode ? 'Cancel Selection' : 'Select Multiple',
                              ),
                            if (_canManageMembers && !_isSelectionMode)
                              TextButton.icon(
                                onPressed: _addMember,
                                icon: const Icon(Icons.person_add, color: Color(0xFF9D4EDD)),
                                label: const Text('Add', style: TextStyle(color: Color(0xFF9D4EDD))),
                              ),
                            // Select all button
                            if (_isSelectionMode)
                              TextButton(
                                onPressed: () => setState(() {
                                  if (_selectedMemberIds.length == _members.where((m) => m.userId != _society?.presidentId).length) {
                                    _selectedMemberIds.clear();
                                  } else {
                                    _selectedMemberIds.clear();
                                    for (var m in _members) {
                                      if (m.userId != _society?.presidentId) _selectedMemberIds.add(m.userId);
                                    }
                                  }
                                }),
                                child: Text(
                                  _selectedMemberIds.length == _members.where((m) => m.userId != _society?.presidentId).length ? 'Deselect All' : 'Select All',
                                  style: const TextStyle(color: Color(0xFF9D4EDD)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Members List
                    _members.isEmpty
                        ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No members yet', style: TextStyle(color: Color(0xFFB8A9C9))))))
                        : SliverList(delegate: SliverChildBuilderDelegate((context, idx) => _buildMemberTile(_members[idx], isDark), childCount: _members.length)),

                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
      // Floating action buttons
      floatingActionButton: _isSelectionMode && _selectedMemberIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _deleteSelectedMembers,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete, color: Colors.white),
              label: Text('Delete (${_selectedMemberIds.length})', style: const TextStyle(color: Colors.white)),
            )
          : _canManageMembers && !_isSelectionMode
              ? GestureDetector(
                  onTap: _navigateToCreateEvent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: const Color(0xFF9D4EDD).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text('Create Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildStat(String label, int value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF9D4EDD), size: 28),
        const SizedBox(height: 4),
        Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
      ],
    );
  }

  // Helper to build member avatar - supports both custom avatars and network images
  Widget _buildMemberAvatar(SocietyMember member, bool isDark) {
    // Check if it's a custom avatar ID (starts with male_ or female_)
    final avatarId = member.userImage;
    if (avatarId != null && (avatarId.startsWith('male_') || avatarId.startsWith('female_'))) {
      final avatarData = AvatarService.getAvatarById(avatarId);
      if (avatarData != null) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: avatarData.gradient,
          ),
          child: Icon(avatarData.icon, color: Colors.white, size: 24),
        );
      }
    }

    // Check if it's a network URL
    if (avatarId != null && avatarId.isNotEmpty && avatarId.startsWith('http')) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFF9D4EDD).withOpacity(0.2),
        backgroundImage: NetworkImage(avatarId),
      );
    }

    // Default: show first letter of name or email
    final initial = member.userName.isNotEmpty
        ? member.userName[0].toUpperCase()
        : (member.userEmail.isNotEmpty ? member.userEmail[0].toUpperCase() : '?');

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF9D4EDD).withOpacity(0.2),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF9D4EDD),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildMemberTile(SocietyMember member, bool isDark) {
    // Determine the role - prefer society.president_id for president, then use societyRole
    String effectiveRole = member.societyRole;
    if (_society?.presidentId == member.userId) {
      effectiveRole = 'president';
    }

    String? roleLabel;
    Color? roleColor;

    if (effectiveRole == 'president') {
      roleLabel = 'President';
      roleColor = Colors.orange;
    } else if (effectiveRole == 'vice_president') {
      roleLabel = 'Vice President';
      roleColor = Colors.purple;
    }
    // 'member' role doesn't show a badge

    final isSelected = _selectedMemberIds.contains(member.userId);
    final canSelect = effectiveRole != 'president'; // President cannot be deleted

    return GestureDetector(
      onTap: _isSelectionMode && canSelect
        ? () => setState(() {
            if (isSelected) {
              _selectedMemberIds.remove(member.userId);
            } else {
              _selectedMemberIds.add(member.userId);
            }
          })
        : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
            ? Colors.red.withOpacity(0.2)
            : const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
            ? Border.all(color: Colors.red, width: 2)
            : (roleColor != null ? Border.all(color: roleColor, width: 2) : Border.all(color: const Color(0xFF3D3557).withOpacity(0.5))),
        ),
        child: Row(
          children: [
            // Checkbox in selection mode
            if (_isSelectionMode) ...[
              if (canSelect)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _selectedMemberIds.add(member.userId);
                    } else {
                      _selectedMemberIds.remove(member.userId);
                    }
                  }),
                  activeColor: Colors.red,
                )
              else
                // Disabled checkbox for president
                const SizedBox(width: 48, child: Icon(Icons.lock, color: Colors.grey, size: 20)),
            ],
            _buildMemberAvatar(member, isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(member.userName, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis)),
                      if (roleLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: roleColor!.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text(roleLabel, style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (_isAdmin) Text(member.userEmail, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                ],
              ),
            ),
            // Hide action buttons in selection mode
            if (!_isSelectionMode) ...[
              if (_isAdmin) ...[
                // Role change button for admin
                IconButton(
                  onPressed: () => _changeMemberRole(member),
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF9D4EDD), size: 20),
                  tooltip: 'Change Role',
                ),
              ],
              if (_canManageMembers && effectiveRole != 'president')
                IconButton(
                  onPressed: () => _removeMember(member),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// Bulk Add Members Dialog with multi-select
class _BulkAddMembersDialog extends StatefulWidget {
  final List<UserInfo> availableUsers;
  final bool isDark;
  final Color Function(String) getRoleColor;

  const _BulkAddMembersDialog({
    required this.availableUsers,
    required this.isDark,
    required this.getRoleColor,
  });

  @override
  State<_BulkAddMembersDialog> createState() => _BulkAddMembersDialogState();
}

class _BulkAddMembersDialogState extends State<_BulkAddMembersDialog> {
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';

  List<UserInfo> get _filteredUsers {
    if (_searchQuery.isEmpty) return widget.availableUsers;
    final query = _searchQuery.toLowerCase();
    return widget.availableUsers.where((u) =>
      u.name.toLowerCase().contains(query) ||
      u.email.toLowerCase().contains(query)
    ).toList();
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: widget.isDark ? DarkColors.surface : Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Members', style: TextStyle(color: widget.isDark ? DarkColors.textPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              hintStyle: TextStyle(color: widget.isDark ? DarkColors.textSecondary : Colors.grey),
              prefixIcon: Icon(Icons.search, color: widget.isDark ? DarkColors.textSecondary : Colors.grey),
              filled: true,
              fillColor: widget.isDark ? DarkColors.background : Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: TextStyle(color: widget.isDark ? DarkColors.textPrimary : Colors.black),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          if (_selectedUserIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selectedUserIds.length} user(s) selected',
                style: TextStyle(fontSize: 12, color: widget.isDark ? DarkColors.primary : AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _filteredUsers.isEmpty
            ? Center(child: Text('No users found', style: TextStyle(color: widget.isDark ? DarkColors.textSecondary : Colors.grey)))
            : ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, idx) {
                  final user = _filteredUsers[idx];
                  final isSelected = _selectedUserIds.contains(user.id);
                  final roleColor = widget.getRoleColor(user.role.toString().split('.').last);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedUserIds.add(user.id);
                        } else {
                          _selectedUserIds.remove(user.id);
                        }
                      });
                    },
                    activeColor: widget.isDark ? DarkColors.primary : AppTheme.primaryColor,
                    secondary: CircleAvatar(
                      backgroundColor: roleColor.withOpacity(0.2),
                      child: Text(user.name[0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(user.name, style: TextStyle(color: widget.isDark ? DarkColors.textPrimary : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Row(
                      children: [
                        Flexible(child: Text(user.email, style: TextStyle(color: widget.isDark ? DarkColors.textSecondary : AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(user.role.toString().split('.').last, style: TextStyle(fontSize: 9, color: roleColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: widget.isDark ? DarkColors.textSecondary : Colors.grey)),
        ),
        if (_selectedUserIds.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _selectedUserIds.clear()),
            child: const Text('Clear All', style: TextStyle(color: Colors.orange)),
          ),
        ElevatedButton.icon(
          onPressed: _selectedUserIds.isEmpty ? null : () => Navigator.pop(context, _selectedUserIds.toList()),
          icon: const Icon(Icons.group_add, size: 18),
          label: Text('Add ${_selectedUserIds.isEmpty ? "" : "(${_selectedUserIds.length})"}'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isDark ? DarkColors.primary : AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
