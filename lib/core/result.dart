// lib/core/result.dart
// Result type for consistent error handling

/// A sealed class representing the result of an operation.
/// Can be either Success<T> or Failure<T>.
sealed class Result<T> {
  const Result();

  /// Returns true if this is a Success
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure
  bool get isFailure => this is Failure<T>;

  /// Get the data if Success, otherwise null
  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// Get the error message if Failure, otherwise null
  String? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final message) => message,
  };

  /// Execute a function based on success or failure
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Object? error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final message, :final error) => failure(message, error),
    };
  }

  /// Map the success value to another type
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success<T>(:final data) => Success(mapper(data)),
      Failure<T>(:final message, :final error) => Failure(message, error: error),
    };
  }

  /// FlatMap for chaining results
  Result<R> flatMap<R>(Result<R> Function(T data) mapper) {
    return switch (this) {
      Success<T>(:final data) => mapper(data),
      Failure<T>(:final message, :final error) => Failure(message, error: error),
    };
  }
}

/// Represents a successful result with data
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Represents a failed result with an error message
final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.error, this.stackTrace});

  @override
  String toString() => 'Failure($message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Extension for easily wrapping async operations
extension ResultExtension<T> on Future<T> {
  /// Wraps a Future in a Result, catching any exceptions
  Future<Result<T>> toResult() async {
    try {
      final data = await this;
      return Success(data);
    } catch (e, stackTrace) {
      return Failure(
        e.toString(),
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
