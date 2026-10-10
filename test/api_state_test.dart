import 'package:api_state/api_state.dart';
import 'package:test/test.dart';

class TestFailure extends Failure {
  const TestFailure(super.message, {super.code, super.stackTrace});
}

void main() {
  group('ApiStatus', () {
    test('initial state', () {
      const status = ApiInitial<int>();
      expect(status.isInitial, true);
      expect(status.hasData, false);
      expect(status.data, isNull);
    });

    test('loading state', () {
      const status = ApiLoading<int>();
      expect(status.isLoading, true);
    });

    test('success state', () {
      const status = ApiSuccess(42);
      expect(status.isSuccess, true);
      expect(status.data, 42);
      expect(status.hasData, true);
    });

    test('failure state', () {
      const status = ApiFailure<int>(TestFailure('Not found', code: 404));
      expect(status.isFailure, true);
      expect(status.error.message, 'Not found');
      expect(status.error.code, 404);
    });

    test('refresh state', () {
      const status = ApiRefresh(42);
      expect(status.isRefresh, true);
      expect(status.data, 42);
      expect(status.hasData, true);
    });

    test('when covers all cases', () {
      const ApiStatus<String> status = ApiSuccess('data');
      final result = status.when(
        initialOrLoading: () => 'loading',
        success: (data) => 'success: $data',
        failure: (error) => 'error',
      );
      expect(result, 'success: data');
    });

    test('map transforms data', () {
      const ApiStatus<int> status = ApiSuccess(10);
      final mapped = status.map((data) => data.toString());
      expect(mapped.data, '10');
      expect(mapped.isSuccess, true);
    });

    test('sealed class pattern matching', () {
      const ApiStatus<int> status = ApiSuccess(42);
      final result = switch (status) {
        ApiInitial() => 'initial',
        ApiLoading() => 'loading',
        ApiSuccess(:final data) => 'success: $data',
        ApiFailure(:final error) => 'failure: ${error.message}',
        ApiRefresh(:final data) => 'refresh: $data',
        ApiLoadMore(:final data) => 'loading more: $data',
      };
      expect(result, 'success: 42');
    });

    test('equality', () {
      expect(const ApiSuccess(1), equals(const ApiSuccess(1)));
      expect(const ApiSuccess(1), isNot(equals(const ApiSuccess(2))));
      expect(const ApiInitial<int>(), equals(const ApiInitial<int>()));
      expect(const ApiLoading<int>(), equals(const ApiLoading<int>()));
    });
  });

  group('whenData', () {
    test('returns value for success', () {
      const ApiStatus<int> status = ApiSuccess(42);
      final result = status.whenData((data) => 'got $data');
      expect(result, 'got 42');
    });

    test('returns value for refresh', () {
      const ApiStatus<int> status = ApiRefresh(10);
      final result = status.whenData((data) => data * 2);
      expect(result, 20);
    });

    test('returns null for loading', () {
      const ApiStatus<int> status = ApiLoading();
      final result = status.whenData((data) => data);
      expect(result, isNull);
    });

    test('returns null for initial', () {
      const ApiStatus<int> status = ApiInitial();
      final result = status.whenData((data) => data);
      expect(result, isNull);
    });

    test('returns null for failure', () {
      const ApiStatus<int> status = ApiFailure(TestFailure('err'));
      final result = status.whenData((data) => data);
      expect(result, isNull);
    });
  });

  group('toLoading / toRefresh', () {
    test('toLoading from any state', () {
      const status = ApiSuccess(42);
      expect(status.toLoading().isLoading, true);
    });

    test('toRefresh preserves data from success', () {
      const ApiStatus<int> status = ApiSuccess(42);
      final refreshed = status.toRefresh();
      expect(refreshed.isRefresh, true);
      expect(refreshed.data, 42);
    });

    test('toRefresh preserves data from refresh', () {
      const ApiStatus<int> status = ApiRefresh(99);
      final refreshed = status.toRefresh();
      expect(refreshed.isRefresh, true);
      expect(refreshed.data, 99);
    });

    test('toRefresh falls back to loading when no data', () {
      const ApiStatus<int> status = ApiInitial();
      expect(status.toRefresh().isLoading, true);
    });

    test('toRefresh falls back to loading from failure', () {
      const ApiStatus<int> status = ApiFailure(TestFailure('err'));
      expect(status.toRefresh().isLoading, true);
    });
  });

  group('mapFailure', () {
    test('transforms failure error', () {
      const ApiStatus<int> status = ApiFailure(TestFailure('raw', code: 500));
      final mapped = status.mapFailure(
        (f) => TestFailure('Mapped: ${f.message}', code: f.code),
      );
      expect(mapped.isFailure, true);
      expect(mapped.error?.message, 'Mapped: raw');
      expect(mapped.error?.code, 500);
    });

    test('passes through success unchanged', () {
      const ApiStatus<int> status = ApiSuccess(42);
      final mapped = status.mapFailure((f) => TestFailure('nope'));
      expect(mapped.isSuccess, true);
      expect(mapped.data, 42);
    });

    test('passes through loading unchanged', () {
      const ApiStatus<int> status = ApiLoading();
      final mapped = status.mapFailure((f) => TestFailure('nope'));
      expect(mapped.isLoading, true);
    });
  });

  group('ApiStatus.guard', () {
    test('returns ApiSuccess on successful future', () async {
      final result = await ApiStatus.guard(
        () async => 42,
        onError: (e, st) => TestFailure(e.toString(), stackTrace: st),
      );
      expect(result.isSuccess, true);
      expect(result.data, 42);
    });

    test('returns ApiFailure on thrown exception', () async {
      final result = await ApiStatus.guard<int>(
        () async => throw Exception('boom'),
        onError: (e, st) => TestFailure(e.toString(), stackTrace: st),
      );
      expect(result.isFailure, true);
      expect(result.error?.message, contains('boom'));
      expect(result.error?.stackTrace, isNotNull);
    });
  });

  group('Failure', () {
    test('equality (stackTrace excluded)', () {
      final failure1 = TestFailure('error', code: 500, stackTrace: StackTrace.current);
      const failure2 = TestFailure('error', code: 500);
      expect(failure1, equals(failure2));
    });

    test('stackTrace is preserved', () {
      final trace = StackTrace.current;
      final failure = TestFailure('oops', stackTrace: trace);
      expect(failure.stackTrace, same(trace));
    });

    test('toString', () {
      const failure = TestFailure('oops');
      expect(failure.toString(), contains('oops'));
    });
  });
}
