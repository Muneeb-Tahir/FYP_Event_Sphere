// lib/services/chatbot_service.dart
// Event Sphere AI Chatbot Service - Rules-based with Database Integration

import 'dart:async';
import 'chatbot/intent_recognizer.dart';
import 'chatbot/database_handler.dart';
import 'chatbot/response_builder.dart';
import 'chatbot/pdf_generator.dart';
import 'auth_service.dart';
import 'resource_service.dart';
import 'logging_service.dart';
import '../models/event.dart';

/// Represents a chat message
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });
}

/// Types of messages for UI rendering
enum MessageType {
  text,
  eventList,
  eventDetails,
  registration,
  qrCode,
  pdfReady,
  actionRequired,
}

/// Chat response with optional actions
class ChatResponse {
  final String message;
  final MessageType type;
  final List<Event>? events;
  final Event? event;
  final List<ChatAction>? actions;
  final Map<String, dynamic>? data;

  ChatResponse({
    required this.message,
    this.type = MessageType.text,
    this.events,
    this.event,
    this.actions,
    this.data,
  });
}

/// Action buttons for chat messages
class ChatAction {
  final String label;
  final String actionType;
  final Map<String, dynamic>? params;

  ChatAction({
    required this.label,
    required this.actionType,
    this.params,
  });
}

/// Main Chatbot Service
class ChatbotService {

  // Store last context for follow-up questions
  static List<Event>? _lastEventList;
  static Event? _lastEvent;

  // ============================================================================
  // MAIN ENTRY POINT
  // ============================================================================

  /// Process user message and return response
  static Future<ChatResponse> sendMessage(String userMessage) async {
    // Small delay for natural feel
    await Future.delayed(const Duration(milliseconds: 300));

    // Recognize intent
    final intent = IntentRecognizer.recognize(userMessage);

    // Route to appropriate handler
    switch (intent.type) {
      // Greetings
      case IntentTypes.greeting:
        return ChatResponse(message: ChatResponseBuilder.greeting());

      case IntentTypes.thanks:
        return ChatResponse(message: ChatResponseBuilder.thanks());

      case IntentTypes.goodbye:
        return ChatResponse(message: ChatResponseBuilder.goodbye());

      case IntentTypes.help:
        return ChatResponse(message: ChatResponseBuilder.help());

      case IntentTypes.tips:
        return ChatResponse(message: ChatResponseBuilder.tips());

      // Event listing
      case IntentTypes.listCurrentEvents:
        return await _handleListCurrentEvents();

      case IntentTypes.listPastEvents:
        return await _handleListPastEvents();

      case IntentTypes.listAllEvents:
        return await _handleListAllEvents();

      // Event search
      case IntentTypes.eventSearch:
        return await _handleEventSearch(intent.params);

      // Event details
      case IntentTypes.eventInfo:
        return await _handleEventInfo(intent.params);

      // Registration
      case IntentTypes.registerEvent:
        return await _handleRegisterEvent(intent.params);

      case IntentTypes.showMyRegistrations:
        return await _handleShowRegistrations();

      case IntentTypes.showAttendedEvents:
        return await _handleShowAttendedEvents();

      // QR Code
      case IntentTypes.showQr:
      case IntentTypes.showTicket:
        return await _handleShowQr(intent.params);

      // Recommendations
      case IntentTypes.getRecommendations:
        return await _handleRecommendations();

      // Analytics
      case IntentTypes.analytics:
        return await _handleAnalytics();

      case IntentTypes.weeklyDigest:
        return await _handleWeeklyDigest();

      case IntentTypes.eventSummary:
      case IntentTypes.monthSummary:
        return await _handleEventSummary();

      // Navigation
      case IntentTypes.whereToFind:
        return _handleWhereToFind(intent.params['query'] ?? userMessage);

      // FAQs
      case IntentTypes.faq:
        return await _handleFaq(intent.params);

      // PDF Generation
      case IntentTypes.generatePdf:
        return await _handleGeneratePdf(intent.params);

      // Unknown
      default:
        return ChatResponse(message: ChatResponseBuilder.fallback());
    }
  }

  // ============================================================================
  // INTENT HANDLERS
  // ============================================================================

  static Future<ChatResponse> _handleListCurrentEvents() async {
    final events = await ChatDatabaseHandler.getCurrentEvents();
    _lastEventList = events;

    return ChatResponse(
      message: ChatResponseBuilder.formatEventList(events, 'Current Events'),
      type: MessageType.eventList,
      events: events,
      actions: events.isNotEmpty ? [
        ChatAction(label: '📄 Export PDF', actionType: 'export_pdf', params: {'type': 'current_events'}),
      ] : null,
    );
  }

