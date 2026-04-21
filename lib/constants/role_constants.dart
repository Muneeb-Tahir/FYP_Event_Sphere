// lib/constants/role_constants.dart
// Role constants and hierarchy utilities for RBAC

import '../models/user.dart';

/// Central source of truth for role names and hierarchy
class RoleConstants {
  // Database role names (snake_case)
  static const String student = 'student';
  static const String vicePresident = 'vice_president';
  static const String president = 'president';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  // Role hierarchy rank (higher = more privileged)
  static const Map<String, int> roleRank = {
    student: 1,
    vicePresident: 2,
    president: 3,
    admin: 4,
    superAdmin: 5,
  };

  // Display names for UI
  static const Map<String, String> displayNames = {
    student: 'Student',
    vicePresident: 'Vice President',
    president: 'President',
    admin: 'Admin',
    superAdmin: 'Super Admin',
  };

  /// Convert Dart enum to database string
  static String roleEnumToDb(UserRole role) {
    switch (role) {
      case UserRole.student:
        return student;
      case UserRole.vicePresident:
        return vicePresident;
      case UserRole.president:
        return president;
      case UserRole.admin:
        return admin;
      case UserRole.superAdmin:
        return superAdmin;
    }
  }

  /// Convert database string to Dart enum
  static UserRole dbToRoleEnum(String dbRole) {
    switch (dbRole) {
      case student:
        return UserRole.student;
      case vicePresident:
        return UserRole.vicePresident;
      case president:
        return UserRole.president;
      case admin:
        return UserRole.admin;
      case superAdmin:
        return UserRole.superAdmin;
      default:
        return UserRole.student; // Default to most restricted
    }
  }

  /// Get display name for a database role string
  static String getDisplayName(String dbRole) {
    return displayNames[dbRole] ?? 'Unknown';
  }

  /// Get display name for a UserRole enum
  static String getDisplayNameFromEnum(UserRole role) {
    return displayNames[roleEnumToDb(role)] ?? 'Unknown';
  }

  /// Get rank for a role (higher = more privileged)
  static int getRank(String role) {
    return roleRank[role] ?? 0;
  }

  /// Check if caller can manage target based on hierarchy
  static bool canManage(String callerRole, String targetRole) {
    final callerRank = roleRank[callerRole] ?? 0;
    final targetRank = roleRank[targetRole] ?? 0;
    return callerRank > targetRank;
  }

  /// Check if caller can change target's role
  /// Takes into account special rules (admin can't modify admin, etc.)
  static bool canChangeRole(String callerRole, String targetRole, String newRole) {
    // Only admin/super_admin can change roles
    if (callerRole != admin && callerRole != superAdmin) {
      return false;
    }

    // Nobody can modify super_admin
    if (targetRole == superAdmin) {
      return false;
    }

    // Nobody can promote to super_admin
    if (newRole == superAdmin) {
      return false;
    }

    // Admin cannot modify other admins
    if (callerRole == admin && targetRole == admin) {
      return false;
    }

    // Only super_admin can create/demote admins
    if ((newRole == admin || targetRole == admin) && callerRole != superAdmin) {
      return false;
    }

    return true;
  }

  /// Get roles that the caller can assign
  static List<String> getAssignableRoles(String callerRole) {
    if (callerRole == superAdmin) {
      // Super admin can assign anything except super_admin
      return [student, vicePresident, president, admin];
    } else if (callerRole == admin) {
      // Admin can only assign student, vice_president, president
      return [student, vicePresident, president];
    }
    return [];
  }

  /// Get roles that the caller can view/manage in user management
  static List<String> getManageableRoles(String callerRole) {
    if (callerRole == superAdmin) {
      // Super admin can see everyone except other super_admins
      return [student, vicePresident, president, admin];
    } else if (callerRole == admin) {
      // Admin can only see student, vice_president, president
      return [student, vicePresident, president];
    }
    return [];
  }
}
