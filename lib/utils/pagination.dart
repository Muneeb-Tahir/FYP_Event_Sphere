// lib/utils/pagination.dart
// Pagination utilities for Event Sphere

/// Result container for paginated queries
class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasMore;
  final int? totalCount;

  PaginatedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
  });

  /// Check if this is the first page
  bool get isFirstPage => page == 0;

  /// Check if there are items
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Get the number of items
  int get length => items.length;

  /// Calculate the start index in the full list
  int get startIndex => page * pageSize;

  /// Calculate the end index in the full list
  int get endIndex => startIndex + items.length;

  /// Create an empty result
  factory PaginatedResult.empty({int pageSize = 20}) {
    return PaginatedResult(
      items: [],
      page: 0,
      pageSize: pageSize,
      hasMore: false,
    );
  }

  /// Map items to a different type
  PaginatedResult<R> map<R>(R Function(T) mapper) {
    return PaginatedResult<R>(
      items: items.map(mapper).toList(),
      page: page,
      pageSize: pageSize,
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }
}

/// Mixin for adding pagination state to StatefulWidgets
mixin PaginationMixin<T> {
  List<T> paginatedItems = [];
  int currentPage = 0;
  bool isLoadingMore = false;
  bool hasMoreItems = true;
  bool isInitialLoading = true;

  /// Reset pagination state
  void resetPagination() {
    paginatedItems = [];
    currentPage = 0;
    isLoadingMore = false;
    hasMoreItems = true;
    isInitialLoading = true;
  }

  /// Handle scroll to trigger load more
  bool shouldLoadMore(double scrollPosition, double maxScroll) {
    return scrollPosition >= maxScroll * 0.8 && !isLoadingMore && hasMoreItems;
  }
}
