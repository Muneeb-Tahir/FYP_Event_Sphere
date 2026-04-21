// lib/providers/event_provider.dart
// Riverpod providers for event state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/logging_service.dart';
import '../core/result.dart';

/// Event list state
sealed class EventListState {
  const EventListState();
}

class EventListInitial extends EventListState {
  const EventListInitial();
}

class EventListLoading extends EventListState {
  const EventListLoading();
}

class EventListLoaded extends EventListState {
  final List<Event> events;
  final bool hasMore;
  const EventListLoaded(this.events, {this.hasMore = true});
}

class EventListError extends EventListState {
  final String message;
  const EventListError(this.message);
}

/// Event list notifier
class EventListNotifier extends StateNotifier<EventListState> {
  EventListNotifier() : super(const EventListInitial()) {
    loadEvents();
  }

  int _currentPage = 0;
  final int _pageSize = 20;
  List<Event> _allEvents = [];

  /// Load events (initial load or refresh)
  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _allEvents = [];
    }

    state = const EventListLoading();
    try {
      final events = await EventService.getAllEvents();
      _allEvents = events;
      state = EventListLoaded(events, hasMore: events.length >= _pageSize);
      LoggingService.database('select', 'events', count: events.length);
    } catch (e) {
      LoggingService.error('Failed to load events', e);
      state = EventListError(e.toString());
    }
  }

  /// Load more events (pagination)
  Future<void> loadMore() async {
    if (state is! EventListLoaded) return;
    final currentState = state as EventListLoaded;
    if (!currentState.hasMore) return;

    _currentPage++;
    try {
      final result = await EventService.getEventsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );
      _allEvents = [..._allEvents, ...result.items];
      state = EventListLoaded(_allEvents, hasMore: result.hasMore);
    } catch (e) {
      LoggingService.error('Failed to load more events', e);
      // Keep current state but log error
    }
  }

  /// Search events
  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      loadEvents(refresh: true);
      return;
    }

    state = const EventListLoading();
    try {
      final events = await EventService.searchEvents(query);
      state = EventListLoaded(events, hasMore: false);
      LoggingService.database('search', 'events', count: events.length);
    } catch (e) {
      LoggingService.error('Failed to search events', e);
      state = EventListError(e.toString());
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? category) async {
    state = const EventListLoading();
    try {
      List<Event> events;
      if (category == null || category.isEmpty) {
        events = await EventService.getAllEvents();
      } else {
        events = await EventService.getEventsByCategory(category);
      }
      state = EventListLoaded(events, hasMore: false);
      LoggingService.userAction('filter_events', {'category': category});
    } catch (e) {
      LoggingService.error('Failed to filter events', e);
      state = EventListError(e.toString());
    }
  }
}

/// Single event state
sealed class EventDetailState {
  const EventDetailState();
}

class EventDetailLoading extends EventDetailState {
  const EventDetailLoading();
}

class EventDetailLoaded extends EventDetailState {
  final Event event;
  const EventDetailLoaded(this.event);
}

class EventDetailError extends EventDetailState {
  final String message;
  const EventDetailError(this.message);
}

/// Event detail notifier
class EventDetailNotifier extends StateNotifier<EventDetailState> {
  EventDetailNotifier(this.eventId) : super(const EventDetailLoading()) {
    loadEvent();
  }

  final String eventId;

  Future<void> loadEvent() async {
    state = const EventDetailLoading();
    try {
      final event = await EventService.getEvent(eventId);
      if (event != null) {
        state = EventDetailLoaded(event);
      } else {
        state = const EventDetailError('Event not found');
      }
    } catch (e) {
      LoggingService.error('Failed to load event detail', e);
      state = EventDetailError(e.toString());
    }
  }

  Future<Result<void>> refreshEvent() async {
    try {
      final event = await EventService.getEvent(eventId);
      if (event != null) {
        state = EventDetailLoaded(event);
        return const Success(null);
      }
      return const Failure('Event not found');
    } catch (e) {
      return Failure(e.toString(), error: e);
    }
  }
}

// ==================== Providers ====================

/// Main events list provider
final eventsProvider = StateNotifierProvider<EventListNotifier, EventListState>((ref) {
  return EventListNotifier();
});

/// Events stream provider for real-time updates
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return EventService.getApprovedEventsStream();
});

/// Pending events stream for admins
final pendingEventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return EventService.getPendingEventsStream();
});

/// Single event detail provider (family for different event IDs)
final eventDetailProvider = StateNotifierProvider.family<EventDetailNotifier, EventDetailState, String>((ref, eventId) {
  return EventDetailNotifier(eventId);
});

/// Convenience provider for events list (when loaded)
final eventsListProvider = Provider<List<Event>>((ref) {
  final state = ref.watch(eventsProvider);
  return switch (state) {
    EventListLoaded(:final events) => events,
    _ => [],
  };
});

/// Events by society provider
final eventsBySocietyProvider = FutureProvider.family<List<Event>, String>((ref, societyId) async {
  return EventService.getEventsBySociety(societyId);
});

/// Events by creator provider
final eventsByCreatorProvider = FutureProvider.family<List<Event>, String>((ref, userId) async {
  return EventService.getEventsByCreator(userId);
});
