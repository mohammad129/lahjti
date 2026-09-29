/// Base exception class for all application-level exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (Status: $statusCode)';
}

/// Network-specific exception types
enum NetworkErrorType {
  noInternet,
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  quotaExceeded,
  serverError,
  aiUnavailable,
  badCertificate,
  cancelled,
  unknown,
}

/// Thrown when an HTTP or socket request fails.
class NetworkException extends AppException {
  final NetworkErrorType errorType;

  const NetworkException({
    required super.message,
    required this.errorType,
    super.statusCode,
    super.originalError,
  });

  @override
  String toString() =>
      'NetworkException[$errorType]: $message (Status: $statusCode)';
}

/// Thrown when backend returns an unexpected server-side issue.
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode,
    super.originalError,
  });
}

/// Thrown when local cache or persistence fails.
class CacheException extends AppException {
  const CacheException({required super.message, super.originalError});
}

/// Thrown for authentication failures.
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.originalError,
  });
}
