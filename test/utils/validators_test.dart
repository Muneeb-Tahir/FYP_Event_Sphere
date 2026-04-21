// test/utils/validators_test.dart
// Unit tests for Validators utility class

import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('email validation', () {
      test('returns error for empty email', () {
        expect(Validators.email(null), 'Email is required');
        expect(Validators.email(''), 'Email is required');
      });

      test('returns error for invalid email formats', () {
        expect(Validators.email('invalid'), 'Please enter a valid email address');
        expect(Validators.email('invalid@'), 'Please enter a valid email address');
        expect(Validators.email('@example.com'), 'Please enter a valid email address');
        expect(Validators.email('test@.com'), 'Please enter a valid email address');
      });

      test('returns null for valid email addresses', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.org'), isNull);
        expect(Validators.email('test-user@example.co.uk'), isNull);
        expect(Validators.email('user@subdomain.domain.com'), isNull);
      });
    });

    group('password validation', () {
      test('returns error for empty password', () {
        expect(Validators.password(null), 'Password is required');
        expect(Validators.password(''), 'Password is required');
      });

      test('returns error for short password', () {
        expect(Validators.password('12345'), 'Password must be at least 6 characters');
        expect(Validators.password('abc'), 'Password must be at least 6 characters');
      });

      test('returns null for valid password', () {
        expect(Validators.password('123456'), isNull);
        expect(Validators.password('password123'), isNull);
      });
    });

    group('strongPassword validation', () {
      test('returns error for empty password', () {
        expect(Validators.strongPassword(null), 'Password is required');
        expect(Validators.strongPassword(''), 'Password is required');
      });

      test('returns error for password less than 8 characters', () {
        expect(Validators.strongPassword('Pass1'), 'Password must be at least 8 characters');
      });

      test('returns error for password without uppercase', () {
        expect(Validators.strongPassword('password123'), 'Password must contain at least one uppercase letter');
      });

      test('returns error for password without lowercase', () {
        expect(Validators.strongPassword('PASSWORD123'), 'Password must contain at least one lowercase letter');
      });

      test('returns error for password without number', () {
        expect(Validators.strongPassword('PasswordABC'), 'Password must contain at least one number');
      });

      test('returns null for strong password', () {
        expect(Validators.strongPassword('Password123'), isNull);
        expect(Validators.strongPassword('MyP@ssw0rd'), isNull);
      });
    });

    group('confirmPassword validation', () {
      test('returns error when empty', () {
        final validator = Validators.confirmPassword('password123');
        expect(validator(null), 'Please confirm your password');
        expect(validator(''), 'Please confirm your password');
      });

      test('returns error when passwords do not match', () {
        final validator = Validators.confirmPassword('password123');
        expect(validator('different'), 'Passwords do not match');
      });

      test('returns null when passwords match', () {
        final validator = Validators.confirmPassword('password123');
        expect(validator('password123'), isNull);
      });
    });

    group('required validation', () {
      test('returns error for empty value', () {
        expect(Validators.required(null), 'This field is required');
        expect(Validators.required(''), 'This field is required');
        expect(Validators.required('   '), 'This field is required');
      });

      test('uses custom field name', () {
        expect(Validators.required(null, 'Username'), 'Username is required');
        expect(Validators.required('', 'Email'), 'Email is required');
      });

      test('returns null for non-empty value', () {
        expect(Validators.required('valid'), isNull);
        expect(Validators.required('  valid  '), isNull);
      });
    });

    group('name validation', () {
      test('returns error for empty name', () {
        expect(Validators.name(null), 'Name is required');
        expect(Validators.name(''), 'Name is required');
        expect(Validators.name('   '), 'Name is required');
      });

      test('returns error for name less than 2 characters', () {
        expect(Validators.name('A'), 'Name must be at least 2 characters');
      });

      test('returns error for name more than 50 characters', () {
        final longName = 'A' * 51;
        expect(Validators.name(longName), 'Name must be less than 50 characters');
      });

      test('returns null for valid name', () {
        expect(Validators.name('Jo'), isNull);
        expect(Validators.name('John Doe'), isNull);
        expect(Validators.name('A' * 50), isNull);
      });
    });

    group('eventTitle validation', () {
      test('returns error for empty title', () {
        expect(Validators.eventTitle(null), 'Event title is required');
        expect(Validators.eventTitle(''), 'Event title is required');
      });

      test('returns error for title less than 3 characters', () {
        expect(Validators.eventTitle('AB'), 'Title must be at least 3 characters');
      });

      test('returns error for title more than 100 characters', () {
        final longTitle = 'A' * 101;
        expect(Validators.eventTitle(longTitle), 'Title must be less than 100 characters');
      });

      test('returns null for valid title', () {
        expect(Validators.eventTitle('ABC'), isNull);
        expect(Validators.eventTitle('Tech Conference 2025'), isNull);
      });
    });

    group('description validation', () {
      test('returns error for empty description', () {
        expect(Validators.description(null), 'Description is required');
        expect(Validators.description(''), 'Description is required');
      });

      test('returns error for description less than 10 characters', () {
        expect(Validators.description('Too short'), 'Description must be at least 10 characters');
      });

      test('returns error for description more than 1000 characters', () {
        final longDesc = 'A' * 1001;
        expect(Validators.description(longDesc), 'Description must be less than 1000 characters');
      });

      test('returns null for valid description', () {
        expect(Validators.description('This is a valid description for an event.'), isNull);
      });
    });

    group('venue validation', () {
      test('returns error for empty venue', () {
        expect(Validators.venue(null), 'Venue is required');
        expect(Validators.venue(''), 'Venue is required');
      });

      test('returns error for venue less than 2 characters', () {
        expect(Validators.venue('A'), 'Venue must be at least 2 characters');
      });

      test('returns null for valid venue', () {
        expect(Validators.venue('Room 101'), isNull);
        expect(Validators.venue('Main Auditorium'), isNull);
      });
    });

    group('capacity validation', () {
      test('returns error for empty capacity', () {
        expect(Validators.capacity(null), 'Capacity is required');
        expect(Validators.capacity(''), 'Capacity is required');
      });

      test('returns error for non-numeric input', () {
        expect(Validators.capacity('abc'), 'Please enter a valid number');
        expect(Validators.capacity('12.5'), 'Please enter a valid number');
      });

      test('returns error for capacity less than 1', () {
        expect(Validators.capacity('0'), 'Capacity must be at least 1');
        expect(Validators.capacity('-5'), 'Capacity must be at least 1');
      });

      test('returns error for capacity more than 10000', () {
        expect(Validators.capacity('10001'), 'Capacity cannot exceed 10,000');
        expect(Validators.capacity('50000'), 'Capacity cannot exceed 10,000');
      });

      test('returns null for valid capacity', () {
        expect(Validators.capacity('1'), isNull);
        expect(Validators.capacity('100'), isNull);
        expect(Validators.capacity('10000'), isNull);
      });
    });

    group('futureDate validation', () {
      test('returns error for null date', () {
        expect(Validators.futureDate(null), 'Date is required');
      });

      test('returns error for past date', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        expect(Validators.futureDate(pastDate), 'Date must be in the future');
      });

      test('returns null for future date', () {
        final futureDate = DateTime.now().add(const Duration(days: 1));
        expect(Validators.futureDate(futureDate), isNull);
      });
    });

    group('url validation', () {
      test('returns null for empty url (optional)', () {
        expect(Validators.url(null), isNull);
        expect(Validators.url(''), isNull);
      });

      test('returns error for invalid url', () {
        expect(Validators.url('invalid'), 'Please enter a valid URL');
        expect(Validators.url('ftp://invalid'), 'Please enter a valid URL');
      });

      test('returns null for valid url', () {
        expect(Validators.url('https://example.com'), isNull);
        expect(Validators.url('http://example.org/path'), isNull);
        expect(Validators.url('example.com'), isNull);
      });
    });

    group('phone validation', () {
      test('returns null for empty phone (optional)', () {
        expect(Validators.phone(null), isNull);
        expect(Validators.phone(''), isNull);
      });

      test('returns error for invalid phone', () {
        expect(Validators.phone('123'), 'Please enter a valid phone number');
        expect(Validators.phone('abc'), 'Please enter a valid phone number');
      });

      test('returns null for valid phone', () {
        expect(Validators.phone('+1234567890'), isNull);
        expect(Validators.phone('123-456-7890'), isNull);
        expect(Validators.phone('1234567890'), isNull);
      });
    });

    group('passwordStrength', () {
      test('returns 0 for very weak password', () {
        expect(Validators.passwordStrength(''), 0);
      });

      test('returns score based on criteria met', () {
        // 'abc' - has lowercase only = 1
        expect(Validators.passwordStrength('abc'), 1);
        // 'abcdefgh' - has length(8+) + lowercase = 2
        expect(Validators.passwordStrength('abcdefgh'), 2);
      });

      test('returns higher score for stronger passwords', () {
        expect(Validators.passwordStrength('Abcdefgh'), 3); // length + upper + lower
        expect(Validators.passwordStrength('Abcd1234'), 4); // length + upper + lower + number
        expect(Validators.passwordStrength('Abcd123!'), 4); // capped at 4
      });
    });

    group('passwordStrengthLabel', () {
      test('returns correct labels for each strength level', () {
        expect(Validators.passwordStrengthLabel(0), 'Very Weak');
        expect(Validators.passwordStrengthLabel(1), 'Weak');
        expect(Validators.passwordStrengthLabel(2), 'Fair');
        expect(Validators.passwordStrengthLabel(3), 'Strong');
        expect(Validators.passwordStrengthLabel(4), 'Very Strong');
        expect(Validators.passwordStrengthLabel(5), 'Unknown');
      });
    });
  });
}
