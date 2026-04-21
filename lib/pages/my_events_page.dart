// lib/pages/my_events_page.dart
// President's Event Dashboard - Track event status (Pending/Approved/Rejected)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import 'add_event_page.dart';
import 'attendance_page.dart';
import 'edit_event_page.dart';

class MyEventsPage extends ConsumerStatefulWidget {
  const MyEventsPage({super.key});

  @override
  ConsumerState<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends ConsumerState<MyEventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Event> _allEvents = [];
  bool _loading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentUser = ref.read(currentUserProvider);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (_currentUser == null) return;
    setState(() => _loading = true);
    try {
      final events = await EventService.getEventsByCreator(_currentUser!.id);
      setState(() {
        _allEvents = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Event> _filterByStatus(String? status) {
    if (status == null) return _allEvents;
    return _allEvents.where((e) => e.approvalStatus == status).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'rejected': return Icons.cancel;
      default: return Icons.hourglass_empty;
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
        title: Text('My Events', style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
          unselectedLabelColor: isDark ? DarkColors.textSecondary : AppTheme.textSecondary,
          indicatorColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
          tabs: [
            Tab(text: 'All (${_allEvents.length})'),
            Tab(text: 'Pending (${_filterByStatus('pending').length})'),
            Tab(text: 'Approved (${_filterByStatus('approved').length})'),
            Tab(text: 'Rejected (${_filterByStatus('rejected').length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEventPage()));
          _loadEvents();
        },
        backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Event', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: isDark ? DarkColors.primary : AppTheme.primaryColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEventList(null, isDark),
                _buildEventList('pending', isDark),
                _buildEventList('approved', isDark),
                _buildEventList('rejected', isDark),
              ],
            ),
    );
  }

  Widget _buildEventList(String? status, bool isDark) {
    final events = _filterByStatus(status);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(status == 'rejected' ? Icons.cancel_outlined : Icons.event_busy, size: 64, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text('No ${status ?? ''} events', style: TextStyle(fontSize: 16, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) => _buildEventCard(events[index], isDark),
      ),
    );
  }

  Widget _buildEventCard(Event event, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 120,
                  color: _getStatusColor(event.approvalStatus).withOpacity(0.2),
                  child: Center(child: Icon(Icons.image, size: 40, color: _getStatusColor(event.approvalStatus))),
                ),
                placeholder: (_, __) => Container(
                  height: 120,
                  color: _getStatusColor(event.approvalStatus).withOpacity(0.1),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _getStatusColor(event.approvalStatus))),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _getStatusColor(event.approvalStatus).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(event.approvalStatus), size: 14, color: _getStatusColor(event.approvalStatus)),
                          const SizedBox(width: 4),
                          Text(event.approvalStatus.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getStatusColor(event.approvalStatus))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(event.category ?? 'Event', style: TextStyle(fontSize: 11, color: isDark ? DarkColors.primary : AppTheme.primaryColor)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(event.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary)),
                const SizedBox(height: 8),

                // Date & Venue
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatDate(event.date), style: TextStyle(fontSize: 13, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 14, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(event.venue, style: TextStyle(fontSize: 13, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
                  ],
                ),

                // Rejected Feedback
                if (event.approvalStatus == 'rejected')
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.3))),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Admin feedback: Event needs more details', style: TextStyle(fontSize: 12, color: Colors.red.shade700))),
                      ],
                    ),
                  ),

                // Actions for approved events
                if (event.approvalStatus == 'approved')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendancePage(event: event))),
                            icon: const Icon(Icons.people, size: 18),
                            label: const Text('Attendance'),
                            style: OutlinedButton.styleFrom(foregroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {/* QR Page */},
                            icon: const Icon(Icons.qr_code, size: 18),
                            label: const Text('QR Code'),
                            style: ElevatedButton.styleFrom(backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor, foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Edit button - users can edit their own events
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventPage(event: event)));
                        if (result == true) _loadEvents(); // Refresh if updated
                      },
                      icon: Icon(Icons.edit_outlined, size: 18, color: isDark ? DarkColors.primary : AppTheme.primaryColor),
                      label: Text('Edit Event', style: TextStyle(color: isDark ? DarkColors.primary : AppTheme.primaryColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.5)),
                        foregroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),

                // Delete button - users can delete their own events
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteEvent(event),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('Delete Event', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await EventService.deleteEvent(event.id);
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
