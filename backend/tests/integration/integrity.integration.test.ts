import mongoose, { Types } from 'mongoose';
import os from 'os';

import { connectDatabase } from '../../src/config/database';
import { BattingStyle, PlayingRole, TeamMemberRole, TeamMemberStatus } from '../../src/constants/enums';
import Innings from '../../src/models/Innings';
import Match from '../../src/models/Match';
import Player from '../../src/models/Player';
import Team from '../../src/models/Team';
import TeamMember from '../../src/models/TeamMember';
import User from '../../src/models/User';
import {
  api,
  createPlayerViaApi,
  createTeamViaApi,
  registerAndVerify,
  uniqueValue,
} from './helpers';

const hasUniqueIndex = async (collectionName: string, keys: string[]): Promise<boolean> => {
  const indexes = await mongoose.connection.db!.collection(collectionName).indexes();
  return indexes.some(
    (index: any) =>
      index.unique === true &&
      JSON.stringify(Object.keys(index.key)) === JSON.stringify(keys)
  );
};

describe('MongoDB integration: data integrity', () => {
  it('creates every expected unique index on the isolated database', async () => {
    const expectations: Array<[string, string[]]> = [
      ['users', ['email']],
      ['users', ['phone']],
      ['players', ['user']],
      ['teams', ['name']],
      ['teammembers', ['team', 'player']],
      ['tournamentteams', ['tournament', 'team']],
      ['innings', ['match', 'inningsNumber']],
      ['refreshtokens', ['token']],
    ];

    for (const [collection, keys] of expectations) {
      expect(await hasUniqueIndex(collection, keys)).toBe(true);
    }
  });

  it('rejects duplicate and malformed writes at the MongoDB schema/index level', async () => {
    const user = await registerAndVerify('integrity-user');
    const player = await createPlayerViaApi(user);

    const duplicatePlayer = await Player.create({
      user: new Types.ObjectId(user.userId),
      playingRole: PlayingRole.BOWLER,
      battingStyle: BattingStyle.LEFT_HAND,
    }).then(
      () => null,
      (error: any) => error
    );
    expect(duplicatePlayer?.code).toBe(11000);

    const team = await createTeamViaApi(user, `Integrity Team ${uniqueValue()}`);
    const memberData = {
      team: team._id,
      player: player._id,
      role: TeamMemberRole.PLAYER,
      status: TeamMemberStatus.ACTIVE,
      joinedAt: new Date(),
    };
    expect(await TeamMember.countDocuments({ team: team._id, player: player._id })).toBe(1);
    const duplicateMember = await TeamMember.create(memberData).then(
      () => null,
      (error: any) => error
    );
    expect(duplicateMember?.code).toBe(11000);

    await expect(new User({}).validate()).rejects.toMatchObject({
      errors: expect.objectContaining({ name: expect.anything(), password: expect.anything() }),
    });
    await expect(new Match({}).validate()).rejects.toMatchObject({
      errors: expect.objectContaining({ teamA: expect.anything(), teamB: expect.anything() }),
    });
    await expect(
      new Team({ name: `Bad Owner ${uniqueValue()}`, owner: 'not-an-object-id' }).validate()
    ).rejects.toBeDefined();
    await expect(
      new Innings({
        match: new Types.ObjectId(),
        inningsNumber: 1,
      }).validate()
    ).rejects.toBeDefined();
  });

  it('returns stable pagination metadata for persisted team documents', async () => {
    const prefix = `PG${uniqueValue().slice(-8)}`;
    const owner = await registerAndVerify('integrity-pagination');
    const created: string[] = [];
    for (let index = 0; index < 3; index += 1) {
      const team = await createTeamViaApi(owner, `${prefix} ${index}`);
      created.push(team._id);
    }

    const pageOne = await api()
      .get('/api/v1/teams')
      .query({ search: prefix, page: 1, limit: 2 })
      .expect(200);
    expect(pageOne.body.data).toHaveLength(2);
    expect(pageOne.body.pagination).toMatchObject({ page: 1, limit: 2, total: 3 });
    expect(created).toContain(pageOne.body.data[0]._id);

    const pageTwo = await api()
      .get('/api/v1/teams')
      .query({ search: prefix, page: 2, limit: 2 })
      .expect(200);
    expect(pageTwo.body.data).toHaveLength(1);
    expect(pageTwo.body.pagination).toMatchObject({ hasNextPage: false, hasPrevPage: true });
  });

  it('persists documents across a real MongoDB disconnect and reconnect', async () => {
    const owner = await registerAndVerify('integrity-reconnect');
    const team = await createTeamViaApi(owner, `Reconnect Team ${uniqueValue()}`);

    await mongoose.disconnect();
    expect(mongoose.connection.readyState).toBe(0);

    await connectDatabase({ runtimeAdapters: { os } } as any);
    expect(mongoose.connection.readyState).toBe(1);

    const stored = await Team.findById(team._id);
    expect(stored?.name).toBe(team.name);
    expect(stored?.owner.toString()).toBe(owner.userId);
    expect(await User.findById(owner.userId)).not.toBeNull();
  });
});
