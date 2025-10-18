import 'exceptions.dart';

/// Result type for handling success and failure states
sealed class Result<T> {
  const Result();

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null if failure
  T? get data => switch (this) {
        Success(value: final value) => value,
        Failure() => null,
      };

  /// Get exception if failure, null if success
  AppException? get exception => switch (this) {
        Success() => null,
        Failure(exception: final error) => error,
      };

  /// Transform the result's value
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final value) => Success(transform(value)),
      Failure(exception: final error) => Failure(error),
    };
  }

  /// Transform the result's value asynchronously
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    return switch (this) {
      Success(value: final value) => Success(await transform(value)),
      Failure(exception: final error) => Failure(error),
    };
  }

  /// Fold the result into a single value
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppException exception) onFailure,
  }) {
    return switch (this) {
      Success(value: final value) => onSuccess(value),
      Failure(exception: final error) => onFailure(error),
    };
  }

  /// Execute a callback if success
  Result<T> onSuccess(void Function(T value) callback) {
    if (this is Success<T>) {
      callback((this as Success<T>).value);
    }
    return this;
  }

  /// Execute a callback if failure
  Result<T> onFailure(void Function(AppException exception) callback) {
    if (this is Failure<T>) {
      callback((this as Failure<T>).exception);
    }
    return this;
  }

  /// Get data or throw exception
  T getOrThrow() {
    return switch (this) {
      Success(value: final value) => value,
      Failure(exception: final error) => throw error,
    };
  }

  /// Get data or return default value
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(value: final value) => value,
      Failure() => defaultValue,
    };
  }

  /// Get data or compute default value
  T getOrElse(T Function() defaultValue) {
    return switch (this) {
      Success(value: final value) => value,
      Failure() => defaultValue(),
    };
  }
}

/// Success result
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Success && runtimeType == other.runtimeType && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success(value: $value)';
}

/// Failure result
final class Failure<T> extends Result<T> {
  final AppException exception;

  const Failure(this.exception);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Failure &&
            runtimeType == other.runtimeType &&
            exception == other.exception;
  }

  @override
  int get hashCode => exception.hashCode;

  @override
  String toString() => 'Failure(exception: $exception)';
}
