import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_response.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';

const _user = User(
  id: 'u1',
  name: 'Test User',
  email: 'test@example.com',
  role: 'NORMAL_USER',
  isVerified: true,
);

class FakeAuthRepository implements AuthRepository {
  Map<String, dynamic> verificationResult = {
    'user': _user.toJson(),
    'tokens': {
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
    },
  };

  @override
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return AuthResponse(user: _user, accessToken: '', refreshToken: '');
  }

  @override
  Future<AuthResponse> login({
    required String emailOrPhone,
    required String password,
  }) async {
    return AuthResponse(
      user: _user,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    );
  }

  @override
  Future<Map<String, dynamic>> verifyOTP({
    required String userId,
    required String otp,
  }) async {
    return verificationResult;
  }

  @override
  Future<Map<String, dynamic>> resendOTP({String? userId, String? emailOrPhone}) async {
    return {'userId': userId ?? 'u1'};
  }

  @override
  Future<Map<String, dynamic>> forgotPassword({required String emailOrPhone}) async {
    return {'userId': 'u1'};
  }

  @override
  Future<Map<String, dynamic>> resetPassword({
    required String userId,
    required String otp,
    required String newPassword,
  }) async {
    return {'message': 'Password reset successfully.'};
  }

  @override
  Future<AuthResponse> refreshToken({required String token}) async {
    return AuthResponse(
      user: _user,
      accessToken: 'refreshed-access',
      refreshToken: 'refreshed-refresh',
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {}

  @override
  Future<User> getProfile() async => _user;

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async => _user;

  @override
  Future<String> uploadAvatar(String filePath) async => '/uploads/avatar.png';

  @override
  Future<User?> checkAuth() async => _user;

  @override
  Future<User?> getStoredUser() async => _user;

  @override
  Future<bool> isAuthenticated() async => true;
}

void main() {
  test('register returns the backend user id without authenticating', () async {
    final notifier = AuthNotifier(FakeAuthRepository());
    addTearDown(notifier.dispose);

    final userId = await notifier.register(
      name: 'Test User',
      email: 'test@example.com',
      phone: '9876543210',
      password: 'Password1',
    );

    expect(userId, 'u1');
    expect(notifier.state, isA<Unauthenticated>());
  });

  test('verify OTP authenticates with the returned user', () async {
    final notifier = AuthNotifier(FakeAuthRepository());
    addTearDown(notifier.dispose);

    final success = await notifier.verifyOTP(userId: 'u1', otp: '123456');

    expect(success, isTrue);
    expect(notifier.state, isA<Authenticated>());
    expect((notifier.state as Authenticated).user.id, 'u1');
  });

  test('forgot password returns the backend user id', () async {
    final notifier = AuthNotifier(FakeAuthRepository());
    addTearDown(notifier.dispose);

    final userId = await notifier.forgotPassword(emailOrPhone: 'test@example.com');

    expect(userId, 'u1');
  });
}
