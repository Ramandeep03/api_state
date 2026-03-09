/// Base class representing a failure from an API call or other operation.
///
/// Extend this to create specific failure types:
/// ```dart
/// class NetworkFailure extends Failure {
///   const NetworkFailure([super.message = 'No internet connection']);
/// }
///
/// class ServerFailure extends Failure {
///   const ServerFailure(super.message, {super.code});
/// }
/// ```
abstract class Failure {
  /// A human-readable error message.
  final String message;

  /// An optional error code (e.g. HTTP status code).
  final int? code;

  /// An optional stack trace for debugging/crash reporting.
  final StackTrace? stackTrace;

  const Failure(this.message, {this.code, this.stackTrace});

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && message == other.message && code == other.code;

  @override
  int get hashCode => Object.hash(message, code);
}
