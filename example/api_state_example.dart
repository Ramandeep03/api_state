import 'package:api_state/api_state.dart';

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.stackTrace});
}

class LoadMoreFailure extends Failure {
  const LoadMoreFailure(super.message, {super.code, super.stackTrace});
}

void main() {
  ApiStatus<String> status = const ApiInitial();
  print(status); // ApiInitial()

  status = const ApiLoading();

  status = const ApiSuccess('Hello World');

  // Using the when() helper:
  final message = status.when(
    initialOrLoading: () => 'Loading...',
    success: (data) => 'Got: $data',
    failure: (error) => 'Error: ${error.message}',
  );
  print(message); // Got: Hello World

  // Using Dart 3 exhaustive switch:
  final label = switch (status) {
    ApiInitial() => 'idle',
    ApiLoading() => 'loading...',
    ApiSuccess(:final data) => 'data: $data',
    ApiFailure(:final error) => 'error: ${error.message}',
    ApiRefresh(:final data) => 'refreshing: $data',
    ApiLoadMore(:final data) => 'loading more: $data',
  };
  print(label); // data: Hello World

  ApiStatus<List<String>> usersState =
      const ApiLoadMore(['Ada', 'Grace']);
  usersState = usersState.toLoadMoreFailure(
    const LoadMoreFailure('Could not fetch the next page'),
  );

  print(usersState.data); // [Ada, Grace] — existing data is preserved
  print(usersState.error is LoadMoreFailure); // true — error subtype identifies it
}
