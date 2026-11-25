import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import scoringService from '../services/scoring.service';
import { publishScoringEvent } from '../sockets/publisher';
import { ScoringCommit } from '../sockets/types';

const respondWithState = (
  res: Response,
  status: number,
  message: string,
  result: any
): void => {
  const { commit, ...state } = result || {};
  if ((commit as ScoringCommit | undefined)?.committed) {
    publishScoringEvent(commit as ScoringCommit, state);
  }
  ApiResponse.success(res, status, message, state);
};

const currentUserId = (req: Request): string => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User is not authenticated.');
  }
  return userId;
};

const scoringInput = (req: Request): Record<string, unknown> => {
  const headerKey = req.header('Idempotency-Key');
  const ifMatch = req.header('If-Match')?.replace(/"/g, '');
  const body = (req.body || {}) as Record<string, unknown>;
  return {
    ...body,
    ...(headerKey && !body.idempotencyKey ? { idempotencyKey: headerKey } : {}),
    ...(ifMatch && body.expectedVersion === undefined
      ? { expectedVersion: Number(ifMatch) }
      : {}),
  };
};

export const getScoringState = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.getState(req.params.matchId as string, {
    inningsNumber: req.query.inningsNumber ? Number(req.query.inningsNumber) : undefined,
    limit: req.query.limit ? Number(req.query.limit) : undefined,
    order: req.query.order === 'asc' ? 'asc' : 'desc',
  });
  ApiResponse.success(res, 200, 'Live scoring state retrieved successfully.', state);
});

export const getScoringInnings = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const innings = await scoringService.getInnings(
    req.params.matchId as string,
    Number(req.params.inningsNumber)
  );
  ApiResponse.success(res, 200, 'Innings retrieved successfully.', innings);
});

export const getScoringCommentary = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const commentary = await scoringService.getCommentary(
    req.params.matchId as string,
    req.query.limit ? Number(req.query.limit) : 50,
    req.query.order === 'asc' ? 'asc' : 'desc'
  );
  ApiResponse.success(res, 200, 'Commentary retrieved successfully.', commentary);
});

export const startInnings = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.startInnings(
    req.params.matchId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 200, 'Innings started successfully.', state);
});

export const recordBall = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await scoringService.recordBall(
    req.params.matchId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 201, 'Delivery recorded successfully.', result);
});

export const undoBall = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.undo(
    req.params.matchId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 200, 'Delivery undone successfully.', state);
});

export const correctBall = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.correctBall(
    req.params.matchId as string,
    req.params.deliveryId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 200, 'Delivery corrected successfully.', state);
});

export const endInnings = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.endInnings(
    req.params.matchId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 200, 'Innings completed successfully.', state);
});

export const completeMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await scoringService.completeMatch(
    req.params.matchId as string,
    currentUserId(req),
    scoringInput(req) as never
  );
  respondWithState(res, 200, 'Match result recorded successfully.', state);
});

export default {
  getScoringState,
  getScoringInnings,
  getScoringCommentary,
  startInnings,
  recordBall,
  undoBall,
  correctBall,
  endInnings,
  completeMatch,
};
