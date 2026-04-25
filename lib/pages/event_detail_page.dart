// lib/pages/event_detail_page.dart
// Enhanced Event Detail with Registration, QR Code, Ratings, Comments, and Countdown

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/registration_service.dart';
import '../services/auth_service.dart';
import '../services/share_service.dart';
import '../services/feedback_service.dart';
import '../services/comment_service.dart';
import '../services/gamification_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/star_rating.dart';
import '../services/reminder_service.dart';
import '../services/waitlist_service.dart';
import '../services/supabase_service.dart';
import '../services/logging_service.dart';
import 'qr_generate_page.dart';
import 'qr_scan_page.dart';
import 'attendance_page.dart';
import 'edit_event_page.dart';
import 'photo_gallery_page.dart';
import 'committee_page.dart';
import 'resources_page.dart';
// Import refactored widgets (hiding conflicting names)
import 'event_detail/event_info_card.dart';
import 'event_detail/event_action_button.dart';
import 'event_detail/participants_section.dart' hide Participant;

class EventDetailPage extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  bool isRegistered = false;
  bool loading = true;
  bool registering = false;
  Event? event;
  User? currentUser;
  int attendeeCount = 0;

  // New features state
  double _averageRating = 0.0;
  int _feedbackCount = 0;
  List<EventComment> _comments = [];
  EventFeedback? _userFeedback;
  final TextEditingController _commentController = TextEditingController();

  // Reminder state
  List<String> _activeReminders = [];

  // Waitlist state
  int? _waitlistPosition;

  // Real-time subscription
  dynamic _registrationChannel;
  dynamic _eventChannel;

  @override
  void initState() {
    super.initState();
    currentUser = ref.read(currentUserProvider);
    _loadEventDetails();
    _setupRealTimeSubscriptions();
  }

  @override
  void dispose() {
    _registrationChannel?.cancel();
    _eventChannel?.cancel();
    super.dispose();
  }

  void _setupRealTimeSubscriptions() {
    // Subscribe to registration changes for this event using streams
    _registrationChannel = SupabaseService.client
        .from('registrations')
        .stream(primaryKey: ['id'])
        .eq('event_id', widget.eventId)
        .listen((data) {
          // Reload event details when registration changes
          if (mounted) _loadEventDetails();
        });

    // Subscribe to event changes using streams
    _eventChannel = SupabaseService.client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('id', widget.eventId)
        .listen((data) {
          // Reload event details when event is updated
          if (mounted) _loadEventDetails();
        });
  }

  Future<void> _loadEventDetails() async {
    try {
      final evt = await EventService.getEvent(widget.eventId);
      if (evt != null && currentUser != null) {
        final registered = await RegistrationService.checkRegistration(currentUser!.id, evt.id);
        final count = await RegistrationService.getAttendeeCount(evt.id);

        // Load new features data
        final avgRating = await FeedbackService.getAverageRating(evt.id);
        final feedbackCount = await FeedbackService.getFeedbackCount(evt.id);
        final userFeedback = await FeedbackService.getUserFeedback(evt.id, currentUser!.id);
        final comments = await CommentService.getEventComments(evt.id);

        // Load reminders
        final reminders = await ReminderService.getEventReminders(evt.id);

        // Load waitlist position (if not registered)
        int? waitlistPos;
        if (!registered && evt.isFull) {
          waitlistPos = await WaitlistService.getPosition(evt.id);
        }

        setState(() {
          event = evt;
          isRegistered = registered;
          attendeeCount = count;
          _averageRating = avgRating;
          _feedbackCount = feedbackCount;
          _userFeedback = userFeedback;
          _comments = comments;
          _activeReminders = reminders;
          _waitlistPosition = waitlistPos;
          loading = false;
        });
      } else {
        setState(() { event = evt; loading = false; });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _submitFeedback(int rating, String? comment) async {
    if (currentUser == null || event == null) return;
    try {
      await FeedbackService.submitFeedback(
        eventId: event!.id,
        userId: currentUser!.id,
        rating: rating,
        comment: comment,
      );
      // Award points for feedback
      await GamificationService.awardFeedbackGiven(currentUser!.id);
      _loadEventDetails(); // Reload to show updated rating
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⭐ Thanks for your feedback!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (currentUser == null || event == null || _commentController.text.trim().isEmpty) return;
    try {
      await CommentService.addComment(
        eventId: event!.id,
        userId: currentUser!.id,
        content: _commentController.text.trim(),
      );
      _commentController.clear();
      _loadEventDetails(); // Reload comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleRegistration() async {
    if (currentUser == null || event == null) return;

    // If registering, ask for consent first
    if (!isRegistered) {
      final consent = await _showPrivacyConsentDialog();
      if (consent == null) return; // User cancelled

      setState(() => registering = true);
      try {
        await RegistrationService.registerForEvent(currentUser!.id, event!.id, showInList: consent);
        setState(() { isRegistered = true; attendeeCount++; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registered successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
        }
      }
    } else {
      // Unregistering
      setState(() => registering = true);
      try {
        await RegistrationService.unregisterFromEvent(currentUser!.id, event!.id);
        setState(() { isRegistered = false; attendeeCount--; });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unregistered from event'), backgroundColor: Colors.grey),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
        }
      }
    }
    setState(() => registering = false);
  }

  Future<bool?> _showPrivacyConsentDialog() async {
    bool showInList = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? DarkColors.surface : Colors.white,
          title: Text('Register for Event', style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You\'re about to register for "${event!.title}"',
                style: TextStyle(color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show my name in attendees list',
                            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            showInList ? 'Your name will be visible' : 'You will appear as "Anonymous"',
                            style: TextStyle(fontSize: 12, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: showInList,
                      onChanged: (value) => setDialogState(() => showInList = value),
                      activeColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, showInList),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyQRCode() {
    if (event == null || currentUser == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => QrGeneratePage(eventId: event!.id)));
  }

  void _showReminderOptions(bool isDark) {
    if (event == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Reminder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get notified before the event starts',
                style: TextStyle(color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              _buildReminderOption('30min', '30 Minutes Before', Icons.access_time, isDark, setModalState),
              _buildReminderOption('hour', '1 Hour Before', Icons.timer, isDark, setModalState),
              _buildReminderOption('day', '1 Day Before', Icons.today, isDark, setModalState),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderOption(String type, String label, IconData icon, bool isDark, StateSetter setModalState) {
    final isActive = _activeReminders.contains(type);

    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.orange : (isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
      title: Text(label, style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary)),
      trailing: Switch(
        value: isActive,
        activeColor: Colors.orange,
        onChanged: (value) async {
          if (event == null) return;

          if (value) {
            final success = await ReminderService.setReminder(
              eventId: event!.id,
              reminderType: type,
              eventDate: event!.date,
            );
            if (success) {
              setState(() => _activeReminders.add(type));
              setModalState(() {});
            } else {
              // Show error feedback
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot set reminder - time has already passed'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            final success = await ReminderService.cancelReminder(
              eventId: event!.id,
              reminderType: type,
            );
            if (success) {
              setState(() => _activeReminders.remove(type));
              setModalState(() {});
            }
          }
        },
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showWaitlistDialog(bool isDark) async {
    if (event == null) return;

    // Show loading
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<List<WaitlistEntry>>(
        future: WaitlistService.getEventWaitlist(event!.id),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.queue, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Waitlist',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (snapshot.hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${snapshot.data!.length} waiting',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
                          const SizedBox(height: 8),
                          Text('No one on waitlist', style: TextStyle(color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final entry = snapshot.data![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.2),
                            child: Text(
                              '#${entry.position}',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            entry.userName ?? 'User ${index + 1}',
                            style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary),
                          ),
                          subtitle: Text(
                            'Joined ${_formatWaitlistDate(entry.joinedAt)}',
                            style: TextStyle(fontSize: 12, color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatWaitlistDate(DateTime date) {
    // Show exact date and time
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} at $hour:$minute $amPm';
  }

  void _showParticipantsList(bool isDark) async {
    if (event == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? DarkColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _getParticipants(),
        builder: (context, snapshot) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: isDark ? DarkColors.primary : AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Participants',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (snapshot.hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${snapshot.data!.length} registered',
                          style: TextStyle(color: isDark ? DarkColors.primary : AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('No participants yet', style: TextStyle(color: isDark ? DarkColors.textSecondary : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final participant = snapshot.data![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isDark ? DarkColors.primary : AppTheme.primaryColor).withOpacity(0.2),
                            backgroundImage: participant['profile_image_url'] != null
                                ? NetworkImage(participant['profile_image_url'])
                                : null,
                            child: participant['profile_image_url'] == null
                                ? Text(
                                    (participant['name'] ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(color: isDark ? DarkColors.primary : AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            participant['name'] ?? 'Unknown User',
                            style: TextStyle(color: isDark ? DarkColors.textPrimary : AppTheme.textPrimary),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? DarkColors.primary : AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getParticipants() async {
    if (event == null) {
      LoggingService.debug('Event is null, returning empty');
      return [];
    }
    try {
      LoggingService.debug('Fetching participants for event ID: ${event!.id}');

      // Get all registrations for this event
      final registrations = await SupabaseService.client
          .from('registrations')
          .select('user_id')
          .eq('event_id', event!.id);

      LoggingService.debug('Registrations found: ${(registrations as List).length}');

      if (registrations.isEmpty) return [];

      // Get user details for each registration
      final userIds = registrations.map((e) => e['user_id'] as String).toList();
      LoggingService.debug('User IDs: $userIds');

      final users = await SupabaseService.client
          .from('users')
          .select('id, name, email, profile_image_url')
          .inFilter('id', userIds);

      LoggingService.debug('Users found: ${(users as List).length}');

      // Try to get privacy settings (may fail if column doesn't exist)
      Map<String, bool> showInListMap = {};
      try {
        final privacySettings = await SupabaseService.client
            .from('registrations')
            .select('user_id, show_in_list')
            .eq('event_id', event!.id);
        for (var reg in (privacySettings as List)) {
          showInListMap[reg['user_id'] as String] = reg['show_in_list'] ?? true;
        }
      } catch (e) {
        LoggingService.debug('Privacy column may not exist: $e');
        // Default all to visible if column doesn't exist
      }

      return users.map((u) {
        final userId = u['id'] as String;
        final showInList = showInListMap[userId] ?? true;

        return {
          'user_id': userId,
          'name': showInList ? (u['name'] ?? 'Unknown') : 'Anonymous',
          'email': showInList ? (u['email'] ?? '') : '(Hidden)',
          'profile_image_url': showInList ? u['profile_image_url'] : null,
          'is_anonymous': !showInList,
        };
      }).toList();
    } catch (e) {
      LoggingService.error('Error fetching participants', e);
      return [];
    }
  }

  Future<void> _deleteEvent() async {
    if (event == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event!.title}"? This action cannot be undone.'),
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
        await EventService.deleteEvent(event!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back after deletion
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD))),
      );
    }

    if (event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0B14),
        appBar: AppBar(backgroundColor: const Color(0xFF1E1B2E), elevation: 0),
        body: const Center(child: Text('Event not found', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: CustomScrollView(
        slivers: [
          // Hero Image with App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1E1B2E),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Edit button - for event creator, admin, super_admin, or president
              if (currentUser?.id == event!.createdBy || currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.8), shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditEventPage(event: event!)));
                    if (result == true) _loadEventDetails(); // Refresh if updated
                  },
                ),
              // Delete button - only for admin, super_admin, and president
              if (currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), shape: BoxShape.circle),
                    child: const Icon(Icons.delete, color: Colors.white, size: 18),
                  ),
                  onPressed: _deleteEvent,
                ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.share, color: Colors.white, size: 18),
                ),
                onPressed: () => ShareService.showShareSheet(context, event!),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: event!.imageUrl != null
                  ? Container(
                      color: const Color(0xFF1E1B2E),
                      child: CachedNetworkImage(
                        imageUrl: event!.imageUrl!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorWidget: (_, __, ___) => _buildPlaceholderImage(isDark),
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1E1B2E),
                          child: const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD))),
                        ),
                      ),
                    )
                  : _buildPlaceholderImage(isDark),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isRegistered ? Colors.green.withOpacity(0.15) : const Color(0xFF9D4EDD).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isRegistered ? Icons.check_circle : Icons.event_available, size: 16, color: isRegistered ? Colors.green : const Color(0xFF9D4EDD)),
                            const SizedBox(width: 4),
                            Text(isRegistered ? 'Registered' : 'Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRegistered ? Colors.green : const Color(0xFF9D4EDD))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _getCategoryColor(event!.category ?? 'Other').withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(event!.category ?? 'Event', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getCategoryColor(event!.category ?? 'Other'))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(event!.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),

                  const SizedBox(height: 20),

                  // Info Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(event!.date), isDark),
                        const Divider(height: 24, color: Color(0xFF3D3557)),
                        _buildInfoRow(Icons.access_time, 'Time', _formatTime(event!.date), isDark),
                        const Divider(height: 24, color: Color(0xFF3D3557)),
                        _buildInfoRow(Icons.location_on, 'Venue', event!.venue, isDark),
                        const Divider(height: 24, color: Color(0xFF3D3557)),
                        InkWell(
                          onTap: () => _showParticipantsList(isDark),
                          child: _buildInfoRow(Icons.people, 'Attendees', '${event!.currentAttendees} registered  ▶', isDark),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  const Text('About Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(event!.description, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFFB8A9C9))),

                  const SizedBox(height: 24),

                  // Capacity Section (if limited)
                  if (event!.maxAttendees != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Capacity',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event!.isFull ? Colors.red.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  event!.isFull ? 'SOLD OUT' : '${event!.remainingSpots} spots left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: event!.isFull ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: event!.currentAttendees / event!.maxAttendees!,
                              backgroundColor: const Color(0xFF3D3557),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                event!.isFull ? Colors.red : const Color(0xFF9D4EDD),
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${event!.currentAttendees} / ${event!.maxAttendees} registered',
                            style: const TextStyle(fontSize: 13, color: Color(0xFFB8A9C9)),
                          ),
                          // View Waitlist button for organizers
                          if (event!.isFull && (currentUser?.id == event!.createdBy || currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident)) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showWaitlistDialog(isDark),
                                icon: const Icon(Icons.queue, size: 18),
                                label: const Text('View Waitlist'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Countdown Timer (for upcoming events OR for admin/president on any event)
                  if (event!.date.isAfter(DateTime.now()) ||
                      currentUser?.role == UserRole.admin ||
                      currentUser?.role == UserRole.superAdmin ||
                      currentUser?.role == UserRole.president) ...[
                    CountdownTimer(
                      eventDate: event!.date,
                      eventId: event!.id,
                      userRole: currentUser?.role,
                      onPostpone: _loadEventDetails,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons — only for upcoming events
                  if (event!.date.isBefore(DateTime.now())) ...[
                    // Past event — show ended banner, no registration
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy, color: Colors.red, size: 36),
                          const SizedBox(height: 12),
                          const Text(
                            'This event has ended',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ended on ${_formatDate(event!.date)}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFFB8A9C9)),
                          ),
                          if (isRegistered) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text('You attended this event', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (currentUser?.role == UserRole.student || currentUser?.role == UserRole.president) ...[
                    // Upcoming event — show registration buttons
                    // Show waitlist button if event is full and not registered
                    if (event!.isFull && !isRegistered) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: registering ? null : () async {
                            setState(() => registering = true);
                            if (_waitlistPosition != null) {
                              // Leave waitlist
                              await WaitlistService.leaveWaitlist(event!.id);
                              setState(() => _waitlistPosition = null);
                            } else {
                              // Join waitlist
                              final pos = await WaitlistService.joinWaitlist(event!.id);
                              setState(() => _waitlistPosition = pos);
                            }
                            setState(() => registering = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _waitlistPosition != null ? Colors.orange : Colors.grey.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: registering
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_waitlistPosition != null ? Icons.remove_circle : Icons.add_circle, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      _waitlistPosition != null
                                          ? 'Leave Waitlist (#$_waitlistPosition)'
                                          : 'Event Full - Join Waitlist',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // Normal registration button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: registering ? null : _toggleRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRegistered ? Colors.red : const Color(0xFF9D4EDD),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: registering
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isRegistered ? Icons.cancel : Icons.how_to_reg, size: 22),
                                    const SizedBox(width: 8),
                                    Text(isRegistered ? 'Unregister' : 'Register Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],

                    // Show QR button if registered
                    if (isRegistered) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _showMyQRCode,
                          icon: const Icon(Icons.qr_code_2, color: Color(0xFF9D4EDD)),
                          label: const Text('Show My QR Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9D4EDD))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],

                    // Reminder Button
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReminderOptions(isDark),
                        icon: Icon(
                          _activeReminders.isNotEmpty ? Icons.notifications_active : Icons.notifications_none,
                          color: _activeReminders.isNotEmpty ? Colors.orange : const Color(0xFFB8A9C9),
                        ),
                        label: Text(
                          _activeReminders.isNotEmpty ? 'Reminder Set (${_activeReminders.length})' : 'Set Reminder',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3D3557)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  // Photo Gallery Button (show for past events)
                  if (event!.date.isBefore(DateTime.now())) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoGalleryPage(event: event!))),
                        icon: const Icon(Icons.photo_library, color: Color(0xFF9D4EDD)),
                        label: const Text('View Event Photos', style: TextStyle(fontSize: 14, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3D3557)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  // Committee Button (show for organizers)
                  if (currentUser?.id == event!.createdBy || currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommitteePage(event: event!))),
                        icon: const Icon(Icons.groups, color: Color(0xFF9D4EDD)),
                        label: const Text('Manage Committee', style: TextStyle(fontSize: 14, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3D3557)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  // Resources Button (for organizers)
                  if (currentUser?.id == event!.createdBy || currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResourcesPage(event: event!))),
                        icon: const Icon(Icons.folder, color: Color(0xFF9D4EDD)),
                        label: const Text('Event Resources', style: TextStyle(fontSize: 14, color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3D3557)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  // Attendance Button (for organizers/admins)
                  if (currentUser?.id == event!.createdBy || currentUser?.role == UserRole.admin || currentUser?.role == UserRole.superAdmin || currentUser?.role == UserRole.president || currentUser?.role == UserRole.vicePresident) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // View Attendance
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AttendancePage(event: event!)),
                              ),
                              icon: const Icon(Icons.how_to_reg, color: Colors.green),
                              label: const Text('Attendance', style: TextStyle(fontSize: 13, color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Scan QR
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const QrScanPage()),
                              ),
                              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF9D4EDD)),
                              label: const Text('Scan QR', style: TextStyle(fontSize: 13, color: Color(0xFF9D4EDD))),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF9D4EDD)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Rating Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 24),
                            SizedBox(width: 8),
                            Text('Ratings & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            StarRating(rating: _averageRating, size: 28, showValue: true),
                            const SizedBox(width: 12),
                            Text('($_feedbackCount reviews)', style: const TextStyle(color: Color(0xFFB8A9C9))),
                          ],
                        ),
                        if (_userFeedback == null && currentUser != null) ...[
                          const Divider(height: 24, color: Color(0xFF3D3557)),
                          const Text('Rate this event:', style: TextStyle(color: Color(0xFFB8A9C9))),
                          const SizedBox(height: 8),
                          InteractiveStarRating(
                            onRatingChanged: (rating) => _submitFeedback(rating, null),
                          ),
                        ] else if (_userFeedback != null) ...[
                          const Divider(height: 24, color: Color(0xFF3D3557)),
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text('You rated this ${_userFeedback!.rating} stars', style: const TextStyle(color: Color(0xFFB8A9C9))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comments Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.comment, color: Color(0xFF9D4EDD), size: 24),
                            const SizedBox(width: 8),
                            Text('Discussion (${_comments.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        if (currentUser != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a comment...',
                                    hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                                    filled: true,
                                    fillColor: const Color(0xFF0D0B14),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addComment,
                                icon: const Icon(Icons.send, color: Color(0xFF9D4EDD)),
                              ),
                            ],
                          ),
                        ],
                        if (_comments.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ..._comments.take(5).map((comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF9D4EDD).withOpacity(0.2),
                                  child: Text(comment.userName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF9D4EDD), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                          const SizedBox(width: 8),
                                          Text(_formatTimeAgo(comment.createdAt), style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.content, style: const TextStyle(color: Color(0xFFB8A9C9))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ] else ...[
                          const SizedBox(height: 16),
                          const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Color(0xFFB8A9C9)))),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899).withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(Icons.event, color: Colors.white.withOpacity(0.5), size: 80)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    // Now using refactored EventInfoRow widget
    return EventInfoRow(
      icon: icon,
      label: label,
      value: value,
      iconColor: const Color(0xFF9D4EDD),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'tech': return AppColors.categoryTech;
      case 'sports': return AppColors.categorySports;
      case 'cultural': return AppColors.categoryCultural;
      case 'academic': return AppColors.categoryAcademic;
      case 'music': return AppColors.categoryMusic;
      default: return AppColors.primary;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
