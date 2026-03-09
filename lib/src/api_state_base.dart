import 'package:api_state/src/failure.dart';

/// A generic sealed class representing the different states of an API call.
///
/// Use Dart 3 pattern matching for compile-time exhaustive checks:
/// ```dart
/// switch (status) {
///   case ApiInitial():       // ...
///   case ApiLoading():       // ...
///   case ApiSuccess(:final data):   // ...
///   case ApiFailure(:final error):  // ...
///   case ApiRefresh(:final data):   // ...
/// }
/// ```
sealed class ApiStatus<T> {
  const ApiStatus();

  /// `true` if data is available (success or refresh).
  bool get hasData => switch (this) {
        ApiSuccess() || ApiRefresh() => true,
        _ => false,
      };

  /// `true` if an error is available.
  bool get hasError => this is ApiFailure<T>;

  /// The data if available, otherwise `null`.
  T? get data => switch (this) {
        ApiSuccess(:final data) => data,
        ApiRefresh(:final data) => data,
        _ => null,
      };

  /// The error if available, otherwise `null`.
  Failure? get error => switch (this) {
        ApiFailure(:final error) => error,
        _ => null,
      };

  // -------------------------
  // BOOLEAN GETTERS
  // -------------------------

  /// `true` if the state is initial.
  bool get isInitial => this is ApiInitial<T>;

  /// `true` if the state is loading.
  bool get isLoading => this is ApiLoading<T>;

  /// `true` if the state is success.
  bool get isSuccess => this is ApiSuccess<T>;

  /// `true` if the state is failure.
  bool get isFailure => this is ApiFailure<T>;

  /// `true` if the state is refresh.
  bool get isRefresh => this is ApiRefresh<T>;

  // -------------------------
  // TRANSFORM METHODS
  // -------------------------

  /// Returns a new [ApiStatus] with the data transformed by [transform].
  /// Non-data states are passed through unchanged.
  ApiStatus<R> map<R>(R Function(T data) transform) => switch (this) {
        ApiInitial() => const ApiInitial(),
        ApiLoading() => const ApiLoading(),
        ApiSuccess(:final data) => ApiSuccess(transform(data)),
        ApiFailure(:final error) => ApiFailure(error),
        ApiRefresh(:final data) => ApiRefresh(transform(data)),
      };

  /// Returns a new [ApiStatus] with the error transformed by [transform].
  /// Non-failure states are passed through unchanged.
  ApiStatus<T> mapFailure(Failure Function(Failure error) transform) =>
      switch (this) {
        ApiFailure(:final error) => ApiFailure(transform(error)),
        _ => this,
      };

  // -------------------------
  // STATE TRANSITION HELPERS
  // -------------------------

  /// Transitions to [ApiLoading], discarding any existing data.
  ApiStatus<T> toLoading() => const ApiLoading();

  /// Transitions to [ApiRefresh], preserving existing data.
  ///
  /// If the current state has no data, falls back to [ApiLoading].
  ApiStatus<T> toRefresh() => switch (this) {
        ApiSuccess(:final data) => ApiRefresh(data),
        ApiRefresh(:final data) => ApiRefresh(data),
        _ => const ApiLoading(),
      };

  // -------------------------
  // DATA CALLBACK
  // -------------------------

  /// Calls [callback] with data if the state carries data (success or refresh).
  /// Returns the callback result or `null` if no data is available.
  R? whenData<R>(R Function(T data) callback) => switch (this) {
        ApiSuccess(:final data) => callback(data),
        ApiRefresh(:final data) => callback(data),
        _ => null,
      };

  // -------------------------
  // STATIC HELPERS
  // -------------------------

  /// Wraps an async operation, returning [ApiSuccess] or [ApiFailure].
  ///
  /// ```dart
  /// state = const ApiLoading();
  /// state = await ApiStatus.guard(
  ///   () => repository.fetchUsers(),
  ///   onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
  /// );
  /// ```
  static Future<ApiStatus<T>> guard<T>(
    Future<T> Function() action, {
    required Failure Function(Object error, StackTrace stackTrace) onError,
  }) async {
    try {
      final data = await action();
      return ApiSuccess(data);
    } catch (e, st) {
      return ApiFailure(onError(e, st));
    }
  }

  // -------------------------
  // PATTERN MATCHING METHODS
  // -------------------------

  /// Exhaustive pattern matching. Forces handling of all possible cases.
  R when<R>({
    required R Function() initialOrLoading,
    required R Function(T data) success,
    required R Function(Failure error) failure,
    R Function(T data)? refresh,
  }) =>
      switch (this) {
        ApiInitial() || ApiLoading() => initialOrLoading(),
        ApiSuccess(:final data) => success(data),
        ApiFailure(:final error) => failure(error),
        ApiRefresh(:final data) =>
          refresh?.call(data) ?? initialOrLoading(),
      };

  /// Non-exhaustive pattern matching. Unhandled cases return `null`.
  R? whenOrNull<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Failure error)? failure,
    R Function(T data)? refresh,
  }) =>
      switch (this) {
        ApiInitial() => initial?.call(),
        ApiLoading() => loading?.call(),
        ApiSuccess(:final data) => success?.call(data),
        ApiFailure(:final error) => failure?.call(error),
        ApiRefresh(:final data) => refresh?.call(data),
      };

  /// Pattern matching with a fallback for unhandled cases.
  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Failure error)? failure,
    R Function(T data)? refresh,
    required R Function() orElse,
  }) =>
      switch (this) {
        ApiInitial() => initial?.call() ?? orElse(),
        ApiLoading() => loading?.call() ?? orElse(),
        ApiSuccess(:final data) => success?.call(data) ?? orElse(),
        ApiFailure(:final error) => failure?.call(error) ?? orElse(),
        ApiRefresh(:final data) => refresh?.call(data) ?? orElse(),
      };
}

/// Idle state - before anything has started.
class ApiInitial<T> extends ApiStatus<T> {
  const ApiInitial();

  @override
  String toString() => 'ApiInitial()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiInitial<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state - API request initiated.
class ApiLoading<T> extends ApiStatus<T> {
  const ApiLoading();

  @override
  String toString() => 'ApiLoading()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Success state - API request completed with valid data.
class ApiSuccess<T> extends ApiStatus<T> {
  @override
  final T data;

  const ApiSuccess(this.data);

  @override
  String toString() => 'ApiSuccess(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiSuccess<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure state - API encountered an exception or error response.
class ApiFailure<T> extends ApiStatus<T> {
  @override
  final Failure error;

  const ApiFailure(this.error);

  @override
  String toString() => 'ApiFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiFailure<T> && error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Refresh state - re-fetching data while preserving existing data.
class ApiRefresh<T> extends ApiStatus<T> {
  @override
  final T data;

  const ApiRefresh(this.data);

  @override
  String toString() => 'ApiRefresh(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiRefresh<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}
