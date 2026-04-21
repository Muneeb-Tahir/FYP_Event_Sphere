// test/models/event_test.dart
// Unit tests for Event model

import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/models/event.dart';

void main() {
  group('Event Model Tests', () {
    // Test data
    final testEventMap = {
      'id': 'test-event-id',
      'title': 'Test Event',
      'description': 'A test event description',
      'date': '2025-12-25T10:00:00.000Z',
      'venue': 'Test Venue',
      'society_id': 'society-123',
      'created_by': 'user-456',
      'approval_status': 'approved',
      'category': 'Tech',
      'image_url': 'https://example.com/image.jpg',
      'max_attendees': 100,
      'current_attendees': 50,
      'deleted_at': null,
    };

    group('fromMap factory', () {
      test('creates Event from valid map', () {
        final event = Event.fromMap(testEventMap);

        expect(event.id, 'test-event-id');
        expect(event.title, 'Test Event');
        expect(event.description, 'A test event description');
        expect(event.venue, 'Test Venue');
        expect(event.societyId, 'society-123');
        expect(event.createdBy, 'user-456');
        expect(event.approvalStatus, 'approved');
        expect(event.category, 'Tech');
        expect(event.imageUrl, 'https://example.com/image.jpg');
        expect(event.maxAttendees, 100);
        expect(event.currentAttendees, 50);
      });

      test('handles null values with defaults', () {
        final minimalMap = {
          'id': 'test-id',
          'title': 'Test',
          'description': 'Desc',
          'date': '2025-12-25T10:00:00.000Z',
          'venue': 'Venue',
        };

        final event = Event.fromMap(minimalMap);

        expect(event.societyId, '');
        expect(event.createdBy, '');
        expect(event.approvalStatus, 'pending');
        expect(event.category, 'Tech');
        expect(event.imageUrl, isNull);
        expect(event.maxAttendees, isNull);
        expect(event.currentAttendees, 0);
      });
    });

    group('toMap method', () {
      test('converts Event to valid map', () {
        final event = Event(
          id: 'test-id',
          title: 'Test Event',
          description: 'Description',
          date: DateTime.utc(2025, 12, 25, 10, 0, 0),
          venue: 'Test Venue',
          societyId: 'soc-123',
          createdBy: 'user-123',
          approvalStatus: 'approved',
          category: 'Sports',
          maxAttendees: 50,
          currentAttendees: 25,
        );

        final map = event.toMap();

        expect(map['id'], 'test-id');
        expect(map['title'], 'Test Event');
        expect(map['description'], 'Description');
        expect(map['venue'], 'Test Venue');
        expect(map['society_id'], 'soc-123');
        expect(map['created_by'], 'user-123');
        expect(map['approval_status'], 'approved');
        expect(map['category'], 'Sports');
        expect(map['max_attendees'], 50);
        expect(map['current_attendees'], 25);
      });
    });

    group('copyWith method', () {
      test('creates copy with updated fields', () {
        final original = Event.fromMap(testEventMap);
        final copy = original.copyWith(
          title: 'Updated Title',
          maxAttendees: 200,
        );

        expect(copy.title, 'Updated Title');
        expect(copy.maxAttendees, 200);
        // Original values preserved
        expect(copy.id, original.id);
        expect(copy.description, original.description);
        expect(copy.venue, original.venue);
      });

      test('returns same values when no changes specified', () {
        final original = Event.fromMap(testEventMap);
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.maxAttendees, original.maxAttendees);
      });
    });

    group('computed properties', () {
      test('isFull returns true when at capacity', () {
        final fullEvent = Event(
          id: 'test',
          title: 'Full Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: 100,
          currentAttendees: 100,
        );

        expect(fullEvent.isFull, true);
      });

      test('isFull returns false when not at capacity', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: 100,
          currentAttendees: 50,
        );

        expect(event.isFull, false);
      });

      test('isFull returns false when unlimited capacity', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: null,
          currentAttendees: 1000,
        );

        expect(event.isFull, false);
      });

      test('remainingSpots returns correct count', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: 100,
          currentAttendees: 75,
        );

        expect(event.remainingSpots, 25);
      });

      test('remainingSpots returns null for unlimited', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: null,
        );

        expect(event.remainingSpots, isNull);
      });

      test('capacityDisplay shows SOLD OUT when full', () {
        final fullEvent = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: 50,
          currentAttendees: 50,
        );

        expect(fullEvent.capacityDisplay, 'SOLD OUT');
      });

      test('capacityDisplay shows Unlimited when no limit', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: null,
        );

        expect(event.capacityDisplay, 'Unlimited');
      });

      test('capacityDisplay shows current/max when has capacity', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          maxAttendees: 100,
          currentAttendees: 45,
        );

        expect(event.capacityDisplay, '45 / 100');
      });

      test('isDeleted returns true when deletedAt is set', () {
        final deletedEvent = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          deletedAt: DateTime.now(),
        );

        expect(deletedEvent.isDeleted, true);
      });

      test('isDeleted returns false when deletedAt is null', () {
        final event = Event(
          id: 'test',
          title: 'Event',
          description: 'Desc',
          date: DateTime.now(),
          venue: 'Venue',
          societyId: 'soc',
          createdBy: 'user',
          approvalStatus: 'approved',
          deletedAt: null,
        );

        expect(event.isDeleted, false);
      });
    });
  });
}
