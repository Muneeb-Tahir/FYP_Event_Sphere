// test/services/error_service_test.dart
// Unit tests for ErrorService

import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/services/error_service.dart';

void main() {
  group('ErrorService Tests', () {
    group('getUserFriendlyMessage', () {
      group('Network errors', () {
        test('handles SocketException', () {
          final message = ErrorService.getUserFriendlyMessage(
              Exception('SocketException: Connection refused'));
          expect(message, 'No internet connection. Please check your network and try again.');
        });

        test('handles connection refused', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Connection refused by server');
          expect(message, 'No internet connection. Please check your network and try again.');
        });

        test('handles network unreachable', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Network is unreachable');
          expect(message, 'No internet connection. Please check your network and try again.');
        });

        test('handles timeout errors', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Request timed out');
          expect(message, 'Request timed out. Please try again.');
        });
      });

      group('Authentication errors', () {
        test('handles invalid login credentials', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Invalid login credentials');
          expect(message, 'Invalid email or password. Please try again.');
        });

        test('handles email already registered', () {
          final message = ErrorService.getUserFriendlyMessage(
              'User already registered with this email');
          expect(message, 'This email is already registered. Try logging in instead.');
        });

        test('handles weak password', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Password should be at least 6 characters');
          expect(message, 'Password is too weak. Use at least 6 characters with letters and numbers.');
        });

        test('handles JWT expired', () {
          final message = ErrorService.getUserFriendlyMessage(
              'JWT expired');
          expect(message, 'Your session has expired. Please log in again.');
        });
      });

      group('Permission errors', () {
        test('handles permission denied', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Permission denied');
          expect(message, 'You don\'t have permission to perform this action.');
        });

        test('handles RLS errors', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Row level security violation');
          expect(message, 'Access denied. Please contact support if this continues.');
        });
      });

      group('Database errors', () {
        test('handles unique constraint violation', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Unique constraint violation');
          expect(message, 'This record already exists.');
        });

        test('handles not found', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Record not found');
          expect(message, 'The requested item was not found.');
        });
      });

      group('Storage errors', () {
        test('handles file too large', () {
          final message = ErrorService.getUserFriendlyMessage(
              'File too large');
          expect(message, 'File is too large. Maximum size is 5MB.');
        });

        test('handles invalid file type', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Invalid file type');
          expect(message, 'Invalid file type. Please use JPG, PNG, or GIF.');
        });
      });

      group('Event-specific errors', () {
        test('handles event full', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Event is full');
          expect(message, 'This event is at full capacity.');
        });

        test('handles already registered', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Already registered for this event');
          expect(message, 'You are already registered for this event.');
        });

        test('handles registration closed', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Registration closed');
          expect(message, 'Registration for this event has closed.');
        });
      });

      group('Generic fallback', () {
        test('returns generic message for unknown errors', () {
          final message = ErrorService.getUserFriendlyMessage(
              'Some random error that is not mapped');
          expect(message, 'Something went wrong. Please try again later.');
        });
      });
    });

    group('isNetworkError', () {
      test('returns true for SocketException', () {
        expect(ErrorService.isNetworkError('SocketException'), true);
      });

      test('returns true for connection refused', () {
        expect(ErrorService.isNetworkError('Connection refused'), true);
      });

      test('returns true for network unreachable', () {
        expect(ErrorService.isNetworkError('Network is unreachable'), true);
      });

      test('returns true for timeout', () {
        expect(ErrorService.isNetworkError('Request timeout'), true);
      });

      test('returns false for auth errors', () {
        expect(ErrorService.isNetworkError('Invalid credentials'), false);
      });

      test('returns false for generic errors', () {
        expect(ErrorService.isNetworkError('Something went wrong'), false);
      });
    });

    group('requiresReauth', () {
      test('returns true for JWT expired', () {
        expect(ErrorService.requiresReauth('JWT expired'), true);
      });

      test('returns true for not authenticated', () {
        expect(ErrorService.requiresReauth('User not authenticated'), true);
      });

      test('returns true for session errors', () {
        expect(ErrorService.requiresReauth('Session invalid'), true);
      });

      test('returns true for unauthorized', () {
        expect(ErrorService.requiresReauth('Unauthorized access'), true);
      });

      test('returns false for permission errors', () {
        expect(ErrorService.requiresReauth('Permission denied'), false);
      });

      test('returns false for network errors', () {
        expect(ErrorService.requiresReauth('SocketException'), false);
      });
    });
  });
}
