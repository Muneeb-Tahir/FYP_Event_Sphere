// lib/pages/announcements_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/announcement_service.dart';
import '../models/announcement.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class AnnouncementsPage extends ConsumerStatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  ConsumerState<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends ConsumerState<AnnouncementsPage> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  // ------------------------- LOAD ANNOUNCEMENTS -------------------------
  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final announcements = await AnnouncementService.getAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('Failed to load announcements: ${e.toString()}');
    }
  }

  // ------------------------- REFRESH ANNOUNCEMENTS -------------------------
  Future<void> _refreshAnnouncements() async {
    await _loadAnnouncements();
  }

  // ------------------------- HANDLE ERROR -------------------------
  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  // ------------------------- SHOW SNACKBAR -------------------------
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------- CREATE ANNOUNCEMENT -------------------------
  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool isUrgent = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          title: const Text('New Announcement', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF9D4EDD))),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3D3557))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF9D4EDD))),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Mark as Urgent', style: TextStyle(color: Colors.white)),
                  value: isUrgent,
                  activeColor: const Color(0xFF9D4EDD),
                  onChanged: (v) => setDialogState(() => isUrgent = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        await AnnouncementService.createAnnouncement(
          title: titleController.text,
          content: messageController.text,
          priority: isUrgent ? AnnouncementPriority.urgent : AnnouncementPriority.normal,
        );
        _showSnackBar('Announcement created');
        await _refreshAnnouncements();
      } catch (e) {
        _showSnackBar('Failed to create: ${e.toString()}', isError: true);
      }
    }
  }

  // ------------------------- DELETE ANNOUNCEMENT -------------------------
  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Delete Announcement', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to delete this announcement?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
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
        await AnnouncementService.deleteAnnouncement(id);
        _showSnackBar('Announcement deleted');
        await _refreshAnnouncements();
      } catch (e) {
        _showSnackBar('Failed to delete: ${e.toString()}', isError: true);
      }
    }
  }

  // ------------------------- CHECK IF ADMIN -------------------------
  bool _isAdmin() {
    final user = ref.read(currentUserProvider);
    return user?.role == UserRole.admin || user?.role == UserRole.superAdmin;
  }

  // ------------------------- FORMAT TIME AGO -------------------------
  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Announcements', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _refreshAnnouncements,
          ),
        ],
      ),
      floatingActionButton: _isAdmin()
          ? Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FloatingActionButton(
                onPressed: _createAnnouncement,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnnouncements,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9D4EDD)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_announcements.isEmpty) {
      return const Center(child: Text('No announcements', style: TextStyle(color: Color(0xFFB8A9C9))));
    }

    return RefreshIndicator(
      onRefresh: _refreshAnnouncements,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _announcements.length,
        itemBuilder: (context, idx) {
          final announcement = _announcements[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (announcement.isUrgent)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'URGENT',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isAdmin())
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _deleteAnnouncement(announcement.id),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeAgo(announcement.createdAt),
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9)),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.content,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB8A9C9)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}