  static Future<ChatResponse> _handleListPastEvents() async {
    final events = await ChatDatabaseHandler.getPastEvents(limit: 100);
    _lastEventList = events;

    if (events.isEmpty) {
      return ChatResponse(
        message: '📭 No past events found.',
        type: MessageType.text,
      );
    }

    // Generate PDF for past events list
    final pdfSuccess = await ChatPdfGenerator.generateAndShareEventListPdf(
      events: events,
      title: 'Past Events',
      subtitle: '${events.length} archived/past event(s)',
    );

    // Collect all resources from all past events and generate ZIP
    List<EventResource> allResources = [];
    LoggingService.info('Found ${events.length} past events, collecting resources');
    for (final event in events) {
      final eventResources = await ResourceService.getEventResources(event.id);
      LoggingService.debug('Event "${event.title}" has ${eventResources.length} resources');
      allResources.addAll(eventResources);
    }
    LoggingService.info('Total resources collected: ${allResources.length}');

    bool resourcesSuccess = false;
    if (allResources.isNotEmpty) {
      LoggingService.debug('Generating ZIP for ${allResources.length} resources from past events');
      resourcesSuccess = await ChatPdfGenerator.generateEventResourcesZip(
        event: Event(
          id: 'all_past_events',
          title: 'All_Past_Events_Resources',
          description: '',
          date: DateTime.now(),
          venue: '',
          societyId: '',
          createdBy: '',
          approvalStatus: 'approved',
        ),
        resources: allResources,
      );
    }

    String message;
    if (pdfSuccess) {
      if (allResources.isNotEmpty && resourcesSuccess) {
        message = '📄 **Past Events Generated!**\n\n'
                  'I\'ve created 2 files for you:\n'
                  '1. **Past Events PDF** - ${events.length} event(s) summary\n'
                  '2. **Resources ZIP** - ${allResources.length} resource file(s)\n\n'
                  '📥 Both downloads should appear.';
      } else if (allResources.isNotEmpty && !resourcesSuccess) {
        message = '📄 **Past Events PDF Generated!**\n\n'
                  '${events.length} past event(s) exported.\n\n'
                  '⚠️ Resource files could not be downloaded.';
      } else {
        message = '📄 **Past Events PDF Generated!**\n\n'
                  'I\'ve created a PDF containing ${events.length} past/archived event(s).\n\n'
                  '📥 The download should start automatically.\n\n'
                  'ℹ️ No attached resources found for these events.';
      }
      return ChatResponse(
        message: message,
        type: MessageType.pdfReady,
        events: events,
      );
    } else {
      return ChatResponse(
        message: '❌ Failed to generate the Past Events PDF. Please try again.',
        type: MessageType.text,
      );
    }
  }


  static Future<ChatResponse> _handleListAllEvents() async {
    final events = await ChatDatabaseHandler.getAllEvents();
    _lastEventList = events;

    return ChatResponse(
      message: ChatResponseBuilder.formatEventList(events, 'All Events'),
      type: MessageType.eventList,
      events: events,
      actions: events.isNotEmpty ? [
        ChatAction(label: '📄 Export PDF', actionType: 'export_pdf', params: {'type': 'all_events'}),
      ] : null,
    );
  }

  static Future<ChatResponse> _handleEventSearch(Map<String, dynamic> params) async {
    final query = params['query'] ?? '';
    final events = await ChatDatabaseHandler.searchEvents(query, filters: params);
    _lastEventList = events;

    if (events.isEmpty) {
      return ChatResponse(message: ChatResponseBuilder.noEventsFound());
    }

    String title = 'Search Results';
    if (params.containsKey('dateFilter')) title = 'Events ${params['dateFilter'].toString().replaceAll('_', ' ')}';
    if (params.containsKey('location')) title = 'Events in ${params['location']}';
    if (params.containsKey('category')) title = '${params['category']} Events';

    return ChatResponse(
      message: ChatResponseBuilder.formatEventList(events, title),
      type: MessageType.eventList,
      events: events,
    );
  }

