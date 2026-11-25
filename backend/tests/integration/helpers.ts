import { Types } from 'mongoose';
import request from 'supertest';

import { app } from '../../src/app';
import { UserRole } from '../../src/constants/roles';
import {
  BattingStyle,
  PlayingRole,
  TeamMemberRole,
  TournamentFormat,
  TournamentStatus,
} from '../../src/constants/enums';
import Player from '../../src/models/Player';
import User from '../../src/models/User';

export const api = () => request(app);

export const uniqueValue = (): string =>
  `${Date.now()}${Math.floor(Math.random() * 1_000_000)}`;

export const bearer = (token: string): string => `Bearer ${token}`;

export interface TestUser {
  userId: string;
  name: string;
  email: string;
  password: string;
  accessToken: string;
  refreshToken: string;
}

export interface RegisterResult {
  userId: string;
  otp: string;
  email: string;
  password: string;
  name: string;
}

export const registerUser = async (prefix: string): Promise<RegisterResult> => {
  const name = `${prefix} ${uniqueValue()}`;
  const email = `${prefix}.${uniqueValue()}@example.com`;
  const password = 'StrongPass123!';

  const response = await api()
    .post('/api/v1/auth/register')
    .send({ name, email, password })
    .expect(201);

  expect(response.body.success).toBe(true);
  expect(response.body.data.user.isVerified).toBe(false);
  expect(response.body.data.tokens).toBeUndefined();
  expect(response.body.data.otp).toMatch(/^\d{6}$/);

  return {
    userId: response.body.data.userId,
    otp: response.body.data.otp,
    email,
    password,
    name,
  };
};

export const verifyRegisteredUser = async (
  registration: RegisterResult
): Promise<TestUser> => {
  const response = await api()
    .post('/api/v1/auth/verify-otp')
    .send({ userId: registration.userId, otp: registration.otp })
    .expect(200);

  expect(response.body.data.user.isVerified).toBe(true);
  expect(response.body.data.tokens.accessToken).toEqual(expect.any(String));
  expect(response.body.data.tokens.refreshToken).toEqual(expect.any(String));

  return {
    userId: registration.userId,
    name: registration.name,
    email: registration.email,
    password: registration.password,
    accessToken: response.body.data.tokens.accessToken,
    refreshToken: response.body.data.tokens.refreshToken,
  };
};

export const registerAndVerify = async (prefix: string): Promise<TestUser> =>
  verifyRegisteredUser(await registerUser(prefix));

export const createVerifiedUserInDb = async (
  prefix: string,
  role: UserRole = UserRole.PLAYER
): Promise<InstanceType<typeof User>> =>
  User.create({
    name: `${prefix} ${uniqueValue()}`,
    email: `${prefix}.${uniqueValue()}@example.com`,
    password: 'StrongPass123!',
    role,
    isVerified: true,
  });

export const createPlayerInDb = async (
  userId: Types.ObjectId | string,
  overrides: Record<string, any> = {}
) =>
  Player.create({
    user: new Types.ObjectId(userId.toString()),
    playingRole: PlayingRole.BATSMAN,
    battingStyle: BattingStyle.RIGHT_HAND,
    ...overrides,
  });

export const createPlayerViaApi = async (
  user: TestUser,
  overrides: Record<string, any> = {}
) => {
  const response = await api()
    .post('/api/v1/players')
    .set('Authorization', bearer(user.accessToken))
    .send({
      playingRole: PlayingRole.BATSMAN,
      battingStyle: BattingStyle.RIGHT_HAND,
      city: 'Test City',
      ...overrides,
    })
    .expect(201);
  return response.body.data;
};

export const createTeamViaApi = async (user: TestUser, name: string) => {
  const response = await api()
    .post('/api/v1/teams')
    .set('Authorization', bearer(user.accessToken))
    .send({ name, location: 'Test Ground', description: 'Integration test team' })
    .expect(201);
  return response.body.data;
};

export const createTournamentPayload = (name: string) => {
  const start = new Date();
  start.setUTCDate(start.getUTCDate() + 1);
  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 7);

  return {
    name,
    format: TournamentFormat.LEAGUE,
    ballType: 'WHITE',
    matchFormat: 'T20',
    venues: ['Test Ground'],
    city: 'Test City',
    startDate: start.toISOString(),
    endDate: end.toISOString(),
    registrationStartDate: new Date(Date.now() - 60_000).toISOString(),
    registrationEndDate: new Date(Date.now() + 86_400_000).toISOString(),
    maxTeams: 4,
    maxPlayersPerTeam: 15,
    registrationFee: 0,
  };
};

export const openTournamentViaApi = async (user: TestUser, name: string) => {
  const created = await api()
    .post('/api/v1/tournaments')
    .set('Authorization', bearer(user.accessToken))
    .send(createTournamentPayload(name))
    .expect(201);

  const tournamentId = created.body.data._id;
  await api()
    .put(`/api/v1/tournaments/${tournamentId}/status`)
    .set('Authorization', bearer(user.accessToken))
    .send({ status: TournamentStatus.REGISTRATION_OPEN })
    .expect(200);

  return tournamentId;
};

export const registerTeamInTournament = async (
  user: TestUser,
  tournamentId: string,
  teamId: string
) => {
  const response = await api()
    .post(`/api/v1/tournaments/${tournamentId}/teams`)
    .set('Authorization', bearer(user.accessToken))
    .send({ teamId })
    .expect(201);
  return response.body.data;
};

export const addMemberViaApi = async (
  owner: TestUser,
  teamId: string,
  playerId: string,
  role: TeamMemberRole = TeamMemberRole.PLAYER
) => {
  const response = await api()
    .post(`/api/v1/teams/${teamId}/members`)
    .set('Authorization', bearer(owner.accessToken))
    .send({ playerId, role })
    .expect(201);
  return response.body.data;
};
