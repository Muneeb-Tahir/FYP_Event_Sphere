// test/models/user_test.dart
// Unit tests for User model

import 'package:flutter_test/flutter_test.dart';
import 'package:event_management_app/models/user.dart';

void main() {
  group('User Model Tests', () {
    group('UserRole enum', () {
      test('has all expected values', () {
        expect(UserRole.values, contains(UserRole.student));
        expect(UserRole.values, contains(UserRole.vicePresident));
        expect(UserRole.values, contains(UserRole.president));
        expect(UserRole.values, contains(UserRole.admin));
        expect(UserRole.values, contains(UserRole.superAdmin));
        expect(UserRole.values.length, 5);
      });
    });

    group('User constructor', () {
      test('creates user with required fields', () {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          societyIds: ['society-1', 'society-2'],
        );

        expect(user.id, 'user-123');
        expect(user.email, 'test@example.com');
        expect(user.name, 'Test User');
        expect(user.role, UserRole.student);
        expect(user.societyIds, ['society-1', 'society-2']);
        expect(user.bio, isNull);
        expect(user.phone, isNull);
        expect(user.profileImageUrl, isNull);
        expect(user.joinedDate, isNotNull);
      });

      test('sets joinedDate to now when not provided', () {
        final before = DateTime.now();
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          societyIds: [],
        );
        final after = DateTime.now();

        expect(user.joinedDate.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(user.joinedDate.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('uses provided joinedDate', () {
        final customDate = DateTime(2023, 1, 15);
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.student,
          societyIds: [],
          joinedDate: customDate,
        );

        expect(user.joinedDate, customDate);
      });

      test('creates user with all optional fields', () {
        final user = User(
          id: 'user-123',
          email: 'test@example.com',
          name: 'Test User',
          role: UserRole.president,
          societyIds: ['society-1'],
          bio: 'My bio',
          phone: '+1234567890',
          profileImageUrl: 'https://example.com/avatar.jpg',
          joinedDate: DateTime(2024, 6, 1),
        );

        expect(user.bio, 'My bio');
        expect(user.phone, '+1234567890');
        expect(user.profileImageUrl, 'https://example.com/avatar.jpg');
      });
    });

    group('copyWith method', () {
      late User originalUser;

      setUp(() {
        originalUser = User(
          id: 'original-id',
          email: 'original@example.com',
          name: 'Original Name',
          role: UserRole.student,
          societyIds: ['society-1'],
          bio: 'Original bio',
          phone: '123456789',
          profileImageUrl: 'https://example.com/original.jpg',
          joinedDate: DateTime(2024, 1, 1),
        );
      });

      test('copies all fields when no changes specified', () {
        final copy = originalUser.copyWith();

        expect(copy.id, originalUser.id);
        expect(copy.email, originalUser.email);
        expect(copy.name, originalUser.name);
        expect(copy.role, originalUser.role);
        expect(copy.societyIds, originalUser.societyIds);
        expect(copy.bio, originalUser.bio);
        expect(copy.phone, originalUser.phone);
        expect(copy.profileImageUrl, originalUser.profileImageUrl);
        expect(copy.joinedDate, originalUser.joinedDate);
      });

      test('updates only specified fields', () {
        final copy = originalUser.copyWith(
          name: 'Updated Name',
          email: 'updated@example.com',
        );

        expect(copy.name, 'Updated Name');
        expect(copy.email, 'updated@example.com');
        // Original values preserved
        expect(copy.id, originalUser.id);
        expect(copy.role, originalUser.role);
        expect(copy.bio, originalUser.bio);
      });

      test('updates role correctly', () {
        final copy = originalUser.copyWith(role: UserRole.admin);

        expect(copy.role, UserRole.admin);
        expect(originalUser.role, UserRole.student);
      });

      test('updates societyIds correctly', () {
        final newSocieties = ['society-2', 'society-3'];
        final copy = originalUser.copyWith(societyIds: newSocieties);

        expect(copy.societyIds, newSocieties);
        expect(originalUser.societyIds, ['society-1']);
      });

      test('can update bio to different value', () {
        final copy = originalUser.copyWith(bio: 'New bio content');

        expect(copy.bio, 'New bio content');
      });

      test('preserves null values when not specified', () {
        final userWithNulls = User(
          id: 'user',
          email: 'email@test.com',
          name: 'Name',
          role: UserRole.student,
          societyIds: [],
        );

        final copy = userWithNulls.copyWith(name: 'New Name');

        expect(copy.bio, isNull);
        expect(copy.phone, isNull);
        expect(copy.profileImageUrl, isNull);
      });
    });

    group('equality and identity', () {
      test('two users with same id are different instances', () {
        final user1 = User(
          id: 'same-id',
          email: 'test@example.com',
          name: 'User 1',
          role: UserRole.student,
          societyIds: [],
        );

        final user2 = User(
          id: 'same-id',
          email: 'test@example.com',
          name: 'User 1',
          role: UserRole.student,
          societyIds: [],
        );

        // Different instances (no custom equality)
        expect(identical(user1, user2), false);
      });
    });
  });
}
