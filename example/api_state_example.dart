import 'package:api_state/api_state.dart';

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
  };
  print(label); // data: Hello World
}