  static Future<ChatResponse> _handleEventInfo(Map<String, dynamic> params) async {
    final eventName = params['eventName'] ?? '';

    if (eventName.isEmpty) {
      // Use last event if available
      if (_lastEvent != null) {
        // Check if it's a past/deleted event - generate PDF instead
        if (_lastEvent!.isDeleted || _lastEvent!.date.isBefore(DateTime.now())) {
          return _generatePastEventPdfs(_lastEvent!);
        }
        return ChatResponse(
          message: ChatResponseBuilder.formatEventDetails(_lastEvent!),
          type: MessageType.eventDetails,
          event: _lastEvent,
          actions: [
            ChatAction(label: '✅ Register', actionType: 'register', params: {'eventId': _lastEvent!.id}),
          ],
        );
      }
      return ChatResponse(message: 'Which event would you like to know about? Please provide the event name.');
    }

    final event = await ChatDatabaseHandler.getEventByName(eventName);

    if (event == null) {
      return ChatResponse(message: 'I couldn\'t find an event matching "$eventName". Try a different name or say "show events" to see all events.');
    }

    _lastEvent = event;

    // Check if it's a past/deleted event - generate PDF instead of showing in chat
    if (event.isDeleted || event.date.isBefore(DateTime.now())) {
      return _generatePastEventPdfs(event);
    }

    return ChatResponse(
      message: ChatResponseBuilder.formatEventDetails(event),
      type: MessageType.eventDetails,
      event: event,
      actions: !event.isFull ? [
        ChatAction(label: '✅ Register', actionType: 'register', params: {'eventId': event.id}),
      ] : null,
    );
  }

  /// Generate PDFs for past/deleted events (details + resources)
  static Future<ChatResponse> _generatePastEventPdfs(Event event) async {
    // Fetch event resources
    final resources = await ResourceService.getEventResources(event.id);

    // Generate both PDFs and share them together
    final results = await ChatPdfGenerator.generatePastEventPdfs(
      event: event,
      resources: resources,
    );

    final detailsSuccess = results['details'] ?? false;
    final resourcesSuccess = results['resources'] ?? false;
    final resourcesType = results['resourcesType'] ?? 'none';

    String message;
    if (detailsSuccess) {
      if (resources.isNotEmpty && resourcesSuccess) {
        final resourceFileType = resourcesType == 'zip' ? 'ZIP' : 'PDF';
        message = '**Past Event: ${event.title}**\n\n'
                  'I\'ve prepared 2 files for you:\n'
                  '1. **Event Details** (PDF) - Complete event information\n'
                  '2. **Event Resources** ($resourceFileType) - ${resources.length} resource(s)\n\n'
                  'Both files should appear in the share dialog.';
      } else if (resources.isNotEmpty && !resourcesSuccess) {
        message = '**Past Event: ${event.title}**\n\n'
                  'Event details PDF generated successfully.\n\n'
                  'Note: Resources file could not be generated.';
      } else {
        message = '**Past Event: ${event.title}**\n\n'
                  'I\'ve generated a PDF with the complete event details.\n\n'
                  'This event has no attached resources.';
      }
    } else {
      message = 'Sorry, I couldn\'t generate the files. Please try again.';
    }

    return ChatResponse(
      message: message,
      type: MessageType.pdfReady,
      event: event,
      data: {'resourceCount': resources.length, 'resourcesType': resourcesType},
    );
  }

