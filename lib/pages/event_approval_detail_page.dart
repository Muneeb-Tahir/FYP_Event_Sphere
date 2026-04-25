// lib/pages/event_approval_detail_page.dart
// Event Approval Detail Page - Full details view for admin review
// Extracted from event_approval_page.dart for better maintainability

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/logging_service.dart';
import '../constants/app_theme.dart';
import '../utils/haptic_feedback.dart';

class EventApprovalDetailPage extends StatefulWidget {
  final Event event;

  const EventApprovalDetailPage({super.key, required this.event});

  @override
  State<EventApprovalDetailPage> createState() => _EventApprovalDetailPageState();
}

class _EventApprovalDetailPageState extends State<EventApprovalDetailPage> {
  bool _isProcessing = false;
  String? _creatorName;

  @override
  void initState() {
    super.initState();
    _loadCreatorName();
  }

  Future<void> _loadCreatorName() async {
    try {
      final user = await SupabaseService.client
          .from('users')
          .select('name')
          .eq('id', widget.event.createdBy)
          .maybeSingle();
      if (mounted && user != null) {
        setState(() => _creatorName = user['name'] ?? 'Unknown');
      }
    } catch (e) {
      LoggingService.error('Error loading creator name', e);
    }
  }

  Future<void> _approveEvent() async {
    HapticUtils.mediumImpact();
    setState(() => _isProcessing = true);

    try {
      await EventService.approveEvent(widget.event.id);

      // Send notification to all users about the newly approved event
      String societyName = 'Event Sphere';
      try {
        final society = await SupabaseService.client
            .from('societies')
            .select('name')
            .eq('id', widget.event.societyId)
            .maybeSingle();
        if (society != null) societyName = society['name'] ?? 'Event Sphere';
      } catch (_) {}

      LoggingService.info('Sending new event notification for: ${widget.event.title}');
      await NotificationService.notifyNewEvent(
        eventName: widget.event.title,
        societyName: societyName,
        eventId: widget.event.id,
      );
      LoggingService.info('Notification sent!');

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Event approved successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      HapticUtils.error();
      _showError('Failed to approve: ${e.toString()}');
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _rejectEvent() async {
    HapticUtils.mediumImpact();
    // Show rejection reason dialog
    final reason = await _showRejectDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);

    try {
      await EventService.rejectEvent(widget.event.id);
      if (mounted) {
        HapticUtils.warning();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('Event rejected'),
              ],
            ),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      HapticUtils.error();
      _showError('Failed to reject: ${e.toString()}');
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<String?> _showRejectDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Reject Event', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejection (optional):',
              style: TextStyle(fontSize: 14, color: Color(0xFFB8A9C9)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g., Incomplete information, venue conflict...',
                hintStyle: TextStyle(color: Color(0xFFB8A9C9)),
                border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3D3557))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3D3557))),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF9D4EDD))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tech': return Icons.computer;
      case 'sports': return Icons.sports_soccer;
      case 'cultural': return Icons.theater_comedy;
      case 'academic': return Icons.school;
      case 'music': return Icons.music_note;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final categoryColor = _getCategoryColor(event.category);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      body: CustomScrollView(
        slivers: [
          // Header with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: categoryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [categoryColor, categoryColor.withOpacity(0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(event.category), size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  event.category,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Title
                          Text(
                            event.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pending_actions, color: AppTheme.warningColor),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending Approval', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                              SizedBox(height: 2),
                              Text('This event is waiting for your review', style: TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Event Details Section
                  _buildSectionTitle('Event Details'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(event.date)),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.access_time, 'Time', _formatTime(event.date)),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.location_on, 'Venue', event.venue),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.group, 'Society', event.societyId),
                  ]),
                  const SizedBox(height: 24),

                  // Description Section
                  _buildSectionTitle('Description'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                    ),
                    child: Text(
                      event.description.isNotEmpty ? event.description : 'No description provided.',
                      style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Organizer Info
                  _buildSectionTitle('Organizer'),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(Icons.person, 'Created By', _creatorName ?? 'Loading...'),
                  ]),
                  const SizedBox(height: 100), // Space for buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Reject Button
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.dangerColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _rejectEvent,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, color: AppTheme.dangerColor),
                      SizedBox(width: 8),
                      Text('Reject', style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Approve Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isProcessing ? null : _approveEvent,
                  child: _isProcessing
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Approve Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white));
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF9D4EDD).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF9D4EDD)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
