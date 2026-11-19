import 'dart:convert';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import '../../domain/entities/auth_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of [AuthRepository] managing network calls, local session
/// caching via [SecureStorage], and mapping exceptions to domain [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SecureStorage secureStorage,
  })  : _remoteDataSource = remoteDataSource,
        _secureStorage = secureStorage;

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        name,
        email,
        phone,
        password,
      );

      if (response.accessToken.isNotEmpty) {
        await _secureStorage.saveToken(response.accessToken);
      }
      if (response.refreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(response.refreshToken);
      }
      await _secureStorage.saveUser(jsonEncode(response.user.toJson()));

      return response;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<AuthResponse> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(emailOrPhone, password);

      if (response.accessToken.isNotEmpty) {
        await _secureStorage.saveToken(response.accessToken);
      }
      if (response.refreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(response.refreshToken);
      }
      await _secureStorage.saveUser(jsonEncode(response.user.toJson()));

      return response;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOTP({
    required String userId,
    required String otp,
  }) async {
    try {
      final result = await _remoteDataSource.verifyOTP(userId, otp);

      // If backend returns new tokens upon OTP verification, persist them
      final token = result['token'] ?? result['accessToken'] ?? result['data']?['token'];
      if (token != null && token.toString().isNotEmpty) {
        await _secureStorage.saveToken(token.toString());
      }
      final refreshToken = result['refreshToken'] ?? result['data']?['refreshToken'];
      if (refreshToken != null && refreshToken.toString().isNotEmpty) {
        await _secureStorage.saveRefreshToken(refreshToken.toString());
      }
      final userMap = result['user'] ?? result['data']?['user'];
      if (userMap is Map<String, dynamic>) {
        await _secureStorage.saveUser(jsonEncode(userMap));
      }

      return result;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({
    required String emailOrPhone,
  }) async {
    try {
      return await _remoteDataSource.forgotPassword(emailOrPhone);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String otp,
    required String newPassword,
  }) async {
    try {
      return await _remoteDataSource.resetPassword(userId, otp, newPassword);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<AuthResponse> refreshToken({
    required String token,
  }) async {
    try {
      final response = await _remoteDataSource.refreshToken(token);
      if (response.accessToken.isNotEmpty) {
        await _secureStorage.saveToken(response.accessToken);
      }
      if (response.refreshToken.isNotEmpty) {
        await _secureStorage.saveRefreshToken(response.refreshToken);
      }
      return response;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    try {
      final token = refreshToken ?? await _secureStorage.getRefreshToken();
      await _remoteDataSource.logout(token);
    } catch (_) {
      // Ignore network errors on logout so local credentials are always cleared
    } finally {
      await _secureStorage.clearAll();
    }
  }

  @override
  Future<User> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      await _secureStorage.saveUser(jsonEncode(user.toJson()));
      return user;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatedUser = await _remoteDataSource.updateProfile(data);
      await _secureStorage.saveUser(jsonEncode(updatedUser.toJson()));
      return updatedUser;
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      return await _remoteDataSource.uploadAvatar(filePath);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<User?> checkAuth() async {
    try {
      final hasToken = await _secureStorage.hasToken();
      if (!hasToken) return null;

      // First try fetching latest profile from server
      try {
        final profile = await _remoteDataSource.getProfile();
        await _secureStorage.saveUser(jsonEncode(profile.toJson()));
        return profile;
      } catch (_) {
        // Fallback to locally cached user if offline
        return await getStoredUser();
      }
    } catch (_) {
      await _secureStorage.clearAll();
      return null;
    }
  }

  @override
  Future<User?> getStoredUser() async {
    try {
      final userJson = await _secureStorage.getUser();
      if (userJson != null && userJson.isNotEmpty) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(map);
      }
    } catch (_) {
      // Cached parsing failed
    }
    return null;
  }

  @override
  Future<bool> isAuthenticated() async {
    return await _secureStorage.hasToken();
  }
}
