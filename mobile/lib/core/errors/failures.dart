import 'exceptions.dart';

/// Base class for all domain-level failures returned by repositories.
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';

  /// Factory helper that converts an AppException into its corresponding Failure.
  factory Failure.fromException(AppException exception) {
    if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        errors: exception.errors,
      );
    } else if (exception is NetworkException) {
      return NetworkFailure(message: exception.message);
    } else if (exception is UnauthorizedException) {
      return UnauthorizedFailure(message: exception.message);
    } else if (exception is ForbiddenException) {
      return ForbiddenFailure(message: exception.message);
    } else if (exception is NotFoundException) {
      return NotFoundFailure(message: exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        errors: exception.errors,
      );
    } else if (exception is CacheException) {
      return CacheFailure(message: exception.message);
    }
    return ServerFailure(message: exception.message);
  }
}

/// Represents failure from server response or internal server error.
class ServerFailure extends Failure {
  final Map<String, dynamic>? errors;

  const ServerFailure({
    required String message,
    int? statusCode,
    this.errors,
  }) : super(message, statusCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ServerFailure &&
          errors.toString() == other.errors.toString();

  @override
  int get hashCode => Object.hash(super.hashCode, errors.toString());
}

/// Represents failure when local storage read/write operation fails.
class CacheFailure extends Failure {
  const CacheFailure({required String message}) : super(message);
}

/// Represents failure when device cannot connect to network or times out.
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'Unable to connect to Cricket Hub servers. Please check your internet.',
  }) : super(message);
}

/// Represents failure when authentication credentials are missing, invalid, or expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    String message = 'Authentication required. Please sign in to continue.',
  }) : super(message, 401);
}

/// Represents failure when user is not authorized to perform the action.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    String message = 'You do not have permission to access this resource.',
  }) : super(message, 403);
}

/// Represents failure when requested item is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = 'Requested resource was not found.',
  }) : super(message, 404);
}

/// Represents failure when submitted data does not satisfy validation rules.
class ValidationFailure extends Failure {
  final Map<String, dynamic> errors;

  const ValidationFailure({
    required this.errors,
    String message = 'Please correct the highlighted fields and try again.',
  }) : super(message, 422);

  /// Helper to get single user-facing error message.
  String? get firstError {
    if (errors.isEmpty) return null;
    final firstVal = errors.values.first;
    if (firstVal is List && firstVal.isNotEmpty) {
      return firstVal.first.toString();
    }
    return firstVal.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ValidationFailure &&
          errors.toString() == other.errors.toString();

  @override
  int get hashCode => Object.hash(super.hashCode, errors.toString());
}
