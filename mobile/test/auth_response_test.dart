import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/auth_response.dart';

void main() {
  test('parses nested token payload returned by the backend', () {
    final response = AuthResponse.fromJson({
      'success': true,
      'message': 'Logged in successfully.',
      'data': {
        'user': {
          '_id': 'u1',
          'name': 'Test User',
          'email': 'test@example.com',
          'isVerified': true,
        },
        'tokens': {
          'accessToken': 'access-token',
          'refreshToken': 'refresh-token',
          'expiresIn': '24h',
        },
      },
    });

    expect(response.user.id, 'u1');
    expect(response.accessToken, 'access-token');
    expect(response.refreshToken, 'refresh-token');
  });

  test('parses tokens from a doubly wrapped payload', () {
    final response = AuthResponse.fromJson({
      'data': {
        'data': {
          'user': {
            'id': 'u2',
            'name': 'Second User',
            'email': 'second@example.com',
          },
          'accessToken': 'nested-access',
          'refreshToken': 'nested-refresh',
        },
      },
    });

    expect(response.accessToken, 'nested-access');
    expect(response.refreshToken, 'nested-refresh');
  });
}
