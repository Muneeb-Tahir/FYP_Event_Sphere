// lib/services/chatbot/intent_recognizer.dart
// Rules-based intent recognition for Event Sphere Chatbot

/// Represents a recognized intent from user message
class ChatIntent {
  final String type;
  final Map<String, dynamic> params;
  final double confidence;

  ChatIntent({
    required this.type,
    this.params = const {},
    this.confidence = 1.0,
  });

  @override
  String toString() => 'ChatIntent($type, params: $params)';
}

/// Intent types supported by the chatbot
class IntentTypes {
  // Event-related
  static const String eventSearch = 'event_search';
  static const String eventInfo = 'event_info';
  static const String listCurrentEvents = 'list_current_events';
  static const String listPastEvents = 'list_past_events';
  static const String listAllEvents = 'list_all_events';

  // Registration
  static const String registerEvent = 'register_event';
  static const String unregisterEvent = 'unregister_event';
  static const String showMyRegistrations = 'show_my_registrations';
  static const String showAttendedEvents = 'show_attended_events';

  // QR/Ticket
  static const String showQr = 'show_qr';
  static const String showTicket = 'show_ticket';

  // Recommendations
  static const String getRecommendations = 'get_recommendations';

  // Analytics/Summaries
  static const String eventSummary = 'event_summary';
  static const String weeklyDigest = 'weekly_digest';
  static const String monthSummary = 'month_summary';
  static const String analytics = 'analytics';

  // Navigation/Help
  static const String whereToFind = 'where_to_find';
  static const String faq = 'faq';
  static const String tips = 'tips';
  static const String help = 'help';

  // PDF
  static const String generatePdf = 'generate_pdf';

  // Social
  static const String greeting = 'greeting';
  static const String thanks = 'thanks';
  static const String goodbye = 'goodbye';

  // Fallback
  static const String unknown = 'unknown';
}

/// Rules-based intent recognizer
class IntentRecognizer {

  /// Recognize intent from user message
  static ChatIntent recognize(String message) {
    final lower = message.toLowerCase().trim();

    // Greetings
    if (_matchesAny(lower, ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'assalam', 'salam'])) {
      return ChatIntent(type: IntentTypes.greeting);
    }

    // Thanks
    if (_matchesAny(lower, ['thank', 'thanks', 'thx', 'appreciate'])) {
      return ChatIntent(type: IntentTypes.thanks);
    }

    // Goodbye
    if (_matchesAny(lower, ['bye', 'goodbye', 'see you', 'later', 'exit', 'quit'])) {
      return ChatIntent(type: IntentTypes.goodbye);
    }

    // Help
    if (_matchesAny(lower, ['help', 'what can you do', 'commands', 'menu', 'options'])) {
      return ChatIntent(type: IntentTypes.help);
    }

    // PDF Generation
    if (_matchesAny(lower, ['pdf', 'download', 'export', 'generate report'])) {
      return ChatIntent(
        type: IntentTypes.generatePdf,
        params: _extractPdfType(lower),
      );
    }

    // QR Code / Ticket
    if (_matchesAny(lower, ['qr', 'qr code', 'ticket', 'my ticket', 'show ticket'])) {
      return ChatIntent(
        type: IntentTypes.showQr,
        params: _extractEventName(lower),
      );
    }

    // User's registrations
    if (_matchesAny(lower, ['my registered', 'my events', 'registered events', 'my registrations', 'show my'])) {
      if (lower.contains('attended') || lower.contains('past') || lower.contains('completed')) {
        return ChatIntent(type: IntentTypes.showAttendedEvents);
      }
      return ChatIntent(type: IntentTypes.showMyRegistrations);
    }

    // Registration intent
    if (_matchesAny(lower, ['register me', 'sign me up', 'join', 'enroll', 'book me'])) {
      return ChatIntent(
        type: IntentTypes.registerEvent,
        params: _extractEventName(lower),
      );
    }

    // Unregister
    if (_matchesAny(lower, ['unregister', 'cancel registration', 'leave event', 'drop out'])) {
      return ChatIntent(
        type: IntentTypes.unregisterEvent,
        params: _extractEventName(lower),
      );
    }

    // Recommendations
    if (_matchesAny(lower, ['recommend', 'suggestion', 'what should i', 'for me'])) {
      return ChatIntent(type: IntentTypes.getRecommendations);
    }

    // Analytics / Summaries
    if (_matchesAny(lower, ['analytics', 'stats', 'statistics', 'report'])) {
      return ChatIntent(type: IntentTypes.analytics);
    }

    if (_matchesAny(lower, ['summary', 'summarize', 'overview'])) {
      if (lower.contains('week')) {
        return ChatIntent(type: IntentTypes.weeklyDigest);
      }
      if (lower.contains('month')) {
        return ChatIntent(type: IntentTypes.monthSummary);
      }
      return ChatIntent(type: IntentTypes.eventSummary);
    }

    if (_matchesAny(lower, ['weekly digest', 'this week'])) {
      return ChatIntent(type: IntentTypes.weeklyDigest);
    }

    // Where to find / Navigation
    if (_matchesAny(lower, ['where', 'how to', 'how do i', 'navigate', 'find the'])) {
      return ChatIntent(
        type: IntentTypes.whereToFind,
        params: {'query': lower},
      );
    }

