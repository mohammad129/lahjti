import 'package:flutter/foundation.dart';
import 'exceptions.dart';

/// Base class for UI-friendly failures.
/// Never exposes raw SQL, internal stack traces, or server payloads.
@immutable
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => message.hashCode ^ statusCode.hashCode;

  @override
  String toString() => '$runtimeType(message: $message, code: $statusCode)';
}

/// Friendly failure for connection or network errors.
class NetworkFailure extends Failure {
  final NetworkErrorType errorType;

  const NetworkFailure({
    required super.message,
    required this.errorType,
    super.statusCode,
  });
}

/// Friendly failure for backend server errors.
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'صار معنا خلل بسيط. جرب مرة ثانية.',
    super.statusCode,
  });
}

/// Friendly failure for authorization errors.
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
    super.statusCode = 401,
  });
}

/// Generic friendly fallback failure.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'صار معنا خلل بسيط. جرب مرة ثانية.',
    super.statusCode,
  });
}

/// Helper mapping exceptions to user-facing Failures.
class ErrorMapper {
  ErrorMapper._();

  static Failure mapExceptionToFailure(Object error) {
    if (error is NetworkException) {
      switch (error.errorType) {
        case NetworkErrorType.noInternet:
          return NetworkFailure(
            message: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
            errorType: error.errorType,
            statusCode: error.statusCode,
          );
        case NetworkErrorType.connectionTimeout:
        case NetworkErrorType.sendTimeout:
        case NetworkErrorType.receiveTimeout:
          return NetworkFailure(
            message: 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
            errorType: error.errorType,
            statusCode: error.statusCode,
          );
        case NetworkErrorType.unauthorized:
          return AuthFailure(statusCode: error.statusCode);
        case NetworkErrorType.serverError:
          return ServerFailure(statusCode: error.statusCode);
        default:
          return NetworkFailure(
            message: 'صار معنا خلل بسيط في الاتصال. جرب مرة ثانية.',
            errorType: error.errorType,
            statusCode: error.statusCode,
          );
      }
    }

    if (error is AuthException) {
      return AuthFailure(statusCode: error.statusCode);
    }

    if (error is ServerException) {
      return ServerFailure(statusCode: error.statusCode);
    }

    return const UnknownFailure();
  }
}
