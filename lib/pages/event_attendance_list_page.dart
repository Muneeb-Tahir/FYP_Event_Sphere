// lib/pages/event_attendance_list_page.dart
// Admin page: pick an event to view its attendance

import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../models/event.dart';
import 'attendance_page.dart';

class EventAttendanceListPage extends StatefulWidget {
  const EventAttendanceListPage({super.key});

  @override
  State<EventAttendanceListPage> createState() => _EventAttendanceListPageState();
}

class _EventAttendanceListPageState extends State<EventAttendanceListPage> {
  List<Event> _events = [];
  Map<String, _AttendanceStats> _stats = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await EventService.getAllEvents();
      // Sort by date descending (newest first)
      events.sort((a, b) => b.date.compareTo(a.date));

      // Load attendance stats for each event
      final stats = <String, _AttendanceStats>{};
      for (final event in events) {
        try {
          final registered = await RegistrationService.getAttendeeCount(event.id);
          final checkedIn = (await RegistrationService.getCheckedInAttendees(event.id)).length;
          stats[event.id] = _AttendanceStats(registered: registered, checkedIn: checkedIn);
        } catch (_) {
          stats[event.id] = _AttendanceStats(registered: 0, checkedIn: 0);
        }
      }

      if (mounted) {
        setState(() {
          _events = events;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Event> get _filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    final q = _searchQuery.toLowerCase();
    return _events.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.venue.toLowerCase().contains(q) ||
        e.category.toLowerCase().contains(q)).toList();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search events...',
                hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB8A9C9)),
                filled: true,
                fillColor: const Color(0xFF1E1B2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF3D3557)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF3D3557)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF9D4EDD)),
                ),
              ),
            ),
          ),

          // Event list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
                : _filteredEvents.isEmpty
                    ? const Center(child: Text('No events found', style: TextStyle(color: Color(0xFFB8A9C9))))
                    : RefreshIndicator(
                        onRefresh: _loadEvents,
                        color: const Color(0xFF9D4EDD),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredEvents.length,
                          itemBuilder: (context, index) => _buildEventCard(_filteredEvents[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    final stats = _stats[event.id] ?? _AttendanceStats(registered: 0, checkedIn: 0);
    final isPast = event.date.isBefore(DateTime.now());
    final percentage = stats.registered > 0 ? (stats.checkedIn / stats.registered * 100).round() : 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AttendancePage(event: event)),
      ).then((_) => _loadEvents()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.grey.withOpacity(0.2) : const Color(0xFF22C55E).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPast ? 'Past' : 'Upcoming',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPast ? Colors.grey : const Color(0xFF22C55E)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date & venue
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFFB8A9C9)),
                const SizedBox(width: 6),
                Text(_formatDate(event.date), style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                const SizedBox(width: 16),
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFB8A9C9)),
                const SizedBox(width: 4),
                Expanded(child: Text(event.venue, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),

            // Attendance stats
            Row(
              children: [
                _buildStatChip(Icons.people, '${stats.registered}', 'Registered', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatChip(Icons.check_circle, '${stats.checkedIn}', 'Checked In', const Color(0xFF22C55E)),
                const SizedBox(width: 8),
                _buildStatChip(Icons.percent, '$percentage%', 'Rate', const Color(0xFF9D4EDD)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Color(0xFFB8A9C9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _AttendanceStats {
  final int registered;
  final int checkedIn;
  _AttendanceStats({required this.registered, required this.checkedIn});
}
