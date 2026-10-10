import 'package:api_state/src/failure.dart';

part 'api_status_states.dart';

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
///   case ApiLoadMore(:final data):  // ...
/// }
/// ```
sealed class ApiStatus<T> {
  const ApiStatus();

  /// `true` if data is available.
  bool get hasData => switch (this) {
        ApiSuccess() || ApiRefresh() || ApiLoadMore() => true,
        ApiFailure(:final hasData) => hasData,
        _ => false,
      };

  /// `true` if an error is available.
  bool get hasError => this is ApiFailure<T>;

  /// The data if available, otherwise `null`.
  T? get data => switch (this) {
        ApiSuccess(:final data) => data,
        ApiRefresh(:final data) => data,
        ApiLoadMore(:final data) => data,
        ApiFailure(:final data, hasData: true) => data,
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

  /// `true` if the state contains a failure.
  bool get isFailure => this is ApiFailure<T>;

  /// `true` if the state is refresh.
  bool get isRefresh => this is ApiRefresh<T>;

  /// `true` if another page is loading while existing data is preserved.
  bool get isLoadMore => this is ApiLoadMore<T>;

  // -------------------------
  // TRANSFORM METHODS
  // -------------------------

  /// Returns a new [ApiStatus] with the data transformed by [transform].
  /// States without data are passed through unchanged.
  ApiStatus<R> map<R>(R Function(T data) transform) => switch (this) {
        ApiInitial() => const ApiInitial(),
        ApiLoading() => const ApiLoading(),
        ApiSuccess(:final data) => ApiSuccess(transform(data)),
        ApiFailure(:final error, :final data, :final hasData) => hasData
            ? ApiFailure(error, data: transform(data as T), hasData: true)
            : ApiFailure(error),
        ApiRefresh(:final data) => ApiRefresh(transform(data)),
        ApiLoadMore(:final data) => ApiLoadMore(transform(data)),
      };

  /// Returns a new [ApiStatus] with the error transformed by [transform].
  /// Non-failure states are passed through unchanged.
  ApiStatus<T> mapFailure(Failure Function(Failure error) transform) =>
      switch (this) {
        ApiFailure(:final error, :final data, :final hasData) => hasData
            ? ApiFailure(transform(error), data: data, hasData: true)
            : ApiFailure(transform(error)),
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
        ApiLoadMore(:final data) => ApiRefresh(data),
        ApiFailure(:final data, hasData: true) => ApiRefresh(data as T),
        _ => const ApiLoading(),
      };

  /// Transitions to [ApiLoadMore], preserving existing data.
  ///
  /// If the current state has no data, falls back to [ApiLoading].
  ApiStatus<T> toLoadMore() => switch (this) {
        ApiSuccess(:final data) => ApiLoadMore(data),
        ApiRefresh(:final data) => ApiLoadMore(data),
        ApiLoadMore(:final data) => ApiLoadMore(data),
        ApiFailure(:final data, hasData: true) => ApiLoadMore(data as T),
        _ => const ApiLoading(),
      };

  /// Transitions a load-more request to failure while retaining its data.
  ///
  /// If the current state has no data from a load-more operation, returns a
  /// regular [ApiFailure] without data.
  ApiStatus<T> toLoadMoreFailure(Failure error) => switch (this) {
        ApiLoadMore(:final data) =>
          ApiFailure(error, data: data, hasData: true),
        ApiFailure(:final data, hasData: true) =>
          ApiFailure(error, data: data, hasData: true),
        _ => ApiFailure(error),
      };

  // -------------------------
  // DATA CALLBACK
  // -------------------------

  /// Calls [callback] with data if the state carries data.
  /// Returns the callback result or `null` if no data is available.
  R? whenData<R>(R Function(T data) callback) => switch (this) {
        ApiSuccess(:final data) => callback(data),
        ApiRefresh(:final data) => callback(data),
        ApiLoadMore(:final data) => callback(data),
        ApiFailure(:final data, hasData: true) => callback(data as T),
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
    R Function(T data)? loadMore,
  }) =>
      switch (this) {
        ApiInitial() || ApiLoading() => initialOrLoading(),
        ApiSuccess(:final data) => success(data),
        ApiFailure(:final error) => failure(error),
        ApiRefresh(:final data) =>
          refresh?.call(data) ?? initialOrLoading(),
        ApiLoadMore(:final data) =>
          loadMore?.call(data) ?? initialOrLoading(),
      };

  /// Non-exhaustive pattern matching. Unhandled cases return `null`.
  R? whenOrNull<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Failure error)? failure,
    R Function(T data)? refresh,
    R Function(T data)? loadMore,
  }) =>
      switch (this) {
        ApiInitial() => initial?.call(),
        ApiLoading() => loading?.call(),
        ApiSuccess(:final data) => success?.call(data),
        ApiFailure(:final error) => failure?.call(error),
        ApiRefresh(:final data) => refresh?.call(data),
        ApiLoadMore(:final data) => loadMore?.call(data),
      };

  /// Pattern matching with a fallback for unhandled cases.
  R maybeWhen<R>({
    R Function()? initial,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Failure error)? failure,
    R Function(T data)? refresh,
    R Function(T data)? loadMore,
    required R Function() orElse,
  }) =>
      switch (this) {
        ApiInitial() => initial?.call() ?? orElse(),
        ApiLoading() => loading?.call() ?? orElse(),
        ApiSuccess(:final data) => success?.call(data) ?? orElse(),
        ApiFailure(:final error) => failure?.call(error) ?? orElse(),
        ApiRefresh(:final data) => refresh?.call(data) ?? orElse(),
        ApiLoadMore(:final data) => loadMore?.call(data) ?? orElse(),
      };
}
