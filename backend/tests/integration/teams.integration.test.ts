import { Types } from 'mongoose';

import { InvitationStatus, TeamMemberRole } from '../../src/constants/enums';
import Team from '../../src/models/Team';
import TeamInvitation from '../../src/models/TeamInvitation';
import TeamMember from '../../src/models/TeamMember';
import User from '../../src/models/User';
import {
  addMemberViaApi,
  api,
  bearer,
  createPlayerInDb,
  createPlayerViaApi,
  createTeamViaApi,
  registerAndVerify,
  uniqueValue,
} from './helpers';

describe('MongoDB integration: teams', () => {
  it('creates a team with a real owner reference and prevents duplicate names', async () => {
    const owner = await registerAndVerify('team-owner');
    const name = `Integration Eleven ${uniqueValue()}`;

    const team = await createTeamViaApi(owner, name);
    const stored = await Team.findById(team._id);
    expect(stored?.name).toBe(name);
    expect(stored?.owner.toString()).toBe(owner.userId);
    expect(stored?.isActive).toBe(true);
    expect((await User.findById(owner.userId))?.role).toBe('TEAM_OWNER');

    const duplicate = await api()
      .post('/api/v1/teams')
      .set('Authorization', bearer(owner.accessToken))
      .send({ name: name.toLowerCase() })
      .expect(409);
    expect(duplicate.body.success).toBe(false);
    expect(await Team.countDocuments({ name })).toBe(1);
  });

  it('allows only the owner to update persisted team details', async () => {
    const owner = await registerAndVerify('team-update-owner');
    const other = await registerAndVerify('team-update-other');
    const team = await createTeamViaApi(owner, `Update Team ${uniqueValue()}`);

    const forbidden = await api()
      .put(`/api/v1/teams/${team._id}`)
      .set('Authorization', bearer(other.accessToken))
      .send({ description: 'Unauthorized update' })
      .expect(403);
    expect(forbidden.body.success).toBe(false);

    const updated = await api()
      .put(`/api/v1/teams/${team._id}`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ description: 'Owner update', location: 'Updated Ground' })
      .expect(200);
    expect(updated.body.data.description).toBe('Owner update');

    const stored = await Team.findById(team._id);
    expect(stored?.location).toBe('Updated Ground');
    expect(stored?.description).toBe('Owner update');
  });

  it('adds and removes members with duplicate protection at API and index level', async () => {
    const owner = await registerAndVerify('team-member-owner');
    const team = await createTeamViaApi(owner, `Member Team ${uniqueValue()}`);
    const player = await createPlayerInDb(new Types.ObjectId(owner.userId));

    const member = await addMemberViaApi(owner, team._id, player._id.toString());
    expect(member.player._id.toString()).toBe(player._id.toString());
    expect(await TeamMember.countDocuments({ team: team._id })).toBe(1);

    await api()
      .post(`/api/v1/teams/${team._id}/members`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ playerId: player._id.toString() })
      .expect(409);

    const removed = await api()
      .delete(`/api/v1/teams/${team._id}/members/${player._id}`)
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);
    expect(removed.body.data.removed).toBe(true);
    expect(await TeamMember.countDocuments({ team: team._id })).toBe(0);
  });

  it('persists invitations and enrolls the invited player only after acceptance', async () => {
    const owner = await registerAndVerify('invite-owner');
    const invitee = await registerAndVerify('invitee');
    const team = await createTeamViaApi(owner, `Invite Team ${uniqueValue()}`);
    const player = await createPlayerViaApi(invitee, { city: 'Invitee City' });

    const invitation = await api()
      .post(`/api/v1/teams/${team._id}/invite`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ playerId: player._id, message: 'Join our team' })
      .expect(201);
    expect(invitation.body.data.status).toBe(InvitationStatus.PENDING);
    expect(invitation.body.data.player.user._id.toString()).toBe(invitee.userId);

    await api()
      .post(`/api/v1/teams/${team._id}/invite`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ playerId: player._id })
      .expect(409);

    const wrongUser = await registerAndVerify('invite-wrong-user');
    await api()
      .put(`/api/v1/teams/invitations/${invitation.body.data._id}`)
      .set('Authorization', bearer(wrongUser.accessToken))
      .send({ status: InvitationStatus.ACCEPTED })
      .expect(403);

    const accepted = await api()
      .put(`/api/v1/teams/invitations/${invitation.body.data._id}`)
      .set('Authorization', bearer(invitee.accessToken))
      .send({ status: InvitationStatus.ACCEPTED })
      .expect(200);
    expect(accepted.body.data.status).toBe(InvitationStatus.ACCEPTED);
    expect(await TeamMember.countDocuments({ team: team._id, player: player._id })).toBe(1);

    const received = await api()
      .get('/api/v1/teams/user/invitations')
      .set('Authorization', bearer(invitee.accessToken))
      .expect(200);
    expect(received.body.data.some((item: any) => item._id === invitation.body.data._id)).toBe(true);
  });

  it('handles join requests and keeps leadership fields synchronized with member roles', async () => {
    const owner = await registerAndVerify('join-owner');
    const applicant = await registerAndVerify('join-applicant');
    const team = await createTeamViaApi(owner, `Join Team ${uniqueValue()}`);
    const player = await createPlayerViaApi(applicant);

    const request = await api()
      .post(`/api/v1/teams/${team._id}/join`)
      .set('Authorization', bearer(applicant.accessToken))
      .expect(201);
    expect(request.body.data.type).toBe('JOIN_REQUEST');

    const outsider = await registerAndVerify('join-outsider');
    await api()
      .put(`/api/v1/teams/invitations/${request.body.data._id}`)
      .set('Authorization', bearer(outsider.accessToken))
      .send({ status: InvitationStatus.ACCEPTED })
      .expect(403);

    await api()
      .put(`/api/v1/teams/invitations/${request.body.data._id}`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ status: InvitationStatus.ACCEPTED })
      .expect(200);

    const roleUpdate = await api()
      .put(`/api/v1/teams/${team._id}/members/${player._id}/role`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ role: TeamMemberRole.CAPTAIN })
      .expect(200);
    expect(roleUpdate.body.data.role).toBe(TeamMemberRole.CAPTAIN);

    const stored = await Team.findById(team._id);
    expect(stored?.captain?.toString()).toBe(player._id);
    expect(
      (await TeamMember.findById(roleUpdate.body.data._id))?.role
    ).toBe(TeamMemberRole.CAPTAIN);
  });

  it('cleans up memberships and invitations when the owner deletes a team', async () => {
    const owner = await registerAndVerify('delete-owner');
    const invitee = await registerAndVerify('delete-invitee');
    const team = await createTeamViaApi(owner, `Delete Team ${uniqueValue()}`);
    const memberPlayer = await createPlayerInDb(new Types.ObjectId(owner.userId));
    const invitedPlayer = await createPlayerViaApi(invitee);

    await addMemberViaApi(owner, team._id, memberPlayer._id.toString());
    await api()
      .post(`/api/v1/teams/${team._id}/invite`)
      .set('Authorization', bearer(owner.accessToken))
      .send({ playerId: invitedPlayer._id })
      .expect(201);

    const deleted = await api()
      .delete(`/api/v1/teams/${team._id}`)
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);
    expect(deleted.body.data.deleted).toBe(true);

    expect(await Team.findById(team._id)).toBeNull();
    expect(await TeamMember.countDocuments({ team: team._id })).toBe(0);
    expect(await TeamInvitation.countDocuments({ team: team._id })).toBe(0);
  });
});
