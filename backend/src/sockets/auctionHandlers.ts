import { Types } from 'mongoose';
import { Server, Socket } from 'socket.io';
import Auction from '../models/Auction';
import auctionService from '../services/auction.service';
import { logger } from '../utils/logger';
import { checkSocketRateLimit, clearSocketRateLimit } from './rateLimit';
import {
  AUCTION_EVENTS,
  auctionControllerRoom,
  auctionRoom,
  publishAuctionEvent,
} from './publisher';
import {
  AuctionCommit,
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketAck,
  SocketAckError,
  SocketData,
} from './types';

type AuctionSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

type AuctionSocketServer = Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

const toError = (error: any): SocketAckError => ({
  code: error?.statusCode ?? error?.data?.code ?? error?.code ?? 'AUCTION_ACCESS_DENIED',
  message: error?.message || 'Auction action is not allowed.',
});

const stateVersion = (state: any): number => Number(state?.stateVersion) || 0;

const resolveAccess = async (auctionId: string, userId: string) => {
  if (!Types.ObjectId.isValid(auctionId)) {
    throw { code: 'INVALID_AUCTION_ID', message: 'Invalid auction id.' };
  }
  const auction = await Auction.findById(auctionId);
  if (!auction) {
    throw { code: 'AUCTION_NOT_FOUND', message: 'Auction not found.' };
  }
  return auctionService.getAuctionAccess(auction, userId);
};

const respondError = (
  socket: AuctionSocket,
  auctionId: string,
  error: SocketAckError,
  ack?: (response: SocketAck) => void
): void => {
  socket.emit(AUCTION_EVENTS.error, { auctionId, error });
  ack?.({ ok: false, error });
};

const enforceSocketRateLimit = (
  socket: AuctionSocket,
  event: string,
  auctionId: string,
  ack?: (response: SocketAck) => void,
  max = 60
): boolean => {
  const limit = checkSocketRateLimit(socket.id, { keyPrefix: `auction:${event}`, windowMs: 60_000, max });
  if (limit.allowed) return true;
  respondError(
    socket,
    auctionId,
    { code: 'RATE_LIMITED', message: `Too many ${event} requests. Retry after ${Math.ceil(limit.retryAfterMs / 1000)}s.` },
    ack
  );
  return false;
};

export const registerAuctionHandlers = (io: AuctionSocketServer): void => {

  io.on('connection', (socket) => {
    const user = socket.data.user;
    if (!user) {
      socket.disconnect(true);
      return;
    }

    socket.on(AUCTION_EVENTS.join, async (payload, ack) => {
      const auctionId = String(payload?.auctionId || '');
      if (!enforceSocketRateLimit(socket, AUCTION_EVENTS.join, auctionId, ack)) return;
      try {
        const access = await resolveAccess(auctionId, user.id);
        await socket.join(auctionRoom(auctionId));
        socket.data.auctionRooms.add(auctionRoom(auctionId));
        if (access.canManage) {
          await socket.join(auctionControllerRoom(auctionId));
          socket.data.auctionRooms.add(auctionControllerRoom(auctionId));
        }
        const state = await auctionService.getState(auctionId, user.id);
        ack?.({
          ok: true,
          auctionId,
          room: auctionRoom(auctionId),
          canBid: access.canBid,
          canManage: access.canManage,
          stateVersion: stateVersion(state),
          state,
        });
      } catch (error: any) {
        respondError(socket, auctionId, toError(error), ack);
      }
    });

    socket.on(AUCTION_EVENTS.leave, async (payload, ack) => {
      const auctionId = String(payload?.auctionId || '');
      await socket.leave(auctionRoom(auctionId));
      await socket.leave(auctionControllerRoom(auctionId));
      socket.data.auctionRooms.delete(auctionRoom(auctionId));
      socket.data.auctionRooms.delete(auctionControllerRoom(auctionId));
      ack?.({
        ok: true,
        auctionId,
        room: auctionRoom(auctionId),
        canBid: false,
        canManage: false,
        stateVersion: 0,
        state: null,
      });
    });

    socket.on(AUCTION_EVENTS.sync, async (payload, ack) => {
      const auctionId = String(payload?.auctionId || '');
      if (!enforceSocketRateLimit(socket, AUCTION_EVENTS.sync, auctionId, ack)) return;
      try {
        const access = await resolveAccess(auctionId, user.id);
        const state = await auctionService.getState(auctionId, user.id);
        ack?.({
          ok: true,
          auctionId,
          room: auctionRoom(auctionId),
          canBid: access.canBid,
          canManage: access.canManage,
          stateVersion: stateVersion(state),
          state,
        });
      } catch (error: any) {
        respondError(socket, auctionId, toError(error), ack);
      }
    });

    socket.on(AUCTION_EVENTS.bid, async (payload, ack) => {
      const auctionId = String(payload?.auctionId || '');
      if (!enforceSocketRateLimit(socket, AUCTION_EVENTS.bid, auctionId, ack, 20)) return;
      try {
        const result = await auctionService.placeBid(auctionId, user.id, {
          team: String(payload?.team || ''),
          amount: payload?.amount,
          expectedVersion: payload?.expectedVersion,
          idempotencyKey: payload?.idempotencyKey,
        });
        const { commit, ...state } = result;
        publishAuctionEvent(commit as AuctionCommit | undefined, state);
        ack?.({
          ok: true,
          auctionId,
          room: auctionRoom(auctionId),
          canBid: true,
          canManage: false,
          stateVersion: stateVersion(state),
          state,
        });
      } catch (error: any) {
        const normalized = toError(error);
        socket.emit(AUCTION_EVENTS.bidRejected, {
          auctionId,
          action: 'BID_REJECTED',
          occurredAt: new Date().toISOString(),
          actorId: user.id,
          error: normalized,
        });
        ack?.({ ok: false, error: normalized });
      }
    });

    socket.on('disconnect', (reason) => {
      clearSocketRateLimit(socket.id);
      socket.data.auctionRooms.clear();
      logger.info(`[Socket.IO] Auction client disconnected: ${socket.id} (${reason})`);
    });
  });
};
