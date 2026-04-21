// lib/pages/attendance_page.dart
// Attendance Management for President - View and manage event attendees

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/registration_service.dart';
import '../services/user_service.dart';
import '../constants/app_theme.dart';

class AttendancePage extends StatefulWidget {
  final Event event;
  const AttendancePage({super.key, required this.event});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<AttendeeInfo> _attendees = [];
  bool _loading = true;
  String _filter = 'all'; // all, checked_in, not_checked_in

  @override
  void initState() {
    super.initState();
    _loadAttendees();
  }

  Future<void> _loadAttendees() async {
    setState(() => _loading = true);
    try {
      // Get registered user IDs
      final userIds = await RegistrationService.getEventAttendees(widget.event.id);
      final checkedInIds = await RegistrationService.getCheckedInAttendees(widget.event.id);

      // Fetch user details
      List<AttendeeInfo> attendees = [];
      for (String userId in userIds) {
        final user = await UserService.getUserById(userId);
        if (user != null) {
          attendees.add(AttendeeInfo(
            userId: userId,
            name: user.name,
            email: user.email,
            profileImageUrl: user.profileImageUrl,
            isCheckedIn: checkedInIds.contains(userId),
          ));
        }
      }

      setState(() {
        _attendees = attendees;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading attendees: $e'), backgroundColor: Colors.red));
    }
  }

  List<AttendeeInfo> get _filteredAttendees {
    switch (_filter) {
      case 'checked_in': return _attendees.where((a) => a.isCheckedIn).toList();
      case 'not_checked_in': return _attendees.where((a) => !a.isCheckedIn).toList();
      default: return _attendees;
    }
  }

  int get _checkedInCount => _attendees.where((a) => a.isCheckedIn).length;

  Future<void> _manualCheckIn(AttendeeInfo attendee) async {
    try {
      await RegistrationService.checkInAttendee(attendee.userId, widget.event.id);
      _loadAttendees();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${attendee.name} checked in!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-in failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? DarkColors.surface : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text('Attendance', style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.event.title, style: TextStyle(color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [isDark ? DarkColors.primary : AppTheme.primaryColor, (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', _attendees.length, Icons.people),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStat('Checked In', _checkedInCount, Icons.check_circle),
                Container(width: 1, height: 40, color: Colors.white30),
                _buildStat('Pending', _attendees.length - _checkedInCount, Icons.hourglass_empty),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Checked In', 'checked_in', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Not Checked', 'not_checked_in', isDark),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Attendee List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: isDark ? DarkColors.primary : AppTheme.primaryColor))
                : _filteredAttendees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text('No attendees found', style: TextStyle(fontSize: 16, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAttendees,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAttendees.length,
                          itemBuilder: (context, index) => _buildAttendeeCard(_filteredAttendees[index], isDark),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text('$value', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    bool selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (isDark ? DarkColors.primary : AppTheme.primaryColor) : (isDark ? DarkColors.surface : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : (isDark ? DarkColors.border : AppTheme.borderColor)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : (isDark ? DarkColors.textPrimary : AppTheme.textPrimary), fontWeight: selected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
      ),
    );
  }

  Widget _buildAttendeeCard(AttendeeInfo attendee, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: attendee.isCheckedIn ? Border.all(color: Colors.green.withOpacity(0.3), width: 2) : null,
      ),
      child: Row(
        children: [
          // Avatar with status
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.2),
                backgroundImage: attendee.profileImageUrl != null ? NetworkImage(attendee.profileImageUrl!) : null,
                child: attendee.profileImageUrl == null ? Text(attendee.name[0].toUpperCase(), style: TextStyle(color: isDark ? DarkColors.primary : AppTheme.primaryColor, fontWeight: FontWeight.bold)) : null,
              ),
              if (attendee.isCheckedIn)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: isDark ? DarkColors.surface : Colors.white, width: 2)),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attendee.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(attendee.email, style: TextStyle(fontSize: 13, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
              ],
            ),
          ),

          // Check-in status / button
          if (attendee.isCheckedIn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Attended', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: () => _manualCheckIn(attendee),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Check In', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class AttendeeInfo {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;
  final bool isCheckedIn;

  AttendeeInfo({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.isCheckedIn,
  });
}
