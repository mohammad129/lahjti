import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import '../errors/exceptions.dart';
import 'error_interceptor.dart';

/// Safe diagnostic logging interceptor that logs endpoints, status, and latency without secrets or tokens.
class SafeDiagnosticInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['request_start_time'] = DateTime.now().millisecondsSinceEpoch;
    if (EnvConfig.enableLogging) {
      // ignore: avoid_print
      print(
        '🌐 [API Request] ${options.method} ${options.baseUrl}${options.path}',
      );
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime =
        response.requestOptions.extra['request_start_time'] as int?;
    final latencyMs =
        startTime != null
            ? DateTime.now().millisecondsSinceEpoch - startTime
            : 0;
    if (EnvConfig.enableLogging) {
      // ignore: avoid_print
      print(
        '✅ [API Response] ${response.requestOptions.method} ${response.requestOptions.path} -> HTTP ${response.statusCode} (${latencyMs}ms)',
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra['request_start_time'] as int?;
    final latencyMs =
        startTime != null
            ? DateTime.now().millisecondsSinceEpoch - startTime
            : 0;
    // ignore: avoid_print
    print(
      '❌ [API Error] ${err.requestOptions.method} ${err.requestOptions.baseUrl}${err.requestOptions.path} -> Status: ${err.response?.statusCode ?? 'None'}, Type: ${err.type}, Latency: ${latencyMs}ms, Message: ${err.message}',
    );
    super.onError(err, handler);
  }
}

/// Provider for the application's singleton [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: EnvConfig.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: EnvConfig.receiveTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer dev_pilot_token_2026',
        'x-user-id': 'pilot_user_android',
      },
    ),
  );

  dio.interceptors.add(SafeDiagnosticInterceptor());
  dio.interceptors.add(NetworkErrorInterceptor());

  return ApiClient(dio);
});

/// Reusable HTTP Client wrapping Dio.
class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Dio get dioInstance => _dio;

  /// Perform a GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  /// Perform a POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  /// Perform a PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  /// Perform a DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _unwrapException(e);
    }
  }

  /// Extracts the mapped [AppException] from [DioException].
  Object _unwrapException(DioException e) {
    if (e.error is AppException) {
      return e.error!;
    }
    return NetworkException(
      message: e.message ?? 'Unknown network exception',
      errorType: NetworkErrorType.unknown,
      statusCode: e.response?.statusCode,
      originalError: e,
    );
  }
}
