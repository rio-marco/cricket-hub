import express, { NextFunction, Request, Response } from 'express';
import request from 'supertest';

jest.mock('../../services/team.service', () => ({
  __esModule: true,
  default: {
    createTeam: jest.fn(),
    getTeams: jest.fn(),
    getTeamById: jest.fn(),
    updateTeam: jest.fn(),
    deleteTeam: jest.fn(),
    getTeamMembers: jest.fn(),
    addPlayer: jest.fn(),
    removePlayer: jest.fn(),
    invitePlayer: jest.fn(),
    requestToJoin: jest.fn(),
    respondToInvitation: jest.fn(),
    getTeamInvitations: jest.fn(),
    getUserInvitations: jest.fn(),
    updateMemberRole: jest.fn(),
    getTeamStats: jest.fn(),
    getTeamMatches: jest.fn(),
  },
}));

import teamController from '../team.controller';
import teamService from '../../services/team.service';

const createApp = (): express.Express => {
  const app = express();
  app.use(express.json());
  app.use((req: Request, _res: Response, next: NextFunction) => {
    Object.assign(req, { user: { _id: 'user1' } });
    next();
  });

  app.post('/teams', teamController.createTeam);
  app.get('/teams', teamController.getTeams);
  app.put('/teams/:id', teamController.updateTeam);
  app.get('/teams/:id/matches', teamController.getTeamMatches);

  return app;
};

describe('team controller', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates a team for the authenticated owner', async () => {
    (teamService.createTeam as jest.Mock).mockResolvedValue({ _id: 't1' });

    const response = await request(createApp())
      .post('/teams')
      .send({ name: 'Test XI' });

    expect(response.status).toBe(201);
    expect(response.body.data).toEqual({ _id: 't1' });
    expect(teamService.createTeam).toHaveBeenCalledWith('user1', { name: 'Test XI' });
  });

  it('returns paginated team results', async () => {
    (teamService.getTeams as jest.Mock).mockResolvedValue({
      data: [{ _id: 't1' }],
      pagination: { page: 1, limit: 10, total: 1 },
    });

    const response = await request(createApp()).get('/teams?page=1&limit=10');

    expect(response.status).toBe(200);
    expect(response.body.data).toEqual([{ _id: 't1' }]);
    expect(response.body.pagination).toEqual({
      page: 1,
      limit: 10,
      total: 1,
      totalPages: 1,
      hasNextPage: false,
      hasPrevPage: false,
    });
    expect(teamService.getTeams).toHaveBeenCalledWith(
      expect.objectContaining({ page: '1', limit: '10' })
    );
  });

  it('passes owner id when updating a team', async () => {
    (teamService.updateTeam as jest.Mock).mockResolvedValue({ _id: 't1', name: 'Updated XI' });

    const response = await request(createApp())
      .put('/teams/t1')
      .send({ name: 'Updated XI' });

    expect(response.status).toBe(200);
    expect(response.body.data.name).toBe('Updated XI');
    expect(teamService.updateTeam).toHaveBeenCalledWith('t1', 'user1', {
      name: 'Updated XI',
    });
  });

  it('returns paginated team match history', async () => {
    (teamService.getTeamMatches as jest.Mock).mockResolvedValue({
      data: [{ _id: 'm1' }],
      pagination: { page: 1, limit: 10, total: 3 },
    });

    const response = await request(createApp()).get('/teams/t1/matches?page=1&limit=10');

    expect(response.status).toBe(200);
    expect(response.body.pagination).toMatchObject({ total: 3, totalPages: 1 });
    expect(teamService.getTeamMatches).toHaveBeenCalledWith(
      't1',
      expect.objectContaining({ page: '1', limit: '10' })
    );
  });
});
