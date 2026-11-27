import { Types } from 'mongoose';
import { Server, Socket } from 'socket.io';
import Match from '../models/Match';
import matchService from '../services/match.service';
import scoringService from '../services/scoring.service';
import { logger } from '../utils/logger';
import { checkSocketRateLimit, clearSocketRateLimit } from './rateLimit';
import {
  MATCH_EVENTS,
  scorerRoom,
  viewerRoom,
} from './publisher';
import {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketAck,
  SocketAckError,
  SocketData,
} from './types';

type MatchSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

type MatchSocketServer = Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

const toError = (error: any): SocketAckError => ({
  code: error?.data?.code || error?.code || 'MATCH_ACCESS_DENIED',
  message: error?.message || 'Match access is not allowed.',
});

const stateVersion = (state: any): number => Number(state?.activeInnings?.stateVersion) || 0;

const resolveAccess = async (matchId: string, userId: string) => {
  if (!Types.ObjectId.isValid(matchId)) {
    throw { code: 'INVALID_MATCH_ID', message: 'Invalid match id.' };
  }
  const match = await Match.findById(matchId);
  if (!match) {
    throw { code: 'MATCH_NOT_FOUND', message: 'Match not found.' };
  }
  const access = await matchService.getMatchAccess(match, userId);
  if (!access.canView) {
    throw { code: 'MATCH_ACCESS_DENIED', message: 'You cannot access this match.' };
  }
  return access;
};

const respondError = (
  socket: MatchSocket,
  matchId: string,
  error: SocketAckError,
  ack?: (response: SocketAck) => void
): void => {
  socket.emit(MATCH_EVENTS.error, { matchId, error });
  ack?.({ ok: false, error });
};

const enforceSocketRateLimit = (
  socket: MatchSocket,
  event: string,
  matchId: string,
  ack?: (response: SocketAck) => void
): boolean => {
  const limit = checkSocketRateLimit(socket.id, { keyPrefix: `match:${event}`, windowMs: 60_000, max: 60 });
  if (limit.allowed) return true;
  respondError(
    socket,
    matchId,
    { code: 'RATE_LIMITED', message: `Too many ${event} requests. Retry after ${Math.ceil(limit.retryAfterMs / 1000)}s.` },
    ack
  );
  return false;
};

export const registerMatchHandlers = (io: MatchSocketServer): void => {

  io.on('connection', (socket) => {
    const user = socket.data.user;
    if (!user) {
      socket.disconnect(true);
      return;
    }

    logger.info(`[Socket.IO] Client connected: ${socket.id} (${user.id})`);
    socket.emit(MATCH_EVENTS.connectionStatus, {
      status: 'connected',
      connected: true,
      socketId: socket.id,
      at: new Date().toISOString(),
    });

    if (user.tokenExp) {
      const delay = user.tokenExp * 1000 - Date.now();
      if (delay > 0) {
        const timer = setTimeout(() => {
          socket.emit(MATCH_EVENTS.connectionStatus, {
            status: 'token_expired',
            connected: false,
            at: new Date().toISOString(),
          });
          socket.disconnect(true);
        }, delay);
        socket.on('disconnect', () => clearTimeout(timer));
      }
    }

    socket.on(MATCH_EVENTS.join, async (payload, ack) => {
      const matchId = String(payload?.matchId || '');
      if (!enforceSocketRateLimit(socket, MATCH_EVENTS.join, matchId, ack)) return;
      try {
        const access = await resolveAccess(matchId, user.id);
        await socket.join(viewerRoom(matchId));
        socket.data.matchRooms.add(viewerRoom(matchId));
        if (access.canScore) {
          await socket.join(scorerRoom(matchId));
          socket.data.matchRooms.add(scorerRoom(matchId));
        }
        const state = await scoringService.getState(matchId);
        ack?.({
          ok: true,
          matchId,
          room: viewerRoom(matchId),
          canScore: access.canScore,
          stateVersion: stateVersion(state),
          state,
        });
      } catch (error: any) {
        respondError(socket, matchId, toError(error), ack);
      }
    });

    socket.on(MATCH_EVENTS.leave, async (payload, ack) => {
      const matchId = String(payload?.matchId || '');
      await socket.leave(viewerRoom(matchId));
      await socket.leave(scorerRoom(matchId));
      socket.data.matchRooms.delete(viewerRoom(matchId));
      socket.data.matchRooms.delete(scorerRoom(matchId));
      ack?.({
        ok: true,
        matchId,
        room: viewerRoom(matchId),
        canScore: false,
        stateVersion: 0,
        state: null,
      });
    });

    socket.on(MATCH_EVENTS.sync, async (payload, ack) => {
      const matchId = String(payload?.matchId || '');
      if (!enforceSocketRateLimit(socket, MATCH_EVENTS.sync, matchId, ack)) return;
      try {
        const access = await resolveAccess(matchId, user.id);
        const state = await scoringService.getState(matchId);
        ack?.({
          ok: true,
          matchId,
          room: viewerRoom(matchId),
          canScore: access.canScore,
          stateVersion: stateVersion(state),
          state,
        });
      } catch (error: any) {
        respondError(socket, matchId, toError(error), ack);
      }
    });

    socket.on('disconnect', (reason) => {
      clearSocketRateLimit(socket.id);
      socket.data.matchRooms.clear();
      logger.info(`[Socket.IO] Client disconnected: ${socket.id} (${reason})`);
    });
  });
};
