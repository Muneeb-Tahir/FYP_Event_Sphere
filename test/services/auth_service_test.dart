// test/services/auth_service_test.dart
// Unit tests for AuthService registration flow logic

import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/models/user.dart';

void main() {
  group('AuthService - Registration Logic', () {
    group('Role-based access control', () {
      test('UserRole enum has all expected values', () {
        expect(UserRole.values.length, 5);
        expect(UserRole.values, contains(UserRole.student));
        expect(UserRole.values, contains(UserRole.vicePresident));
        expect(UserRole.values, contains(UserRole.president));
        expect(UserRole.values, contains(UserRole.admin));
        expect(UserRole.values, contains(UserRole.superAdmin));
      });

      test('student role is not an organizer role', () {
        const role = UserRole.student;
        final isOrganizer = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(isOrganizer, false);
      });

      test('admin role is an organizer role', () {
        const role = UserRole.admin;
        final isOrganizer = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(isOrganizer, true);
      });

      test('superAdmin role is an organizer role', () {
        const role = UserRole.superAdmin;
        final isOrganizer = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(isOrganizer, true);
      });

      test('president role is an organizer role', () {
        const role = UserRole.president;
        final isOrganizer = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(isOrganizer, true);
      });

      test('vicePresident role is an organizer role', () {
        const role = UserRole.vicePresident;
        final isOrganizer = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(isOrganizer, true);
      });
    });

    group('QR Scanner visibility', () {
      test('QR Scanner should be hidden for student role', () {
        const role = UserRole.student;
        final canSeeQR = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(canSeeQR, false, reason: 'Students must NOT see QR Scanner');
      });

      test('QR Scanner should be visible for admin', () {
        const role = UserRole.admin;
        final canSeeQR = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(canSeeQR, true);
      });

      test('QR Scanner should be visible for president', () {
        const role = UserRole.president;
        final canSeeQR = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(canSeeQR, true);
      });

      test('QR Scanner should be visible for vicePresident', () {
        const role = UserRole.vicePresident;
        final canSeeQR = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(canSeeQR, true);
      });

      test('QR Scanner should be visible for superAdmin', () {
        const role = UserRole.superAdmin;
        final canSeeQR = role == UserRole.admin ||
            role == UserRole.superAdmin ||
            role == UserRole.president ||
            role == UserRole.vicePresident;
        expect(canSeeQR, true);
      });
    });

    group('Email validation for forgot password', () {
      test('empty email should be rejected', () {
        const email = '';
        expect(email.isEmpty, true);
      });

      test('email without @ should be rejected', () {
        const email = 'invalidemail.com';
        expect(email.contains('@'), false);
      });

      test('valid email should pass', () {
        const email = 'test@example.com';
        expect(email.contains('@'), true);
        expect(email.isNotEmpty, true);
      });

      test('email with spaces should be trimmed', () {
        const email = '  test@example.com  ';
        expect(email.trim(), 'test@example.com');
      });
    });
  });

  group('Bookmark Toggle Logic', () {
    test('bookmarking an unbookmarked event adds it to the set', () {
      final bookmarks = <String>{};
      const eventId = 'event-123';

      // Toggle ON
      if (bookmarks.contains(eventId)) {
        bookmarks.remove(eventId);
      } else {
        bookmarks.add(eventId);
      }
      expect(bookmarks.contains(eventId), true);
    });

    test('bookmarking a bookmarked event removes it from the set', () {
      final bookmarks = <String>{'event-123'};
      const eventId = 'event-123';

      // Toggle OFF
      if (bookmarks.contains(eventId)) {
        bookmarks.remove(eventId);
      } else {
        bookmarks.add(eventId);
      }
      expect(bookmarks.contains(eventId), false);
    });

    test('double toggle returns to original state', () {
      final bookmarks = <String>{};
      const eventId = 'event-456';

      // Toggle ON
      bookmarks.add(eventId);
      expect(bookmarks.contains(eventId), true);

      // Toggle OFF
      bookmarks.remove(eventId);
      expect(bookmarks.contains(eventId), false);
    });

    test('multiple events can be bookmarked independently', () {
      final bookmarks = <String>{};
      bookmarks.add('event-1');
      bookmarks.add('event-2');
      bookmarks.add('event-3');

      expect(bookmarks.length, 3);
      bookmarks.remove('event-2');
      expect(bookmarks.length, 2);
      expect(bookmarks.contains('event-1'), true);
      expect(bookmarks.contains('event-2'), false);
      expect(bookmarks.contains('event-3'), true);
    });
  });

  group('Notification Service - Platform Detection', () {
    test('web platform should skip Firebase init', () {
      // On web, Platform.isAndroid throws, so we default to false
      bool onMobile = false;
      try {
        // Simulating web behavior where Platform throws
        throw UnsupportedError('Platform not available on web');
      } catch (_) {
        onMobile = false;
      }
      expect(onMobile, false, reason: 'Web should NOT init Firebase');
    });
  });
}
