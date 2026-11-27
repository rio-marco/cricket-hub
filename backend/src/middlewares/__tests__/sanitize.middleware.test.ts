import { sanitizeRequest } from '../sanitize.middleware';

const mockRes = {} as any;
const next = jest.fn();

describe('sanitizeRequest', () => {
  beforeEach(() => next.mockClear());

  it('strips Mongo operator keys and dotted keys from body, params, and query', () => {
    const req: any = {
      body: { name: 'ok', $where: 'bad', nested: { 'a.b': 1, $gt: 2, safe: true } },
      params: { id: '1', '$ne': 'x' },
      query: { search: 'hi', 'price[$gt]': '1', $regex: '.*' },
    };
    sanitizeRequest(req, mockRes, next);
    expect(req.body).toEqual({ name: 'ok', nested: { safe: true } });
    expect(req.params).toEqual({ id: '1' });
    expect(req.query.search).toBe('hi');
    expect(req.query.$regex).toBeUndefined();
    expect(next).toHaveBeenCalled();
  });

  it('preserves legitimate payloads', () => {
    const req: any = {
      body: { name: 'Team A', stats: { runs: 10 }, tags: ['a', 'b'] },
      params: { id: 'abc123' },
      query: { page: '1', limit: '10', search: 'hello world' },
    };
    sanitizeRequest(req, mockRes, next);
    expect(req.body).toEqual({ name: 'Team A', stats: { runs: 10 }, tags: ['a', 'b'] });
    expect(req.params).toEqual({ id: 'abc123' });
    expect(req.query).toEqual({ page: '1', limit: '10', search: 'hello world' });
  });
});
