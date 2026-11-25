import express, { ErrorRequestHandler, NextFunction, Request, Response } from 'express';
import request from 'supertest';
import { validate } from '../validate.middleware';
import { searchPlayerSchema } from '../../validators/player.validator';
import { ApiError } from '../../utils/apiError';

const createApp = (): express.Express => {
  const app = express();

  app.get('/', validate(searchPlayerSchema, 'query'), (req: Request, res: Response) => {
    res.json({ query: req.query });
  });

  const errorHandler: ErrorRequestHandler = (
    error: ApiError,
    _req: Request,
    res: Response,
    _next: NextFunction
  ) => {
    res.status(error.statusCode ?? 500).json({
      message: error.message,
      errors: error.errors,
    });
  };
  app.use(errorHandler);

  return app;
};

describe('validate middleware', () => {
  it('replaces read-only Express 5 query with sanitized and typecast values', async () => {
    const response = await request(createApp())
      .get('/?search=%20Virat%20&page=2&limit=5&unknown=value');

    expect(response.status).toBe(200);
    expect(response.body.query).toEqual({
      search: 'Virat',
      page: 2,
      limit: 5,
      sort: '-createdAt',
    });
    expect(response.body.query).not.toHaveProperty('unknown');
  });

  it('returns field-level validation errors for invalid query values', async () => {
    const response = await request(createApp()).get('/?playingRole=INVALID');

    expect(response.status).toBe(400);
    expect(response.body.message).toMatch(/Playing role/);
    expect(response.body.errors).toEqual(
      expect.arrayContaining([expect.objectContaining({ field: 'playingRole' })])
    );
  });
});
