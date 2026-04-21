// lib/repositories/base_repository.dart
// Base repository interface with common operations

import '../core/result.dart';

/// Base repository interface defining common CRUD operations
abstract class BaseRepository<T> {
  /// Get all items
  Future<Result<List<T>>> getAll();

  /// Get a single item by ID
  Future<Result<T?>> getById(String id);

  /// Create a new item
  Future<Result<T>> create(T item);

  /// Update an existing item
  Future<Result<T>> update(String id, Map<String, dynamic> data);

  /// Delete an item by ID
  Future<Result<void>> delete(String id);
}

/// Mixin for offline support in repositories
mixin OfflineCapable<T> {
  /// Get cached items when offline
  Future<List<T>> getCached();

  /// Cache items for offline use
  Future<void> cacheItems(List<T> items);

  /// Check if online
  bool get isOnline;
}

/// Mixin for pagination support
mixin Paginated<T> {
  /// Get paginated items
  Future<Result<PaginatedResponse<T>>> getPaginated({
    int page = 0,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  });
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
  });
}
