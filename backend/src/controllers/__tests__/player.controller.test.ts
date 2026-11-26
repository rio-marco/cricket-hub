import express, { NextFunction, Request, Response } from 'express';
import request from 'supertest';

jest.mock('../../services/player.service', () => ({
  __esModule: true,
  default: {
    createPlayer: jest.fn(),
    getPlayers: jest.fn(),
    searchPlayers: jest.fn(),
    getPlayerById: jest.fn(),
    updatePlayer: jest.fn(),
    deletePlayer: jest.fn(),
    getPlayerStats: jest.fn(),
    getPlayerTeams: jest.fn(),
    getPlayerMatches: jest.fn(),
  },
}));

import playerController from '../player.controller';
import playerService from '../../services/player.service';

const createApp = (): express.Express => {
  const app = express();
  app.use(express.json());
  app.use((req: Request, _res: Response, next: NextFunction) => {
    Object.assign(req, { user: { _id: 'user1' } });
    next();
  });

  app.post('/players', playerController.createPlayer);
  app.get('/players/search', playerController.searchPlayers);
  app.get('/players/:id/stats', playerController.getPlayerStats);
  app.get('/players/:id/teams', playerController.getPlayerTeams);
  app.get('/players/:id/matches', playerController.getPlayerMatches);

  return app;
};

describe('player controller', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('creates a player for the authenticated user', async () => {
    (playerService.createPlayer as jest.Mock).mockResolvedValue({ _id: 'p1' });

    const response = await request(createApp())
      .post('/players')
      .send({ playingRole: 'BATSMAN' });

    expect(response.status).toBe(201);
    expect(response.body.data).toEqual({ _id: 'p1' });
    expect(playerService.createPlayer).toHaveBeenCalledWith('user1', {
      playingRole: 'BATSMAN',
    });
  });

  it('returns paginated search results from the player service', async () => {
    (playerService.searchPlayers as jest.Mock).mockResolvedValue({
      data: [{ _id: 'p1' }],
      pagination: { page: 2, limit: 5, total: 7 },
    });

    const response = await request(createApp()).get(
      '/players/search?search=virat&page=2&limit=5'
    );

    expect(response.status).toBe(200);
    expect(response.body.data).toEqual([{ _id: 'p1' }]);
    expect(response.body.pagination).toEqual({
      page: 2,
      limit: 5,
      total: 7,
      totalPages: 2,
      hasNextPage: false,
      hasPrevPage: true,
    });
    expect(playerService.searchPlayers).toHaveBeenCalledWith(
      expect.objectContaining({ search: 'virat', page: '2', limit: '5' })
    );
  });

  it('returns player statistics, teams, and paginated matches', async () => {
    (playerService.getPlayerStats as jest.Mock).mockResolvedValue({ matches: 10 });
    (playerService.getPlayerTeams as jest.Mock).mockResolvedValue([{ _id: 't1' }]);
    (playerService.getPlayerMatches as jest.Mock).mockResolvedValue({
      data: [{ _id: 'm1' }],
      pagination: { page: 1, limit: 10, total: 1 },
    });

    const app = createApp();
    const stats = await request(app).get('/players/p1/stats');
    const teams = await request(app).get('/players/p1/teams');
    const matches = await request(app).get('/players/p1/matches?page=1&limit=10');

    expect(stats.status).toBe(200);
    expect(stats.body.data).toEqual({ matches: 10 });
    expect(teams.status).toBe(200);
    expect(teams.body.data).toEqual([{ _id: 't1' }]);
    expect(matches.status).toBe(200);
    expect(matches.body.pagination.totalPages).toBe(1);
    expect(playerService.getPlayerStats).toHaveBeenCalledWith('p1', {});
    expect(playerService.getPlayerTeams).toHaveBeenCalledWith('p1');
    expect(playerService.getPlayerMatches).toHaveBeenCalledWith(
      'p1',
      expect.objectContaining({ page: '1', limit: '10' })
    );
  });
});
