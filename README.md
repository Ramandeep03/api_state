# api_state

A lightweight, zero-dependency Dart package for representing API call states using sealed classes.

Built for Dart 3+ with compile-time exhaustive pattern matching. Works with any state management solution — Bloc, Riverpod, GetX, Provider, or plain setState.

## States

| State | Class | Description |
|---|---|---|
| Initial | `ApiInitial` | No action taken yet |
| Loading | `ApiLoading` | API call in progress |
| Success | `ApiSuccess<T>` | Completed with data |
| Failure | `ApiFailure<T>` | Failed with error |
| Refresh | `ApiRefresh<T>` | Re-fetching while showing existing data |

## Installation

```yaml
dependencies:
  api_state: ^1.0.0
```

```dart
import 'package:api_state/api_state.dart';
```

## Quick Start

```dart
// Define your failure types
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.stackTrace});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}
```

```dart
// Use in your state management
ApiStatus<List<User>> usersState = const ApiInitial();

Future<void> fetchUsers() async {
  usersState = const ApiLoading();

  usersState = await ApiStatus.guard(
    () => repository.fetchUsers(),
    onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
  );
}
```

## Pattern Matching

### Dart 3 Switch Expression

The compiler ensures you handle every case:

```dart
Widget build(BuildContext context) {
  return switch (usersState) {
    ApiInitial()              => const SizedBox.shrink(),
    ApiLoading()              => const CircularProgressIndicator(),
    ApiSuccess(:final data)   => UserList(users: data),
    ApiFailure(:final error)  => ErrorView(message: error.message),
    ApiRefresh(:final data)   => UserList(users: data, refreshing: true),
  };
}
```

### `when` — Exhaustive Callbacks

Groups `initial` and `loading` into a single callback:

```dart
final widget = usersState.when(
  initialOrLoading: () => const CircularProgressIndicator(),
  success: (users) => UserList(users: users),
  failure: (error) => ErrorView(message: error.message),
  refresh: (users) => UserList(users: users, refreshing: true), // optional
);
```

### `whenOrNull` — Handle Only What You Need

Unhandled states return `null`:

```dart
usersState.whenOrNull(
  success: (users) => showSnackBar('Loaded ${users.length} users'),
  failure: (error) => showSnackBar(error.message),
);
```

### `maybeWhen` — With Fallback

```dart
final message = usersState.maybeWhen(
  success: (users) => '${users.length} users',
  orElse: () => 'No data yet',
);
```

## Convenience Getters

```dart
usersState.isInitial;  // true if ApiInitial
usersState.isLoading;  // true if ApiLoading
usersState.isSuccess;  // true if ApiSuccess
usersState.isFailure;  // true if ApiFailure
usersState.isRefresh;  // true if ApiRefresh

usersState.hasData;    // true if success or refresh
usersState.hasError;   // true if failure

usersState.data;       // T? — data from success/refresh, null otherwise
usersState.error;      // Failure? — error from failure, null otherwise
```

## Transform Methods

### `map` — Transform Data

Convert `ApiStatus<T>` to `ApiStatus<R>` without losing state info:

```dart
final ApiStatus<List<UserModel>> models = fetchResult;
final ApiStatus<List<UserViewModel>> viewModels = models.map(
  (users) => users.map(UserViewModel.fromModel).toList(),
);
// ApiSuccess<List<UserModel>> → ApiSuccess<List<UserViewModel>>
// ApiLoading/ApiFailure/etc pass through unchanged
```

### `mapFailure` — Transform Errors

```dart
final uiState = repoState.mapFailure(
  (failure) => UserFriendlyFailure('Something went wrong'),
);
```

### `whenData` — Callback for Any Data State

Fires for both `success` and `refresh`:

```dart
usersState.whenData((users) => cache.save(users));
// Returns null for initial/loading/failure
```

## State Transitions

### `toLoading()`

Transition to loading, discarding existing data:

```dart
usersState = usersState.toLoading();
```

### `toRefresh()`

Transition to refresh, preserving existing data. Falls back to `ApiLoading` if no data exists:

```dart
// Pull-to-refresh: keep showing current list while re-fetching
usersState = usersState.toRefresh();
// ApiSuccess(users) → ApiRefresh(users)
// ApiInitial()      → ApiLoading() (no data to preserve)
```

## `ApiStatus.guard`

Wraps an async call and returns `ApiSuccess` or `ApiFailure` automatically:

```dart
Future<void> fetchUsers() async {
  usersState = usersState.toLoading();

  usersState = await ApiStatus.guard(
    () => repository.fetchUsers(),
    onError: (error, stackTrace) => ServerFailure(
      error.toString(),
      stackTrace: stackTrace,
    ),
  );
}
```

## Failure

`Failure` is abstract — extend it to define domain-specific error types:

```dart
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.stackTrace});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache read failed']);
}

class ValidationFailure extends Failure {
  final Map<String, String> fieldErrors;

  const ValidationFailure(this.fieldErrors)
      : super('Validation failed');
}
```

Each failure carries:

| Field | Type | Description |
|---|---|---|
| `message` | `String` | Human-readable error message |
| `code` | `int?` | Optional error code (e.g. HTTP status) |
| `stackTrace` | `StackTrace?` | Optional stack trace for debugging |

## Full Example with Bloc

```dart
class UsersCubit extends Cubit<ApiStatus<List<User>>> {
  final UserRepository _repository;

  UsersCubit(this._repository) : super(const ApiInitial());

  Future<void> fetch() async {
    emit(const ApiLoading());
    emit(await ApiStatus.guard(
      () => _repository.getUsers(),
      onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
    ));
  }

  Future<void> refresh() async {
    emit(state.toRefresh());
    emit(await ApiStatus.guard(
      () => _repository.getUsers(),
      onError: (e, st) => ServerFailure(e.toString(), stackTrace: st),
    ));
  }
}
```

```dart
// In your widget
BlocBuilder<UsersCubit, ApiStatus<List<User>>>(
  builder: (context, state) => switch (state) {
    ApiInitial()              => const SizedBox.shrink(),
    ApiLoading()              => const CircularProgressIndicator(),
    ApiSuccess(:final data)   => UserList(users: data),
    ApiFailure(:final error)  => ErrorView(message: error.message),
    ApiRefresh(:final data)   => UserList(users: data, refreshing: true),
  },
)
```

## API Reference

### ApiStatus

| Method / Getter | Return Type | Description |
|---|---|---|
| `isInitial`, `isLoading`, `isSuccess`, `isFailure`, `isRefresh` | `bool` | State checks |
| `hasData`, `hasError` | `bool` | Data/error availability |
| `data` | `T?` | Data from success/refresh |
| `error` | `Failure?` | Error from failure |
| `when(...)` | `R` | Exhaustive pattern matching |
| `whenOrNull(...)` | `R?` | Partial matching, returns null |
| `maybeWhen(...)` | `R` | Partial matching with fallback |
| `whenData(callback)` | `R?` | Callback for data states |
| `map(transform)` | `ApiStatus<R>` | Transform data type |
| `mapFailure(transform)` | `ApiStatus<T>` | Transform error type |
| `toLoading()` | `ApiStatus<T>` | Transition to loading |
| `toRefresh()` | `ApiStatus<T>` | Transition to refresh (preserves data) |
| `ApiStatus.guard(action, onError:)` | `Future<ApiStatus<T>>` | Wrap async call |
