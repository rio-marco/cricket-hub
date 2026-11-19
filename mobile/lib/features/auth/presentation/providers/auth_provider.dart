import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// =============================================================================
// AUTH STATE (Sealed Hierarchy)
// =============================================================================

/// Sealed class representing the current authentication state.
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

/// Initial uninitialized state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Asynchronous operation in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is successfully signed in
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Authenticated &&
          runtimeType == other.runtimeType &&
          user == other.user;

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'Authenticated(user: ${user.name})';
}

/// User is not logged in / signed out
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Authentication or network failure
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AuthError(message: $message)';
}

// Aliases for convenience
typedef Initial = AuthInitial;
typedef Loading = AuthLoading;
typedef Error = AuthError;

// =============================================================================
// AUTH NOTIFIER
// =============================================================================

/// StateNotifier handling authentication workflow, credentials persistence,
/// session verification, and reactive state updates.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthState.initial());

  /// Verifies if an active token and session exist upon app launch.
  Future<void> checkAuth() async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.checkAuth();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Logs in using email or phone, and password.
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final response = await _authRepository.login(
        emailOrPhone: emailOrPhone.trim(),
        password: password,
      );
      state = AuthState.authenticated(response.user);
      return true;
    } on Failure catch (f) {
      state = AuthState.error(f.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Registers a new user account.
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final response = await _authRepository.register(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );
      state = AuthState.authenticated(response.user);
      return true;
    } on Failure catch (f) {
      state = AuthState.error(f.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Verifies account OTP code.
  Future<bool> verifyOTP({
    required String userId,
    required String otp,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _authRepository.verifyOTP(
        userId: userId,
        otp: otp,
      );

      // Check if user object was returned in OTP response
      final userMap = result['user'] ?? result['data']?['user'];
      if (userMap is Map<String, dynamic>) {
        state = AuthState.authenticated(User.fromJson(userMap));
        return true;
      }

      // Check if session became active
      final user = await _authRepository.checkAuth();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
      return true;
    } on Failure catch (f) {
      state = AuthState.error(f.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Requests password reset OTP.
  Future<bool> forgotPassword({required String emailOrPhone}) async {
    try {
      await _authRepository.forgotPassword(emailOrPhone: emailOrPhone.trim());
      return true;
    } on Failure catch (f) {
      state = AuthState.error(f.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Resets password using received OTP.
  Future<bool> resetPassword({
    required String userId,
    required String otp,
    required String newPassword,
  }) async {
    state = const AuthState.loading();
    try {
      await _authRepository.resetPassword(
        userId: userId,
        otp: otp,
        newPassword: newPassword,
      );
      state = const AuthState.unauthenticated();
      return true;
    } on Failure catch (f) {
      state = AuthState.error(f.message);
      return false;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logs out of the current user session and clears credentials.
  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await _authRepository.logout();
    } catch (_) {
      // Continue clearing local state
    } finally {
      state = const AuthState.unauthenticated();
    }
  }

  /// Clears active error state and returns to unauthenticated.
  void clearError() {
    if (state is AuthError) {
      state = const AuthState.unauthenticated();
    }
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

/// Remote data source provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(apiClient.dio);
});

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    secureStorage: secureStorage,
  );
});

/// Main Auth state notifier provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Alias provider matching Cricket Hub conventions
final authProvider = authStateProvider;

/// Current authenticated user (null if unauthenticated)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState is Authenticated) {
    return authState.user;
  }
  return null;
});

/// True if user is currently authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState is Authenticated;
});
