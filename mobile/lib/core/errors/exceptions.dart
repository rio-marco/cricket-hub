/// Base class for all application-level exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => '$runtimeType: $message (status: $statusCode)';
}

/// Thrown when server returns an error response (5xx or unhandled status codes).
class ServerException extends AppException {
  final Map<String, dynamic>? errors;

  const ServerException({
    required String message,
    int? statusCode,
    this.errors,
  }) : super(message, statusCode);

  @override
  String toString() =>
      'ServerException: $message (statusCode: $statusCode, errors: $errors)';
}

/// Thrown when local persistent cache reading/writing fails.
class CacheException extends AppException {
  const CacheException({required String message}) : super(message);
}

/// Thrown when no network connection is available or request times out.
class NetworkException extends AppException {
  const NetworkException({required String message}) : super(message);
}

/// Thrown when request is not authenticated (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Session expired or unauthorized. Please log in again.',
  }) : super(message, 401);
}

/// Thrown when user does not have permission for the requested resource (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException({
    String message = 'You do not have permission to perform this action.',
  }) : super(message, 403);
}

/// Thrown when requested resource cannot be found (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'The requested resource was not found.',
  }) : super(message, 404);
}

/// Thrown when request payload fails validation rules (HTTP 422 or 400).
class ValidationException extends AppException {
  final Map<String, dynamic> errors;

  const ValidationException({
    required this.errors,
    String message = 'Input validation failed. Please review your entries.',
  }) : super(message, 422);

  /// Helper to get the first validation error message.
  String? get firstError {
    if (errors.isEmpty) return null;
    final firstVal = errors.values.first;
    if (firstVal is List && firstVal.isNotEmpty) {
      return firstVal.first.toString();
    }
    return firstVal.toString();
  }

  @override
  String toString() => 'ValidationException: $message, errors: $errors';
}
