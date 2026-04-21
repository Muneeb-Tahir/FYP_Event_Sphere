// lib/services/share_service.dart
// Event sharing functionality - supports multiple platforms

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';

class ShareService {
  /// Generate shareable event URL
  static String generateEventUrl(String eventId) {
    // In production, this would be your actual domain
    return 'https://eventsphere.app/event/$eventId';
  }

  /// Generate share text for an event
  static String generateShareText(Event event) {
    final dateStr = _formatDate(event.date);
    return '''
🎉 Check out this event!

📌 ${event.title}
📅 $dateStr
📍 ${event.venue}

${event.description.length > 100 ? '${event.description.substring(0, 100)}...' : event.description}

🔗 ${generateEventUrl(event.id)}

#EventSphere #CampusEvents
''';
  }

  /// Copy event link to clipboard
  static Future<void> copyEventLink(BuildContext context, Event event) async {
    final url = generateEventUrl(event.id);
    await Clipboard.setData(ClipboardData(text: url));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Event link copied to clipboard!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Copy full share text to clipboard
  static Future<void> copyShareText(BuildContext context, Event event) async {
    final text = generateShareText(event);
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Event details copied!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Share to WhatsApp (opens WhatsApp with pre-filled text)
  static String getWhatsAppShareUrl(Event event) {
    final text = Uri.encodeComponent(generateShareText(event));
    return 'https://wa.me/?text=$text';
  }

  /// Share to Twitter/X
  static String getTwitterShareUrl(Event event) {
    final text = Uri.encodeComponent('Check out ${event.title} on Event Sphere! 🎉');
    final url = Uri.encodeComponent(generateEventUrl(event.id));
    return 'https://twitter.com/intent/tweet?text=$text&url=$url';
  }

  /// Share to Facebook
  static String getFacebookShareUrl(Event event) {
    final url = Uri.encodeComponent(generateEventUrl(event.id));
    return 'https://www.facebook.com/sharer/sharer.php?u=$url';
  }

  /// Share to LinkedIn
  static String getLinkedInShareUrl(Event event) {
    final url = Uri.encodeComponent(generateEventUrl(event.id));
    final title = Uri.encodeComponent(event.title);
    return 'https://www.linkedin.com/shareArticle?mini=true&url=$url&title=$title';
  }

  /// Share via Email
  static String getEmailShareUrl(Event event) {
    final subject = Uri.encodeComponent('Check out: ${event.title}');
    final body = Uri.encodeComponent(generateShareText(event));
    return 'mailto:?subject=$subject&body=$body';
  }

  /// Show share bottom sheet
  static void showShareSheet(BuildContext context, Event event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ShareBottomSheet(event: event, isDark: isDark),
    );
  }

  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Share Bottom Sheet Widget
class ShareBottomSheet extends StatelessWidget {
  final Event event;
  final bool isDark;

  const ShareBottomSheet({
    super.key,
    required this.event,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Share Event',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Share options grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildShareOption(
                context,
                icon: Icons.copy_rounded,
                label: 'Copy Link',
                color: Colors.blue,
                onTap: () {
                  ShareService.copyEventLink(context, event);
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () {
                  _launchUrl(context, ShareService.getWhatsAppShareUrl(event));
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.alternate_email_rounded,
                label: 'Twitter',
                color: const Color(0xFF1DA1F2),
                onTap: () {
                  _launchUrl(context, ShareService.getTwitterShareUrl(event));
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () {
                  _launchUrl(context, ShareService.getFacebookShareUrl(event));
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.work_rounded,
                label: 'LinkedIn',
                color: const Color(0xFF0A66C2),
                onTap: () {
                  _launchUrl(context, ShareService.getLinkedInShareUrl(event));
                  Navigator.pop(context);
                },
              ),
              _buildShareOption(
                context,
                icon: Icons.email_rounded,
                label: 'Email',
                color: Colors.orange,
                onTap: () {
                  _launchUrl(context, ShareService.getEmailShareUrl(event));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Copy full text button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ShareService.copyShareText(context, event);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.content_copy_rounded),
              label: const Text('Copy Full Share Text'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(BuildContext context, String url) {
    // In production, use url_launcher package
    // For now, copy the URL and show a message
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied! Paste in browser to share.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
