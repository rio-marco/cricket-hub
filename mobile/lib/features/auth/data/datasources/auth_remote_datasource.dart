import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

/// Remote data source interface for authentication operations.
abstract class AuthRemoteDataSource {
  Future<AuthResponse> register(String name, String email, String phone, String password);
  Future<AuthResponse> login(String emailOrPhone, String password);
  Future<Map<String, dynamic>> verifyOTP(String userId, String otp);
  Future<Map<String, dynamic>> forgotPassword(String emailOrPhone);
  Future<Map<String, dynamic>> resetPassword(String userId, String otp, String newPassword);
  Future<AuthResponse> refreshToken(String token);
  Future<void> logout([String? refreshToken]);
  Future<User> getProfile();
  Future<User> updateProfile(Map<String, dynamic> data);
  Future<String> uploadAvatar(String filePath);
}

/// Remote data source implementation using Dio HTTP client.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthResponse> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
      throw const ServerException(message: 'Invalid response format from registration.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<AuthResponse> login(String emailOrPhone, String password) async {
    try {
      final isEmail = emailOrPhone.contains('@');
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'emailOrPhone': emailOrPhone,
          if (isEmail) 'email': emailOrPhone else 'phone': emailOrPhone,
          'password': password,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
      throw const ServerException(message: 'Invalid response format from login.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOTP(String userId, String otp) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'userId': userId,
          'otp': otp,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'OTP verified successfully'};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String emailOrPhone) async {
    try {
      final isEmail = emailOrPhone.contains('@');
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {
          'emailOrPhone': emailOrPhone,
          if (isEmail) 'email': emailOrPhone else 'phone': emailOrPhone,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Password reset OTP sent.'};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword(
    String userId,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'userId': userId,
          'otp': otp,
          'newPassword': newPassword,
          'password': newPassword,
        },
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Password has been reset successfully.'};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken(String token) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': token},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AuthResponse.fromJson(data);
      }
      throw const ServerException(message: 'Invalid response format from token refresh.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> logout([String? refreshToken]) async {
    try {
      await _dio.post(
        ApiEndpoints.logout,
        data: {
          if (refreshToken != null) 'refreshToken': refreshToken,
        },
      );
    } catch (e) {
      // Even if network logout fails, local tokens will be cleared
      _handleError(e);
    }
  }

  @override
  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final userMap = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : (data['user'] is Map<String, dynamic>
                ? data['user'] as Map<String, dynamic>
                : data);
        return UserModel.fromJson(userMap);
      }
      throw const ServerException(message: 'Invalid profile data received.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.profile,
        data: data,
      );
      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final userMap = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['user'] is Map<String, dynamic>
                ? resData['user'] as Map<String, dynamic>
                : resData);
        return UserModel.fromJson(userMap);
      }
      throw const ServerException(message: 'Invalid response format from profile update.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      final fileName = filePath.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.avatar,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final url = data['avatarUrl'] ??
            data['url'] ??
            data['avatar'] ??
            data['data']?['avatarUrl'] ??
            data['data']?['url'];
        if (url != null) return url.toString();
      }
      throw const ServerException(message: 'Avatar uploaded but URL was not returned.');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Maps Dio errors or generic errors to domain-specific AppExceptions
  Never _handleError(dynamic error) {
    if (error is AppException) throw error;

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final responseData = response?.data;

      String message = 'An unexpected error occurred. Please try again.';
      Map<String, dynamic>? errors;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
        if (responseData['errors'] is Map) {
          errors = Map<String, dynamic>.from(responseData['errors'] as Map);
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        message = responseData;
      }

      if (statusCode == 401) {
        throw UnauthorizedException(message: message);
      } else if (statusCode == 403) {
        throw ForbiddenException(message: message);
      } else if (statusCode == 404) {
        throw NotFoundException(message: message);
      } else if (statusCode == 422 || (statusCode == 400 && errors != null)) {
        throw ValidationException(
          errors: errors ?? {'general': message},
          message: message,
        );
      } else {
        throw ServerException(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );
      }
    }

    throw ServerException(message: error.toString());
  }
}
