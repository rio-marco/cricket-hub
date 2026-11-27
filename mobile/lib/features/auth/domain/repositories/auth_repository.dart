import '../entities/auth_response.dart';
import '../entities/user.dart';

/// Contract definition for Authentication repository operations.
abstract class AuthRepository {
  /// Registers a new user with name, email, phone, and password.
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  /// Authenticates a user using email or phone, and password.
  Future<AuthResponse> login({
    required String emailOrPhone,
    required String password,
  });

  /// Verifies one-time password (OTP) for user account.
  Future<Map<String, dynamic>> verifyOTP({
    required String userId,
    required String otp,
  });

  Future<Map<String, dynamic>> resendOTP({
    String? userId,
    String? emailOrPhone,
  });

  /// Initiates password reset by requesting OTP to registered email or phone.
  Future<Map<String, dynamic>> forgotPassword({
    required String emailOrPhone,
  });

  /// Resets password using valid OTP and new password.
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String otp,
    required String newPassword,
  });

  /// Refreshes access token using active refresh token.
  Future<AuthResponse> refreshToken({
    required String token,
  });

  /// Logs out user, invalidating session on server and deleting local tokens.
  Future<void> logout({
    String? refreshToken,
    String? fcmToken,
  });

  /// Retrieves the current user's profile details from remote server.
  Future<User> getProfile();

  /// Updates current user profile details.
  Future<User> updateProfile(Map<String, dynamic> data);

  /// Uploads user avatar image file and returns public image URL.
  Future<String> uploadAvatar(String filePath);

  /// Checks if valid authenticated session exists and returns user if available.
  Future<User?> checkAuth();

  /// Retrieves locally cached user info if available.
  Future<User?> getStoredUser();

  /// Checks whether user is currently authenticated with a valid token.
  Future<bool> isAuthenticated();
}
