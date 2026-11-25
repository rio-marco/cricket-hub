import { Types } from 'mongoose';

import {
  MatchFormat,
  MatchStatus,
  TournamentStatus,
  TournamentTeamStatus,
} from '../../src/constants/enums';
import Match from '../../src/models/Match';
import Tournament from '../../src/models/Tournament';
import TournamentTeam from '../../src/models/TournamentTeam';
import {
  api,
  bearer,
  createTeamViaApi,
  createTournamentPayload,
  openTournamentViaApi,
  registerAndVerify,
  registerTeamInTournament,
  uniqueValue,
} from './helpers';

describe('MongoDB integration: tournaments', () => {
  it('persists tournament creation, enforces organizer updates, and validates dates', async () => {
    const organizer = await registerAndVerify('tournament-organizer');
    const other = await registerAndVerify('tournament-other');
    const payload = createTournamentPayload(`Tournament ${uniqueValue()}`);

    const created = await api()
      .post('/api/v1/tournaments')
      .set('Authorization', bearer(organizer.accessToken))
      .send(payload)
      .expect(201);
    const tournamentId = created.body.data._id;

    const stored = await Tournament.findById(tournamentId);
    expect(stored?.name).toBe(payload.name);
    expect(stored?.organizer.toString()).toBe(organizer.userId);
    expect(stored?.status).toBe(TournamentStatus.DRAFT);
    expect(stored?.maxTeams).toBe(4);

    await api()
      .put(`/api/v1/tournaments/${tournamentId}`)
      .set('Authorization', bearer(other.accessToken))
      .send({ description: 'Unauthorized' })
      .expect(403);

    const updated = await api()
      .put(`/api/v1/tournaments/${tournamentId}`)
      .set('Authorization', bearer(organizer.accessToken))
      .send({ description: 'Organizer update', maxTeams: 8 })
      .expect(200);
    expect(updated.body.data.description).toBe('Organizer update');
    expect((await Tournament.findById(tournamentId))?.maxTeams).toBe(8);

    const invalidDates = await api()
      .post('/api/v1/tournaments')
      .set('Authorization', bearer(organizer.accessToken))
      .send({
        ...createTournamentPayload(`Bad Dates ${uniqueValue()}`),
        endDate: new Date(Date.now() - 86_400_000).toISOString(),
      })
      .expect(400);
    expect(invalidDates.body.success).toBe(false);
  });

  it('enforces lifecycle transitions in the database', async () => {
    const organizer = await registerAndVerify('tournament-status');
    const created = await api()
      .post('/api/v1/tournaments')
      .set('Authorization', bearer(organizer.accessToken))
      .send(createTournamentPayload(`Status Tournament ${uniqueValue()}`))
      .expect(201);
    const tournamentId = created.body.data._id;

    const invalid = await api()
      .put(`/api/v1/tournaments/${tournamentId}/status`)
      .set('Authorization', bearer(organizer.accessToken))
      .send({ status: TournamentStatus.IN_PROGRESS })
      .expect(400);
    expect(invalid.body.message).toContain('Invalid status transition');

    const valid = await api()
      .put(`/api/v1/tournaments/${tournamentId}/status`)
      .set('Authorization', bearer(organizer.accessToken))
      .send({ status: TournamentStatus.REGISTRATION_OPEN })
      .expect(200);
    expect(valid.body.data.status).toBe(TournamentStatus.REGISTRATION_OPEN);
    expect((await Tournament.findById(tournamentId))?.status).toBe(
      TournamentStatus.REGISTRATION_OPEN
    );
  });

  it('registers, approves, and ranks real teams with duplicate and permission checks', async () => {
    const organizer = await registerAndVerify('registration-organizer');
    const teamOwner = await registerAndVerify('registration-team-owner');
    const outsider = await registerAndVerify('registration-outsider');
    const tournamentId = await openTournamentViaApi(
      organizer,
      `Registration Cup ${uniqueValue()}`
    );
    const team = await createTeamViaApi(teamOwner, `Registered Team ${uniqueValue()}`);

    const forbidden = await api()
      .post(`/api/v1/tournaments/${tournamentId}/teams`)
      .set('Authorization', bearer(outsider.accessToken))
      .send({ teamId: team._id })
      .expect(403);
    expect(forbidden.body.success).toBe(false);

    const registration = await registerTeamInTournament(teamOwner, tournamentId, team._id);
    expect(registration.status).toBe(TournamentTeamStatus.PENDING);
    expect(await TournamentTeam.countDocuments({ tournament: tournamentId })).toBe(1);

    await registerTeamInTournament(teamOwner, tournamentId, team._id).catch(() => undefined);
    const duplicate = await api()
      .post(`/api/v1/tournaments/${tournamentId}/teams`)
      .set('Authorization', bearer(teamOwner.accessToken))
      .send({ teamId: team._id })
      .expect(409);
    expect(duplicate.body.success).toBe(false);

    await api()
      .put(`/api/v1/tournaments/${tournamentId}/teams/${registration._id}/approve`)
      .set('Authorization', bearer(outsider.accessToken))
      .expect(403);

    const approved = await api()
      .put(`/api/v1/tournaments/${tournamentId}/teams/${registration._id}/approve`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(200);
    expect(approved.body.data.status).toBe(TournamentTeamStatus.APPROVED);

    const standings = await api()
      .get(`/api/v1/tournaments/${tournamentId}/standings`)
      .expect(200);
    expect(standings.body.data).toHaveLength(1);
    expect(standings.body.data[0]).toMatchObject({
      rank: 1,
      status: TournamentTeamStatus.APPROVED,
      points: 0,
    });

    const details = await api()
      .get(`/api/v1/tournaments/${tournamentId}`)
      .expect(200);
    expect(details.body.data.approvedTeamsCount).toBe(1);
  });

  it('generates fixtures once and returns the persisted schedule and stats', async () => {
    const organizer = await registerAndVerify('fixtures-organizer');
    const ownerA = await registerAndVerify('fixtures-owner-a');
    const ownerB = await registerAndVerify('fixtures-owner-b');
    const tournamentId = await openTournamentViaApi(
      organizer,
      `Fixture League ${uniqueValue()}`
    );
    const teamA = await createTeamViaApi(ownerA, `Fixture A ${uniqueValue()}`);
    const teamB = await createTeamViaApi(ownerB, `Fixture B ${uniqueValue()}`);

    const first = await registerTeamInTournament(ownerA, tournamentId, teamA._id);
    const second = await registerTeamInTournament(ownerB, tournamentId, teamB._id);
    await api()
      .put(`/api/v1/tournaments/${tournamentId}/teams/${first._id}/approve`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(200);
    await api()
      .put(`/api/v1/tournaments/${tournamentId}/teams/${second._id}/approve`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(200);

    const fixtures = await api()
      .post(`/api/v1/tournaments/${tournamentId}/fixtures`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(201);
    expect(fixtures.body.data).toHaveLength(1);
    expect(fixtures.body.data[0]).toMatchObject({
      teamA: teamA._id,
      teamB: teamB._id,
      status: MatchStatus.UPCOMING,
      format: MatchFormat.T20,
      totalOvers: 20,
    });
    expect(await Match.countDocuments({ tournament: tournamentId })).toBe(1);

    await api()
      .post(`/api/v1/tournaments/${tournamentId}/fixtures`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(409);

    const persistedFixtures = await api()
      .get(`/api/v1/tournaments/${tournamentId}/fixtures`)
      .expect(200);
    expect(persistedFixtures.body.data).toHaveLength(1);
    expect(persistedFixtures.body.data[0].teamA._id).toBe(teamA._id);

    const stats = await api()
      .get(`/api/v1/tournaments/${tournamentId}/stats`)
      .expect(200);
    expect(stats.body.data.summary).toMatchObject({
      totalMatches: 1,
      completedMatches: 0,
      totalRuns: 0,
      totalWickets: 0,
    });
  });

  it('deletes only DRAFT tournaments and cascades registrations and matches', async () => {
    const organizer = await registerAndVerify('tournament-delete');
    const teamOwner = await registerAndVerify('delete-team-owner');
    const tournamentId = await openTournamentViaApi(
      organizer,
      `Delete Cup ${uniqueValue()}`
    );
    const team = await createTeamViaApi(teamOwner, `Delete Cup Team ${uniqueValue()}`);
    await registerTeamInTournament(teamOwner, tournamentId, team._id);
    await Match.create({
      title: 'Cascade Match',
      tournament: new Types.ObjectId(tournamentId),
      teamA: team._id,
      teamB: team._id,
      format: MatchFormat.T20,
      totalOvers: 20,
      status: MatchStatus.UPCOMING,
    });

    await api()
      .delete(`/api/v1/tournaments/${tournamentId}`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(400);

    await api()
      .put(`/api/v1/tournaments/${tournamentId}/status`)
      .set('Authorization', bearer(organizer.accessToken))
      .send({ status: TournamentStatus.DRAFT })
      .expect(200);

    await api()
      .delete(`/api/v1/tournaments/${tournamentId}`)
      .set('Authorization', bearer(organizer.accessToken))
      .expect(200);

    expect(await Tournament.findById(tournamentId)).toBeNull();
    expect(await TournamentTeam.countDocuments({ tournament: tournamentId })).toBe(0);
    expect(await Match.countDocuments({ tournament: tournamentId })).toBe(0);
  });
});