  static Future<ChatResponse> _handleRegisterEvent(Map<String, dynamic> params) async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return ChatResponse(message: ChatResponseBuilder.loginRequired());
    }

    final eventName = params['eventName'] ?? '';
    Event? event;

    if (eventName.isEmpty && _lastEvent != null) {
      event = _lastEvent;
    } else if (eventName.isNotEmpty) {
      event = await ChatDatabaseHandler.getEventByName(eventName);
    }

    if (event == null) {
      return ChatResponse(message: 'Which event would you like to register for? Please provide the event name.');
    }

    final result = await ChatDatabaseHandler.registerForEvent(event.id);

    return ChatResponse(
      message: ChatResponseBuilder.formatRegistrationResult(result),
      type: result['success'] == true ? MessageType.registration : MessageType.text,
    );
  }

  static Future<ChatResponse> _handleShowRegistrations() async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return ChatResponse(message: ChatResponseBuilder.loginRequired());
    }

    final events = await ChatDatabaseHandler.getUserRegistrations();
    _lastEventList = events;

    return ChatResponse(
      message: ChatResponseBuilder.formatUserRegistrations(events),
      type: MessageType.eventList,
      events: events,
      actions: events.isNotEmpty ? [
        ChatAction(label: '📄 Export PDF', actionType: 'export_pdf', params: {'type': 'my_registrations'}),
      ] : null,
    );
  }

  static Future<ChatResponse> _handleShowAttendedEvents() async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return ChatResponse(message: ChatResponseBuilder.loginRequired());
    }

    final events = await ChatDatabaseHandler.getUserAttendedEvents();

    if (events.isEmpty) {
      return ChatResponse(message: '📭 You haven\'t attended any events yet.');
    }

    return ChatResponse(
      message: ChatResponseBuilder.formatEventList(events, 'Events You Attended'),
      type: MessageType.eventList,
      events: events,
    );
  }

  static Future<ChatResponse> _handleShowQr(Map<String, dynamic> params) async {
    final user = AuthService.getCurrentUser();
    if (user == null) {
      return ChatResponse(message: ChatResponseBuilder.loginRequired());
    }

    String eventName = params['eventName'] ?? '';
    Event? event;

    if (eventName.isEmpty && _lastEvent != null) {
      event = _lastEvent;
    } else if (eventName.isNotEmpty) {
      event = await ChatDatabaseHandler.getEventByName(eventName);
    }

    if (event == null) {
      return ChatResponse(
        message: '🎫 To view your QR code:\n\n'
                 '1. Go to **My Events** from the home screen\n'
                 '2. Tap on the event\n'
                 '3. Your QR code will be displayed\n\n'
                 'Or tell me which event\'s QR you need.',
      );
    }

    final isRegistered = await ChatDatabaseHandler.isUserRegistered(event.id);

    if (!isRegistered) {
      return ChatResponse(
        message: '❌ You\'re not registered for "${event.title}".\n\n'
                 'Would you like to register? Say "register me for ${event.title}"',
      );
    }

    return ChatResponse(
      message: '🎫 **Your ticket for ${event.title}:**\n\n'
               'Go to **My Events > ${event.title}** to view and download your QR code.\n\n'
               '📍 ${event.venue}\n'
               '🗓️ ${event.date.toString().split(' ')[0]}',
      type: MessageType.qrCode,
      event: event,
    );
  }

  static Future<ChatResponse> _handleRecommendations() async {
    final events = await ChatDatabaseHandler.getRecommendations();
    _lastEventList = events;

    return ChatResponse(
      message: ChatResponseBuilder.formatRecommendations(events),
      type: MessageType.eventList,
      events: events,
    );
  }

  static Future<ChatResponse> _handleAnalytics() async {
    final stats = await ChatDatabaseHandler.getEventStats();

    return ChatResponse(
      message: ChatResponseBuilder.formatStats(stats),
      data: stats,
    );
  }

  static Future<ChatResponse> _handleWeeklyDigest() async {
    final digest = await ChatDatabaseHandler.getWeeklyDigest();
    final events = digest['events'] as List<Event>? ?? [];
    _lastEventList = events;

    return ChatResponse(
      message: ChatResponseBuilder.formatWeeklyDigest(digest),
      type: MessageType.eventList,
      events: events,
      actions: events.isNotEmpty ? [
        ChatAction(label: '📄 Export PDF', actionType: 'export_pdf', params: {'type': 'weekly_digest'}),
      ] : null,
    );
  }

  static Future<ChatResponse> _handleEventSummary() async {
    final stats = await ChatDatabaseHandler.getEventStats();
    final events = await ChatDatabaseHandler.getCurrentEvents(limit: 5);

    final message = '📊 **Event Summary**\n\n'
                    '${ChatResponseBuilder.formatStats(stats)}\n\n'
                    '**Top Upcoming Events:**\n'
                    '${events.map((e) => '• ${e.title}').join('\n')}';

    return ChatResponse(
      message: message,
      data: stats,
    );
  }

  static ChatResponse _handleWhereToFind(String query) {
    return ChatResponse(
      message: ChatResponseBuilder.formatWhereToFind(query),
    );
  }

  static Future<ChatResponse> _handleFaq(Map<String, dynamic> params) async {
    final query = params['query'] ?? '';
    final eventName = params['eventName'] ?? '';

    // If asking about specific event
    if (eventName.isNotEmpty) {
      final event = await ChatDatabaseHandler.getEventByName(eventName);
      if (event != null) {
        _lastEvent = event;
        return ChatResponse(
          message: ChatResponseBuilder.formatEventDetails(event),
          type: MessageType.eventDetails,
          event: event,
        );
      }
    }

    // General FAQ responses
    if (query.contains('free')) {
      return ChatResponse(
        message: '💰 **Event Pricing:**\n\n'
                 'Most events on Event Sphere are free! Some special events may have fees.\n\n'
                 'Say "show free events" to find free events.',
      );
    }

    if (query.contains('time') || query.contains('when')) {
      if (_lastEvent != null) {
        return ChatResponse(
          message: '🕐 **${_lastEvent!.title}** starts at:\n'
                   '${_lastEvent!.date.toString()}',
        );
      }
      return ChatResponse(message: 'Which event\'s time do you want to know?');
    }

    if (query.contains('location') || query.contains('where') || query.contains('venue')) {
      if (_lastEvent != null) {
        return ChatResponse(
          message: '📍 **${_lastEvent!.title}** is at:\n'
                   '${_lastEvent!.venue}',
        );
      }
      return ChatResponse(message: 'Which event\'s venue do you want to know?');
    }

    return ChatResponse(message: ChatResponseBuilder.formatWhereToFind(query));
  }

  static Future<ChatResponse> _handleGeneratePdf(Map<String, dynamic> params) async {
    final pdfType = params['pdfType'] ?? 'all_events';

    List<Event> events = [];
    String title = 'Events';

    switch (pdfType) {
      case 'current_events':
        events = await ChatDatabaseHandler.getCurrentEvents(limit: 50);
        title = 'Current Events';
        break;
      case 'past_events':
        events = await ChatDatabaseHandler.getPastEvents(limit: 50);
        title = 'Past Events';
        break;
      case 'my_registrations':
        events = await ChatDatabaseHandler.getUserRegistrations();
        title = 'My Registrations';
        final user = AuthService.getCurrentUser();
        if (user != null) {
          final success = await ChatPdfGenerator.generateAndShareRegistrationsPdf(
            events: events,
            userName: user.name,
          );
          return ChatResponse(
            message: success
                ? '📄 Your registrations PDF is ready! Share it via the dialog.'
                : '❌ Failed to generate PDF. Please try again.',
            type: MessageType.pdfReady,
          );
        }
        break;
      case 'weekly_digest':
        final digest = await ChatDatabaseHandler.getWeeklyDigest();
        events = digest['events'] as List<Event>? ?? [];
        final weekRange = '${digest['weekStart']} - ${digest['weekEnd']}';
        final success = await ChatPdfGenerator.generateWeeklyDigestPdf(
          events: events,
          weekRange: weekRange,
        );
        return ChatResponse(
          message: success
              ? '📄 Weekly digest PDF is ready! Share it via the dialog.'
              : '❌ Failed to generate PDF. Please try again.',
          type: MessageType.pdfReady,
        );
      default:
        events = await ChatDatabaseHandler.getAllEvents(limit: 50);
        title = 'All Events';
    }

    // Use last event list if available and no specific type
    if (events.isEmpty && _lastEventList != null) {
      events = _lastEventList!;
    }

    if (events.isEmpty) {
      return ChatResponse(message: '📭 No events to export.');
    }

    final success = await ChatPdfGenerator.generateAndShareEventListPdf(
      events: events,
      title: title,
    );

    return ChatResponse(
      message: success
          ? '📄 **$title** PDF is ready! Share it via the dialog.'
          : '❌ Failed to generate PDF. Please try again.',
      type: MessageType.pdfReady,
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  /// Execute action from action button
  static Future<ChatResponse> executeAction(ChatAction action) async {
    switch (action.actionType) {
      case 'register':
        final eventId = action.params?['eventId'];
        if (eventId != null) {
          final result = await ChatDatabaseHandler.registerForEvent(eventId);
          return ChatResponse(
            message: ChatResponseBuilder.formatRegistrationResult(result),
            type: result['success'] == true ? MessageType.registration : MessageType.text,
          );
        }
        break;
      case 'export_pdf':
        return await _handleGeneratePdf(action.params ?? {});
    }

    return ChatResponse(message: 'Action not recognized.');
  }

  // ============================================================================
  // SUGGESTIONS
  // ============================================================================

  /// Get quick suggestion chips
  static List<String> getQuickSuggestions() {
    return [
      'Show current events',
      'My registered events',
      'Recommend events',
      'Events this week',
      'Help',
    ];
  }

  // ============================================================================
  // LEGACY SUPPORT (for existing ChatMessage class usage)
  // ============================================================================

  /// Legacy method - returns ChatMessage for backwards compatibility
  static Future<ChatMessage> sendMessageLegacy(String userMessage) async {
    final response = await sendMessage(userMessage);

    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      role: 'assistant',
      content: response.message,
      timestamp: DateTime.now(),
      type: response.type,
      metadata: {
        'events': response.events,
        'event': response.event,
        'actions': response.actions,
        'data': response.data,
      },
    );
  }
}
