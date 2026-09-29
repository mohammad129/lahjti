import 'dart:io';
import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Interceptor that translates low-level DioExceptions into structured [NetworkException]s.
class NetworkErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _handleDioException(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        message: exception.message,
      ),
    );
  }

  static NetworkException _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return const NetworkException(
          message:
              'انتهت مهلة الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مجددًا.',
          errorType: NetworkErrorType.connectionTimeout,
        );
      case DioExceptionType.sendTimeout:
        return const NetworkException(
          message: 'انتهت مهلة إرسال البيانات إلى الخادم.',
          errorType: NetworkErrorType.sendTimeout,
        );
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message:
              'استغرق استلام الرد وقتًا أطول من المتوقع. يرجى المحاولة مرة أخرى.',
          errorType: NetworkErrorType.receiveTimeout,
        );
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'شهادة أمان الاتصال غير صالحة.',
          errorType: NetworkErrorType.badCertificate,
        );
      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'تم إلغاء الطلب.',
          errorType: NetworkErrorType.cancelled,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message:
              'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى (${error.requestOptions.baseUrl})',
          errorType: NetworkErrorType.noInternet,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException) {
          return NetworkException(
            message:
                'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى (${error.requestOptions.baseUrl})',
            errorType: NetworkErrorType.noInternet,
          );
        }
        return NetworkException(
          message: 'حدث خطأ غير متوقع في الشبكة.',
          errorType: NetworkErrorType.unknown,
          originalError: error.error,
        );
    }
  }

  static NetworkException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    String? serverArabicMsg;
    String? serverMsg;

    if (response?.data is Map) {
      final data = response!.data as Map;
      if (data['error'] is Map) {
        final err = data['error'] as Map;
        serverArabicMsg = err['arabicMessage']?.toString();
        serverMsg = err['message']?.toString();
      } else if (data['error'] is String) {
        serverMsg = data['error'].toString();
      } else if (data['message'] is String) {
        serverMsg = data['message'].toString();
      }
    }

    switch (statusCode) {
      case 400:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'طلب غير صالح. يرجى التحقق والمحاولة مجددًا.',
          errorType: NetworkErrorType.badRequest,
          statusCode: statusCode,
        );
      case 401:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'جلسة المستخدم منتهية. يرجى تسجيل الدخول مجددًا.',
          errorType: NetworkErrorType.unauthorized,
          statusCode: statusCode,
        );
      case 403:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'انتهت الفترة التجريبية أو الاشتراك. يرجى ترقية الخطة للمتابعة.',
          errorType: NetworkErrorType.forbidden,
          statusCode: statusCode,
        );
      case 404:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'الخدمة المطلوبة غير متوفرة حاليًا.',
          errorType: NetworkErrorType.notFound,
          statusCode: statusCode,
        );
      case 409:
        return NetworkException(
          message: serverArabicMsg ?? serverMsg ?? 'حدث تعارض في البيانات.',
          errorType: NetworkErrorType.conflict,
          statusCode: statusCode,
        );
      case 429:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'وصلت إلى حد الاستخدام الحالي. يمكنك المحاولة لاحقًا أو مراجعة خطتك.',
          errorType: NetworkErrorType.quotaExceeded,
          statusCode: statusCode,
        );
      case 502:
      case 503:
      case 504:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'تعذر الحصول على رد من المدرّب الآن. حاول مرة أخرى.',
          errorType: NetworkErrorType.aiUnavailable,
          statusCode: statusCode,
        );
      case 500:
      default:
        return NetworkException(
          message:
              serverArabicMsg ??
              serverMsg ??
              'حدث خطأ في الخادم. يرجى المحاولة لاحقًا.',
          errorType: NetworkErrorType.serverError,
          statusCode: statusCode,
        );
    }
  }
}
