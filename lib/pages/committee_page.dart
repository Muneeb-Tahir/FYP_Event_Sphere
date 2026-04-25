// lib/pages/committee_page.dart
// Event Committee Management Page

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/committee_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';

class CommitteePage extends ConsumerStatefulWidget {
  final Event event;
  const CommitteePage({super.key, required this.event});

  @override
  ConsumerState<CommitteePage> createState() => _CommitteePageState();
}

class _CommitteePageState extends ConsumerState<CommitteePage> {
  List<CommitteeMember> _members = [];
  bool _loading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = ref.read(currentUserProvider);
    _loadCommittee();
  }

  Future<void> _loadCommittee() async {
    setState(() => _loading = true);
    try {
      final members = await CommitteeService.getEventCommittee(widget.event.id);
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  bool get _canManage {
    if (_currentUser == null) return false;
    return _currentUser!.role == UserRole.admin ||
           _currentUser!.role == UserRole.superAdmin ||
           _currentUser!.role == UserRole.president ||
           _currentUser!.role == UserRole.vicePresident ||
           _currentUser!.id == widget.event.createdBy;
  }

  void _showAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMemberSheet(
        eventId: widget.event.id,
        societyId: widget.event.societyId,
        existingMemberIds: _members.map((m) => m.userId).toList(),
        onMemberAdded: _loadCommittee,
      ),
    );
  }

  void _showEditMemberDialog(CommitteeMember member) {
    String selectedRole = member.role;
    final responsibilitiesController = TextEditingController(text: member.responsibilities);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          title: Text('Edit ${member.userName}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'head', child: Text('👑 Head')),
                  DropdownMenuItem(value: 'coordinator', child: Text('📋 Coordinator')),
                  DropdownMenuItem(value: 'volunteer', child: Text('🙋 Volunteer')),
                ],
                onChanged: (v) => setDialogState(() => selectedRole = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: responsibilitiesController,
                decoration: const InputDecoration(
                  labelText: 'Responsibilities',
                  hintText: 'e.g., Handle registrations',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await CommitteeService.removeMember(widget.event.id, member.userId);
                _loadCommittee();
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await CommitteeService.updateMember(
                  eventId: widget.event.id,
                  userId: member.userId,
                  role: selectedRole,
                  responsibilities: responsibilitiesController.text.trim(),
                );
                _loadCommittee();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        title: const Text(
          'Event Committee',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_canManage)
            IconButton(
              icon: const Icon(Icons.person_add, color: Color(0xFF9D4EDD)),
              onPressed: _showAddMemberDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          : _members.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _loadCommittee,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) => _buildMemberCard(_members[index], isDark),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups, size: 80, color: Color(0xFFB8A9C9)),
          const SizedBox(height: 16),
          const Text(
            'No committee members yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add team members to organize this event',
            style: TextStyle(color: Color(0xFFB8A9C9)),
          ),
          if (_canManage) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                onPressed: _showAddMemberDialog,
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: const Text('Add Member', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard(CommitteeMember member, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _getRoleColor(member.role).withOpacity(0.2),
          backgroundImage: member.userImageUrl != null ? NetworkImage(member.userImageUrl!) : null,
          child: member.userImageUrl == null
              ? Text(member.userName[0].toUpperCase(), style: TextStyle(color: _getRoleColor(member.role), fontWeight: FontWeight.bold, fontSize: 18))
              : null,
        ),
        title: Text(
          member.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(member.roleDisplay, style: TextStyle(fontSize: 12, color: _getRoleColor(member.role), fontWeight: FontWeight.w500)),
            ),
            if (member.responsibilities != null && member.responsibilities!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(member.responsibilities!, style: const TextStyle(fontSize: 13, color: Color(0xFFB8A9C9))),
            ],
          ],
        ),
        trailing: _canManage
            ? IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFFB8A9C9)),
                onPressed: () => _showEditMemberDialog(member),
              )
            : null,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'head': return Colors.amber;
      case 'coordinator': return Colors.blue;
      case 'volunteer': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// Bottom sheet for adding members with search
class AddMemberSheet extends StatefulWidget {
  final String eventId;
  final String societyId;
  final List<String> existingMemberIds;
  final VoidCallback onMemberAdded;

  const AddMemberSheet({
    super.key,
    required this.eventId,
    required this.societyId,
    required this.existingMemberIds,
    required this.onMemberAdded,
  });

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  List<UserInfo> _allUsers = [];
  List<UserInfo> _filteredUsers = [];
  bool _loading = true;
  String _selectedRole = 'volunteer';
  UserInfo? _selectedUser;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _allUsers = users.where((u) => !widget.existingMemberIds.contains(u.id)).toList();
        _filteredUsers = _allUsers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((u) =>
          u.name.toLowerCase().contains(query.toLowerCase()) ||
          u.email.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      if (_selectedUser != null && !_filteredUsers.contains(_selectedUser)) {
        _selectedUser = null;
      }
    });
  }

  Future<void> _addMember() async {
    if (_selectedUser == null) return;

    final success = await CommitteeService.addMember(
      eventId: widget.eventId,
      userId: _selectedUser!.id,
      role: _selectedRole,
    );

    if (success) {
      widget.onMemberAdded();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Committee Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _filterUsers,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9D4EDD)),
              filled: true,
              fillColor: const Color(0xFF0D0B14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD))),
            ),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          else if (_allUsers.isEmpty)
            const Text('No available users to add', style: TextStyle(color: Color(0xFFB8A9C9)))
          else ...[
            const Text('Select a user:', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
            const SizedBox(height: 8),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0B14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D3557)),
                ),
                child: _filteredUsers.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No users match your search', style: TextStyle(color: Color(0xFFB8A9C9)))))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected = _selectedUser?.id == user.id;
                          return InkWell(
                            onTap: () => setState(() => _selectedUser = user),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF9D4EDD).withOpacity(0.2) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: const Color(0xFF3D3557).withOpacity(0.5))),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF9D4EDD).withOpacity(0.3),
                                    backgroundImage: user.profileImageUrl != null ? NetworkImage(user.profileImageUrl!) : null,
                                    child: user.profileImageUrl == null ? Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFFB8A9C9), fontWeight: FontWeight.w600)),
                                        Text(user.email, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                                    child: Text(user.role, style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 10)),
                                  ),
                                  if (isSelected) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: Color(0xFF9D4EDD), size: 20)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Role Selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF1E1B2E),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: const Color(0xFF9D4EDD),
              decoration: InputDecoration(
                labelText: 'Committee Role',
                labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                filled: true,
                fillColor: const Color(0xFF0D0B14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF9D4EDD))),
              ),
              items: const [
                DropdownMenuItem(value: 'head', child: Text('👑 Head', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'coordinator', child: Text('📋 Coordinator', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'volunteer', child: Text('🙋 Volunteer', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _selectedUser != null ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]) : null,
                  color: _selectedUser == null ? Colors.grey : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _selectedUser != null ? _addMember : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_selectedUser != null ? 'Add ${_selectedUser!.name}' : 'Select a user to add', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

