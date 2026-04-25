// lib/pages/user_management_page.dart
// Admin User Management Page - RBAC with Hierarchy Enforcement

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';
import '../services/role_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../constants/role_constants.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  List<UserInfo> _users = [];
  List<UserInfo> _filteredUsers = [];
  bool _loading = true;
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();
  Map<String, int> _roleCounts = {
    'student': 0,
    'vice_president': 0,
    'president': 0,
    'admin': 0,
    'super_admin': 0,
  };

  // Current user's role determines what they can see/do
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _detectCurrentUserRole();
    _loadUsers();
    _loadRoleCounts();
  }

  void _detectCurrentUserRole() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _currentUserRole = RoleConstants.roleEnumToDb(currentUser.role);
    }
  }

  // Check if current user is super_admin
  bool get _isSuperAdmin => _currentUserRole == RoleConstants.superAdmin;

  // Check if current user is admin (but not super_admin)
  bool get _isAdmin => _currentUserRole == RoleConstants.admin;

  // Get roles that current user can assign
  List<String> get _assignableRoles {
    if (_isSuperAdmin) {
      return [RoleConstants.student, RoleConstants.vicePresident, RoleConstants.president, RoleConstants.admin];
    } else if (_isAdmin) {
      return [RoleConstants.student, RoleConstants.vicePresident, RoleConstants.president];
    }
    return [];
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
        _applyFilters();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('Failed to load users: $e');
    }
  }

  Future<void> _loadRoleCounts() async {
    try {
      final counts = await UserService.getUserCountsByRole();
      setState(() => _roleCounts = counts);
    } catch (e) {
      // Ignore
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        bool matchesSearch = user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
        bool matchesRole = _selectedFilter == 'all' || user.role == _selectedFilter;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.dangerColor),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _changeUserRole(UserInfo user) async {

    // Get roles that current user can assign
    final assignableRoles = _assignableRoles;

    String? newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Change Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select new role for ${user.name}:', style: const TextStyle(color: Color(0xFFB8A9C9))),
            const SizedBox(height: 16),
            // Only show roles that current user can assign
            ...assignableRoles.map((role) => ListTile(
              leading: Icon(_getRoleIcon(role), color: _getRoleColor(role)),
              title: Text(RoleConstants.getDisplayName(role), style: const TextStyle(color: Colors.white)),
              selected: user.role == role,
              onTap: () => Navigator.pop(context, role),
            )),
          ],
        ),
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        // Use secure RPC via RoleService instead of direct update
        await RoleService.changeUserRole(user.id, newRole);
        _showSuccess('Role updated to ${RoleConstants.getDisplayName(newRole)}');
        _loadUsers();
        _loadRoleCounts();
      } catch (e) {
        _showError('Failed to update role: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  Future<void> _deleteUser(UserInfo user) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Delete User', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete ${user.name}?\nThis action cannot be undone.',
            style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UserService.deleteUser(user.id);
        _showSuccess('User deleted successfully');
        _loadUsers();
        _loadRoleCounts();
      } catch (e) {
        _showError('Failed to delete user: $e');
      }
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin': return Icons.shield;
      case 'admin': return Icons.admin_panel_settings;
      case 'president': return Icons.stars;
      case 'vice_president': return Icons.assistant;
      case 'student':
      default: return Icons.school;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin': return Colors.deepPurple;
      case 'admin': return Colors.red;
      case 'president': return Colors.orange;
      case 'vice_president': return Colors.purple;
      case 'student':
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('User Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatCard('Students', _roleCounts['student'] ?? 0, Colors.blue, Icons.school, isDark),
                const SizedBox(width: 8),
                _buildStatCard('Vice-P', _roleCounts['vice_president'] ?? 0, Colors.purple, Icons.assistant, isDark),
                const SizedBox(width: 8),
                _buildStatCard('Presidents', _roleCounts['president'] ?? 0, Colors.orange, Icons.stars, isDark),
                const SizedBox(width: 8),
                _buildStatCard('Admins', _roleCounts['admin'] ?? 0, Colors.red, Icons.admin_panel_settings, isDark),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB8A9C9)),
                filled: true,
                fillColor: const Color(0xFF1E1B2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD))),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Students', 'student', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Vice-P', 'vice_president', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Presidents', 'president', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('Admins', 'admin', isDark),
                ],
              ),
            ),
          ),

          // Users List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('No users found', style: TextStyle(color: Color(0xFFB8A9C9))))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index], isDark),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFB8A9C9))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = value);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9D4EDD) : const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF9D4EDD) : const Color(0xFF3D3557)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildUserCard(UserInfo user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _getRoleColor(user.role).withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(RoleConstants.getDisplayName(user.role), style: TextStyle(fontSize: 10, color: _getRoleColor(user.role), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFFB8A9C9)),
            color: const Color(0xFF1E1B2E),
            onSelected: (value) {
              if (value == 'role') _changeUserRole(user);
              if (value == 'delete') _deleteUser(user);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'role', child: Row(children: [Icon(Icons.swap_horiz, size: 20, color: Colors.white), SizedBox(width: 8), Text('Change Role', style: TextStyle(color: Colors.white))])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
    );
  }
}
