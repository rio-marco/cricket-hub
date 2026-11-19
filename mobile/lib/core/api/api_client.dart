import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';

/// Complete HTTP client built on Dio with authentication, error mapping,
/// automatic token refresh, and multipart upload capabilities.
class ApiClient {
  final Dio _dio;
  final SecureStorage _storage;
  final AppConfig _config;

  ApiClient({
    required AppConfig config,
    required SecureStorage storage,
    Dio? dio,
  })  : _config = config,
        _storage = storage,
        _dio = dio ?? Dio() {
    _configureDio();
  }

  Dio get dio => _dio;

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      sendTimeout: _config.connectTimeout,
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      responseType: ResponseType.json,
    );

    _dio.interceptors.clear();

    // 1. Auth & Refresh Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach bearer token if available and not already set
          if (!options.headers.containsKey(HttpHeaders.authorizationHeader)) {
            final token = await _storage.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check for 401 Unauthorized to attempt token refresh
          if (error.response?.statusCode == 401) {
            final requestOptions = error.requestOptions;

            // Avoid infinite refresh loops if refresh endpoint itself failed with 401
            final isRefreshRequest = requestOptions.path.contains(ApiEndpoints.refreshToken) ||
                requestOptions.extra['isRetry'] == true;

            if (!isRefreshRequest) {
              final refreshed = await _attemptTokenRefresh();
              if (refreshed) {
                try {
                  final newToken = await _storage.getToken();
                  final retryOptions = Options(
                    method: requestOptions.method,
                    headers: Map<String, dynamic>.from(requestOptions.headers)
                      ..[HttpHeaders.authorizationHeader] = 'Bearer $newToken',
                    responseType: requestOptions.responseType,
                    contentType: requestOptions.contentType,
                    extra: Map<String, dynamic>.from(requestOptions.extra)..['isRetry'] = true,
                  );

                  final retryResponse = await _dio.request(
                    requestOptions.path,
                    data: requestOptions.data,
                    queryParameters: requestOptions.queryParameters,
                    options: retryOptions,
                  );

                  return handler.resolve(retryResponse);
                } catch (retryError) {
                  if (retryError is DioException) {
                    return handler.next(retryError);
                  }
                }
              } else {
                // Refresh failed; clear session
                await _storage.clearAll();
              }
            }
          }

          return handler.next(error);
        },
      ),
    );

    // 2. Logging Interceptor (debug/configured environments)
    if (_config.enableLogging || kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) {
            debugPrint('[CricketHub API] $obj');
          },
        ),
      );
    }
  }

  /// Attempts to exchange refresh token for a fresh JWT access token.
  Future<bool> _attemptTokenRefresh() async {
    final currentRefreshToken = await _storage.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return false;
    }

    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: _config.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': currentRefreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is Map ? response.data : {};
        final newAccessToken = data['token'] ?? data['accessToken'] ?? data['data']?['token'];
        final newRefreshToken = data['refreshToken'] ?? data['data']?['refreshToken'];

        if (newAccessToken != null) {
          await _storage.saveToken(newAccessToken.toString());
          if (newRefreshToken != null) {
            await _storage.saveRefreshToken(newRefreshToken.toString());
          }
          return true;
        }
      }
    } catch (_) {
      // Refresh failed
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // HTTP Methods with Error Mapping
  // ---------------------------------------------------------------------------

  /// Performs a GET request.
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
      throw _handleDioError(e);
    }
  }

  /// Performs a POST request.
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
      throw _handleDioError(e);
    }
  }

  /// Performs a PUT request.
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
      throw _handleDioError(e);
    }
  }

  /// Performs a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Performs a DELETE request.
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
      throw _handleDioError(e);
    }
  }

  /// Performs a multipart POST request (e.g., photo uploads, attachments).
  Future<Response<T>> multipartPost<T>(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Exception Mapping
  // ---------------------------------------------------------------------------

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timed out. Please check your network and try again.',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Unable to connect to Cricket Hub server. Please check your internet.',
        );

      case DioExceptionType.badResponse:
        final response = error.response;
        if (response == null) {
          return const ServerException(message: 'Unknown server error occurred.');
        }

        final statusCode = response.statusCode ?? 500;
        final responseData = response.data;
        String message = 'An error occurred. Please try again.';
        Map<String, dynamic>? errors;

        if (responseData is Map) {
          message = responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              message;

          if (responseData['errors'] is Map) {
            errors = Map<String, dynamic>.from(responseData['errors']);
          }
        } else if (responseData is String && responseData.isNotEmpty) {
          message = responseData;
        }

        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        } else if (statusCode == 403) {
          return ForbiddenException(message: message);
        } else if (statusCode == 404) {
          return NotFoundException(message: message);
        } else if (statusCode == 422 || (statusCode == 400 && errors != null)) {
          return ValidationException(
            message: message,
            errors: errors ?? {'general': message},
          );
        } else if (statusCode >= 500) {
          return ServerException(
            message: message,
            statusCode: statusCode,
            errors: errors,
          );
        }

        return ServerException(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException(message: 'Security certificate verification failed.');

      case DioExceptionType.unknown:
      default:
        return NetworkException(
          message: error.message ?? 'An unexpected network error occurred.',
        );
    }
  }
}

/// Riverpod provider for ApiClient.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(config: config, storage: storage);
});
