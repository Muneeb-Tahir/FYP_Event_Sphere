// lib/services/chatbot/response_builder.dart
// Response templates and builders for Event Sphere Chatbot

import 'package:intl/intl.dart';
import '../../models/event.dart';
import '../auth_service.dart';

/// Manages response message templates and data formatting
class ChatResponseBuilder {

  // ============================================================================
  // STATIC RESPONSES
  // ============================================================================

  static String greeting() {
    final user = AuthService.getCurrentUser();
    final name = user?.name ?? 'there';
    final hour = DateTime.now().hour;

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }

    return '$timeGreeting, $name! 👋\n\nI\'m your Event Sphere assistant. I can help you with:\n'
           '• Finding and searching events\n'
           '• Registering for events\n'
           '• Viewing your registrations & QR codes\n'
           '• Event summaries and analytics\n'
           '• Exporting PDFs\n\n'
           'How can I help you today?';
  }

  static String thanks() {
    return 'You\'re welcome! 😊 Is there anything else I can help you with?';
  }

  static String goodbye() {
    return 'Goodbye! Have a great day! 🎉 Feel free to come back if you need help with events.';
  }

  static String help() {
    return '🤖 **Here\'s what I can do:**\n\n'
           '**📅 Events**\n'
           '• "Show current events"\n'
           '• "Events this week"\n'
           '• "Find tech workshops"\n'
           '• "Events in Lahore"\n\n'
           '**📝 Registration**\n'
           '• "Register me for [event name]"\n'
           '• "Show my registered events"\n'
           '• "Show my QR code"\n\n'
           '**📊 Summaries**\n'
           '• "Weekly digest"\n'
           '• "Event analytics"\n'
           '• "Summary of events"\n\n'
           '**📄 PDFs**\n'
           '• "Export current events PDF"\n'
           '• "PDF of my registrations"\n\n'
           '**❓ Help**\n'
           '• "Where do I find..."\n'
           '• "Tips for events"\n'
           '• Event FAQs';
  }

  static String tips() {
    return '💡 **Tips for Event Sphere:**\n\n'
           '1. **Bookmark events** you\'re interested in so you don\'t forget!\n\n'
           '2. **Register early** – popular events fill up fast.\n\n'
           '3. **Check your QR code** before the event – you\'ll need it for attendance.\n\n'
           '4. **Enable notifications** to get reminders about your events.\n\n'
           '5. **Join societies** to discover events matching your interests.\n\n'
           '6. **Leave feedback** after events to help organizers improve!';
  }

  static String loginRequired() {
    return '🔐 Please login first to access this feature. Go to Profile > Login.';
  }

  static String noEventsFound() {
    return '😔 No events match your search. Try:\n'
           '• Using different keywords\n'
           '• Checking for typos\n'
           '• Broadening your search';
  }

  static String fallback() {
    return 'I\'m not sure about that. I can help you with:\n'
           '• Event information & search\n'
           '• Registration & QR codes\n'
           '• Summaries & analytics\n'
           '• PDF exports\n\n'
           'Type "help" for more options!';
  }

  // ============================================================================
  // DYNAMIC RESPONSES
  // ============================================================================

  /// Format event list for display
  static String formatEventList(List<Event> events, String title) {
    if (events.isEmpty) {
      return '📭 No $title found.';
    }

    final buffer = StringBuffer('📅 **$title** (${events.length})\n\n');

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final dateStr = DateFormat('MMM d, yyyy').format(event.date);
      final timeStr = DateFormat('h:mm a').format(event.date);

      buffer.writeln('**${i + 1}. ${event.title}**');
      buffer.writeln('📍 ${event.venue}');
      buffer.writeln('🗓️ $dateStr at $timeStr');
      buffer.writeln('🏷️ ${event.category}');
      if (event.isDeleted) {
        buffer.writeln('🗃️ Archived');
      } else if (event.isFull) {
        buffer.writeln('⚠️ FULL');
      }
      buffer.writeln('');
    }

    buffer.writeln('💡 Ask me to "register for [event name]" or "show details of [event name]"');

    return buffer.toString();
  }

  /// Format single event details
  static String formatEventDetails(Event event) {
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.date);
    final timeStr = DateFormat('h:mm a').format(event.date);

    return '📌 **${event.title}**\n\n'
           '🗓️ **Date:** $dateStr\n'
           '🕐 **Time:** $timeStr\n'
           '📍 **Venue:** ${event.venue}\n'
           '🏷️ **Category:** ${event.category}\n'
           '👥 **Capacity:** ${event.currentAttendees}/${event.maxAttendees ?? '∞'}\n'
           '${event.isFull ? '⚠️ Event is FULL\n' : ''}\n'
           '📝 **Description:**\n${event.description}\n\n'
           '${event.isFull ? 'You can join the waitlist.' : 'Say "register me for ${event.title}" to sign up!'}';
  }

  /// Format user registrations
  static String formatUserRegistrations(List<Event> events) {
    if (events.isEmpty) {
      return '📭 You haven\'t registered for any events yet.\n\n'
             'Say "show current events" to find events to join!';
    }

    final buffer = StringBuffer('🎫 **Your Registered Events** (${events.length})\n\n');
    final now = DateTime.now();

    for (final event in events) {
      final dateStr = DateFormat('MMM d').format(event.date);
      final isUpcoming = event.date.isAfter(now);
      final status = isUpcoming ? '🟢 Upcoming' : '✅ Completed';

      buffer.writeln('**${event.title}**');
      buffer.writeln('$status • $dateStr');
      buffer.writeln('');
    }

    buffer.writeln('💡 Ask for "my QR for [event name]" to see your ticket.');

    return buffer.toString();
  }

  /// Format recommendations
  static String formatRecommendations(List<Event> events) {
    if (events.isEmpty) {
      return '📭 No recommendations available right now. Check back later!';
    }

    final buffer = StringBuffer('⭐ **Recommended Events for You**\n\n');

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final dateStr = DateFormat('MMM d').format(event.date);

      buffer.writeln('${i + 1}. **${event.title}**');
      buffer.writeln('   📍 ${event.venue} • 🗓️ $dateStr');
      buffer.writeln('');
    }

    buffer.writeln('💡 Say "register for [event name]" to sign up!');

    return buffer.toString();
  }

  /// Format weekly digest
  static String formatWeeklyDigest(Map<String, dynamic> digest) {
    final events = digest['events'] as List<Event>? ?? [];
    final weekStart = digest['weekStart'] ?? '';
    final weekEnd = digest['weekEnd'] ?? '';

    if (events.isEmpty) {
      return '📅 **Weekly Digest ($weekStart - $weekEnd)**\n\n'
             'No events scheduled this week. Check back later!';
    }

    final buffer = StringBuffer('📅 **Weekly Digest ($weekStart - $weekEnd)**\n\n');
    buffer.writeln('You have **${events.length}** event(s) coming up:\n');

    for (final event in events) {
      final dayName = DateFormat('EEEE').format(event.date);
      final timeStr = DateFormat('h:mm a').format(event.date);

      buffer.writeln('• **${event.title}**');
      buffer.writeln('  $dayName at $timeStr');
    }

    buffer.writeln('\n💡 Would you like this as a PDF?');

    return buffer.toString();
  }

  /// Format stats/analytics
  static String formatStats(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    final upcoming = stats['upcoming'] ?? 0;
    final past = stats['past'] ?? 0;
    final categories = stats['categories'] as Map<String, int>? ?? {};

    final buffer = StringBuffer('📊 **Event Analytics**\n\n');

    buffer.writeln('**Total Events:** $total');
    buffer.writeln('**Upcoming:** $upcoming');
    buffer.writeln('**Past:** $past\n');

    if (categories.isNotEmpty) {
      buffer.writeln('**By Category:**');
      categories.forEach((cat, count) {
        buffer.writeln('• $cat: $count');
      });
    }

    return buffer.toString();
  }

  /// Format navigation help
  static String formatWhereToFind(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('event') || lowerQuery.contains('browse')) {
      return '📍 **Finding Events:**\n\n'
             'Go to **Home > Events** tab or tap the Events icon in the bottom navigation.\n\n'
             'You can filter by category using the filter chips at the top!';
    }

    if (lowerQuery.contains('register') || lowerQuery.contains('sign up')) {
      return '📍 **How to Register:**\n\n'
             '1. Go to Events and find the event\n'
             '2. Tap on the event card\n'
             '3. Tap the "Register" button\n'
             '4. Your QR code will be generated!\n\n'
             'Or just ask me: "Register me for [event name]"';
    }

    if (lowerQuery.contains('qr') || lowerQuery.contains('ticket')) {
      return '📍 **Finding Your QR Code:**\n\n'
             'Go to **My Events** from the home screen. Tap on any registered event to see your QR code.\n\n'
             'Show this QR at the venue for attendance!';
    }

    if (lowerQuery.contains('society') || lowerQuery.contains('group')) {
      return '📍 **Finding Societies:**\n\n'
             'Go to **Home > Societies** tab. You can browse all societies and join the ones you\'re interested in!';
    }

    if (lowerQuery.contains('profile') || lowerQuery.contains('settings')) {
      return '📍 **Profile & Settings:**\n\n'
             'Tap the **Profile** icon in the bottom navigation. From there you can:\n'
             '• Edit your profile\n'
             '• Change password\n'
             '• Update notification settings\n'
             '• View your stats';
    }

    if (lowerQuery.contains('bookmark') || lowerQuery.contains('save')) {
      return '📍 **Bookmarking Events:**\n\n'
             'Tap the bookmark icon (🔖) on any event card to save it.\n\n'
             'Find all your bookmarks in **Home > Bookmarks**.';
    }

    return '📍 Try navigating to:\n\n'
           '• **Events** – Browse all events\n'
           '• **My Events** – Your registrations\n'
           '• **Societies** – Student groups\n'
           '• **Bookmarks** – Saved events\n'
           '• **Profile** – Settings & stats\n\n'
           'What are you looking for specifically?';
  }

  /// Format registration result
  static String formatRegistrationResult(Map<String, dynamic> result) {
    if (result['success'] == true) {
      return '✅ ${result['message']}\n\n'
             '🎫 Your QR code is ready! Go to "My Events" to view it.\n\n'
             'Don\'t forget to show your QR code at the venue!';
    } else {
      return '❌ ${result['message']}\n\n'
             'Need help? Try asking me something else.';
    }
  }

  /// Ask for PDF export
  static String askForPdf(String listType) {
    return '\n\n📄 Would you like this as a PDF? Say "export $listType pdf"';
  }
}