    // Tips
    if (_matchesAny(lower, ['tip', 'tips', 'advice', 'best practice'])) {
      return ChatIntent(type: IntentTypes.tips);
    }

    // Event listing
    if (_matchesAny(lower, ['all events', 'list events', 'show events', 'every event'])) {
      if (lower.contains('past') || lower.contains('previous') || lower.contains('completed')) {
        return ChatIntent(type: IntentTypes.listPastEvents);
      }
      if (lower.contains('current') || lower.contains('upcoming') || lower.contains('active')) {
        return ChatIntent(type: IntentTypes.listCurrentEvents);
      }
      return ChatIntent(type: IntentTypes.listAllEvents);
    }

    if (_matchesAny(lower, ['current events', 'upcoming events', 'active events', 'future events'])) {
      return ChatIntent(type: IntentTypes.listCurrentEvents);
    }

    if (_matchesAny(lower, ['past events', 'previous events', 'completed events', 'old events', 'history'])) {
      return ChatIntent(type: IntentTypes.listPastEvents);
    }

    // Event search with filters
    if (_matchesAny(lower, ['events', 'event']) || _matchesAny(lower, ['show', 'find', 'search', 'get'])) {
      final params = _extractSearchFilters(lower);
      if (params.isNotEmpty) {
        return ChatIntent(type: IntentTypes.eventSearch, params: params);
      }
    }

    // Specific event info
    if (_matchesAny(lower, ['about', 'details', 'info', 'tell me about', 'what is', 'when is', 'where is'])) {
      return ChatIntent(
        type: IntentTypes.eventInfo,
        params: _extractEventName(lower),
      );
    }

    // FAQ patterns
    if (_matchesAny(lower, ['what time', 'who is', 'is it free', 'cost', 'price', 'speaker', 'venue', 'location'])) {
      return ChatIntent(
        type: IntentTypes.faq,
        params: {'query': lower, ..._extractEventName(lower)},
      );
    }

    // Default: treat as event search if contains event-related words
    if (_containsEventRelated(lower)) {
      return ChatIntent(
        type: IntentTypes.eventSearch,
        params: {'query': lower},
      );
    }

    // Unknown
    return ChatIntent(type: IntentTypes.unknown, confidence: 0.5);
  }

  /// Check if message matches any of the patterns
  static bool _matchesAny(String message, List<String> patterns) {
    return patterns.any((p) => message.contains(p));
  }

  /// Check if message contains event-related words
  static bool _containsEventRelated(String message) {
    const eventWords = ['event', 'workshop', 'seminar', 'conference', 'meetup', 'session', 'talk', 'hackathon'];
    return eventWords.any((w) => message.contains(w));
  }

  /// Extract event name from message
  static Map<String, dynamic> _extractEventName(String message) {
    // Remove common phrases to isolate event name
    var cleaned = message
        .replaceAll(RegExp(r'register me for|sign me up for|about|details|info|tell me about|show|get|my|ticket|qr|for'), '')
        .trim();

    if (cleaned.isNotEmpty && cleaned.length > 2) {
      return {'eventName': cleaned};
    }
    return {};
  }

  /// Extract PDF type from message
  static Map<String, dynamic> _extractPdfType(String message) {
    if (message.contains('current') || message.contains('upcoming')) {
      return {'pdfType': 'current_events'};
    }
    if (message.contains('past') || message.contains('previous')) {
      return {'pdfType': 'past_events'};
    }
    if (message.contains('my') || message.contains('registered')) {
      return {'pdfType': 'my_registrations'};
    }
    if (message.contains('all')) {
      return {'pdfType': 'all_events'};
    }
    return {'pdfType': 'all_events'};
  }

  /// Extract search filters from message
  static Map<String, dynamic> _extractSearchFilters(String message) {
    final params = <String, dynamic>{};

    // Time filters
    if (message.contains('today')) {
      params['dateFilter'] = 'today';
    } else if (message.contains('tomorrow')) {
      params['dateFilter'] = 'tomorrow';
    } else if (message.contains('this week')) {
      params['dateFilter'] = 'this_week';
    } else if (message.contains('this month')) {
      params['dateFilter'] = 'this_month';
    }

    // Location filters (common Pakistan cities)
    for (final city in ['lahore', 'karachi', 'islamabad', 'rawalpindi', 'faisalabad', 'multan']) {
      if (message.contains(city)) {
        params['location'] = city;
        break;
      }
    }

    // Category filters
    for (final cat in ['tech', 'sports', 'music', 'art', 'academic', 'workshop', 'seminar', 'cultural']) {
      if (message.contains(cat)) {
        params['category'] = cat;
        break;
      }
    }

    // Department filters
    for (final dept in ['cs', 'computer science', 'it', 'electrical', 'mechanical', 'software', 'ai', 'data']) {
      if (message.contains(dept)) {
        params['department'] = dept;
        break;
      }
    }

    // Free events
    if (message.contains('free')) {
      params['isFree'] = true;
    }

    // General query
    if (params.isEmpty) {
      params['query'] = message;
    }

    return params;
  }
}
