import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/features/teams/data/models/team_model.dart';

void main() {
  test('uses real team invitation, role, stats, and match endpoints', () {
    expect(ApiEndpoints.userInvitations, '/teams/user/invitations');
    expect(ApiEndpoints.respondToInvitation('i1'), '/teams/invitations/i1');
    expect(ApiEndpoints.teamMemberRole('t1', 'm1'), '/teams/t1/members/m1/role');
    expect(ApiEndpoints.teamStats('t1'), '/teams/t1/stats');
    expect(ApiEndpoints.teamMatches('t1'), '/teams/t1/matches');
  });

  test('parses populated owner and captain from team payload', () {
    final team = TeamModel.fromJson({
      '_id': 't1',
      'name': 'Mumbai Strikers',
      'owner': {'_id': 'u1', 'name': 'Owner One'},
      'captain': {
        '_id': 'p1',
        'user': {'name': 'Captain One'},
      },
      'members': [{'_id': 'm1'}, {'_id': 'm2'}],
      'logo': 'https://img/team.png',
    });

    expect(team.id, 't1');
    expect(team.owner, 'u1');
    expect(team.ownerName, 'Owner One');
    expect(team.captain, 'p1');
    expect(team.captainName, 'Captain One');
    expect(team.memberCount, 2);
    expect(team.logo, 'https://img/team.png');
  });
}
