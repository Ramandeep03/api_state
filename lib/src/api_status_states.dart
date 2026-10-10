part of 'api_state_base.dart';

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
///
/// Optionally retains data from a previous success so the UI can keep showing
/// it while presenting the error.
class ApiFailure<T> extends ApiStatus<T> {
  @override
  final Failure error;

  @override
  final T? data;

  @override
  final bool hasData;

  const ApiFailure(this.error, {T? data, bool hasData = false})
      : data = data,
        hasData = hasData || data != null;

  @override
  String toString() => hasData
      ? 'ApiFailure(error: $error, data: $data)'
      : 'ApiFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiFailure<T> &&
          error == other.error &&
          hasData == other.hasData &&
          (!hasData || data == other.data);

  @override
  int get hashCode => hasData ? Object.hash(error, data, true) : error.hashCode;
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

/// Loading-more state - fetching another page while preserving existing data.
class ApiLoadMore<T> extends ApiStatus<T> {
  @override
  final T data;

  const ApiLoadMore(this.data);

  @override
  String toString() => 'ApiLoadMore(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiLoadMore<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;
}
