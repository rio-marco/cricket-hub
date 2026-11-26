import { Server } from 'socket.io';
import { AuctionAuditAction } from '../constants/enums';
import {
  AuctionCommit,
  ClientToServerEvents,
  InterServerEvents,
  RealtimePayload,
  ScoringCommit,
  ServerToClientEvents,
  SocketData,
} from './types';

export type MatchSocketServer = Server<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

export const MATCH_EVENTS = {
  connectionStatus: 'connection:status',
  error: 'match:error',
  state: 'match:state',
  delivery: 'score:delivery',
  wicket: 'wicket:recorded',
  corrected: 'score:corrected',
  undone: 'score:undone',
  overCompleted: 'match:over-completed',
  inningsStarted: 'match:innings-started',
  inningsEnded: 'match:innings-ended',
  matchCompleted: 'match:completed',
  join: 'match:join',
  leave: 'match:leave',
  sync: 'match:sync',
} as const;

export const viewerRoom = (matchId: string): string => `match:${matchId}`;
export const scorerRoom = (matchId: string): string => `match:${matchId}:scorers`;

let io: MatchSocketServer | null = null;
const publishedEvents = new Set<string>();
const MAX_PUBLISHED_EVENTS = 1000;

export const setSocketServer = (server: MatchSocketServer): void => {
  io = server;
};

export const getSocketServer = (): MatchSocketServer | null => io;

const idString = (value: unknown): string | undefined =>
  value === undefined || value === null ? undefined : String(value);

const deliveryPayload = (delivery: any): RealtimePayload => ({
  id: idString(delivery?._id ?? delivery?.id),
  sequenceNumber: delivery?.sequenceNumber,
  overNumber: delivery?.overNumber,
  ballNumber: delivery?.ballNumber,
  runs: delivery?.runs,
  extras: delivery?.extras,
  isLegal: delivery?.isLegal,
  isWicket: delivery?.isWicket,
  wicket: delivery?.wicket,
  isBoundary: delivery?.isBoundary,
  isSix: delivery?.isSix,
  commentary: delivery?.commentary,
});

const findDelivery = (state: any, deliveryId?: string): any => {
  if (!deliveryId) return undefined;
  return (state?.deliveries || []).find(
    (delivery: any) => idString(delivery?._id ?? delivery?.id) === String(deliveryId)
  );
};

const envelope = (commit: ScoringCommit): RealtimePayload => ({
  eventId: `${commit.matchId}:${commit.requestKey}:${commit.kind}`,
  matchId: commit.matchId,
  action: commit.kind,
  stateVersion: commit.stateVersion,
  inningsNumber: commit.inningsNumber,
  occurredAt: new Date().toISOString(),
  actorId: commit.actorId,
});

export const publishScoringEvent = (commit: ScoringCommit | undefined, state: any): void => {
  if (!io || !commit?.committed) return;

  const base = envelope(commit);
  const eventKey = String(base.eventId);
  if (publishedEvents.has(eventKey)) return;
  publishedEvents.add(eventKey);
  if (publishedEvents.size > MAX_PUBLISHED_EVENTS) {
    const oldest = publishedEvents.values().next().value as string | undefined;
    if (oldest) publishedEvents.delete(oldest);
  }

  const room = viewerRoom(commit.matchId);
  const emit = (event: keyof ServerToClientEvents, payload: RealtimePayload): void => {
    if (!io) return;
    const emitter = io.to(room) as unknown as { emit: (name: string, data: RealtimePayload) => void };
    emitter.emit(String(event), payload);
  };

  emit(MATCH_EVENTS.state, { ...base, state });

  const delivery = findDelivery(
    state,
    commit.kind === 'CORRECT' ? commit.correctedDeliveryId : commit.deliveryId
  );
  const matchCompleted =
    commit.kind === 'MATCH_COMPLETE' || state?.match?.status === 'COMPLETED';
  const inningsCompleted =
    commit.kind === 'INNINGS_END' ||
    Number(state?.match?.currentInnings) !== commit.inningsNumber;

  if (commit.kind === 'START_INNINGS') {
    emit(MATCH_EVENTS.inningsStarted, {
      ...base,
      innings: (state?.innings || []).find(
        (item: any) => Number(item?.inningsNumber) === commit.inningsNumber
      ),
    });
  }

  if (commit.kind === 'BALL') {
    emit(MATCH_EVENTS.delivery, {
      ...base,
      delivery: deliveryPayload(delivery),
      overCompleted: Boolean(commit.overCompleted),
      inningsCompleted,
      matchCompleted,
    });
  }

  if ((commit.kind === 'BALL' || commit.kind === 'CORRECT') && (commit.isWicket || delivery?.isWicket)) {
    emit(MATCH_EVENTS.wicket, { ...base, delivery: deliveryPayload(delivery) });
  }

  if (commit.kind === 'UNDO') {
    emit(MATCH_EVENTS.undone, {
      ...base,
      undoneDeliveryId: commit.undoneDeliveryId,
      delivery: deliveryPayload(delivery),
    });
  }

  if (commit.kind === 'CORRECT') {
    emit(MATCH_EVENTS.corrected, {
      ...base,
      correctedDeliveryId: commit.correctedDeliveryId,
      delivery: deliveryPayload(delivery),
    });
  }

  if (commit.overCompleted) {
    emit(MATCH_EVENTS.overCompleted, {
      ...base,
      overNumber: Number(delivery?.overNumber ?? 0) + 1,
      bowler: delivery?.bowler,
      commentary: delivery?.commentary,
    });
  }

  if (inningsCompleted) {
    emit(MATCH_EVENTS.inningsEnded, {
      ...base,
      inningsNumber: commit.inningsNumber,
      status: 'COMPLETED',
      nextInningsNumber: state?.match?.currentInnings,
    });
  }

  if (matchCompleted) {
    emit(MATCH_EVENTS.matchCompleted, {
      ...base,
      result: state?.result,
      matchStatus: state?.match?.status,
    });
  }
};

export const AUCTION_EVENTS = {
  state: 'auction:state',
  started: 'auction:started',
  playerChanged: 'auction:player_changed',
  bidPlaced: 'auction:bid_placed',
  bidRejected: 'auction:bid_rejected',
  playerSold: 'auction:player_sold',
  playerUnsold: 'auction:player_unsold',
  paused: 'auction:paused',
  resumed: 'auction:resumed',
  completed: 'auction:completed',
  error: 'auction:error',
  join: 'auction:join',
  leave: 'auction:leave',
  sync: 'auction:sync',
  bid: 'auction:bid',
} as const;

export const auctionRoom = (auctionId: string): string => `auction:${auctionId}`;
export const auctionControllerRoom = (auctionId: string): string => `auction:${auctionId}:controllers`;

const publishedAuctionEvents = new Set<string>();

const auctionEnvelope = (commit: AuctionCommit): RealtimePayload => ({
  eventId: `${commit.auctionId}:${commit.requestKey}:${commit.kind}`,
  auctionId: commit.auctionId,
  action: commit.kind,
  stateVersion: commit.stateVersion,
  occurredAt: new Date().toISOString(),
  actorId: commit.actorId,
});

const auctionEventFor = (commit: AuctionCommit): string | undefined => {
  const mapping: Partial<Record<AuctionAuditAction, string>> = {
    [AuctionAuditAction.START]: AUCTION_EVENTS.started,
    [AuctionAuditAction.FORWARD]: AUCTION_EVENTS.playerChanged,
    [AuctionAuditAction.NEXT_PLAYER]: AUCTION_EVENTS.playerChanged,
    [AuctionAuditAction.BID]: AUCTION_EVENTS.bidPlaced,
    [AuctionAuditAction.BID_DECISION]: AUCTION_EVENTS.bidRejected,
    [AuctionAuditAction.SOLD]: AUCTION_EVENTS.playerSold,
    [AuctionAuditAction.UNSOLD]: AUCTION_EVENTS.playerUnsold,
    [AuctionAuditAction.PAUSE]: AUCTION_EVENTS.paused,
    [AuctionAuditAction.RESUME]: AUCTION_EVENTS.resumed,
    [AuctionAuditAction.COMPLETE]: AUCTION_EVENTS.completed,
  };
  return mapping[commit.kind];
};

export const publishAuctionEvent = (commit: AuctionCommit | undefined, state: any): void => {
  if (!io || !commit?.committed) return;

  const base = auctionEnvelope(commit);
  const eventKey = String(base.eventId);
  if (publishedAuctionEvents.has(eventKey)) return;
  publishedAuctionEvents.add(eventKey);
  if (publishedAuctionEvents.size > MAX_PUBLISHED_EVENTS) {
    const oldest = publishedAuctionEvents.values().next().value as string | undefined;
    if (oldest) publishedAuctionEvents.delete(oldest);
  }

  const emit = (event: string, payload: RealtimePayload): void => {
    if (!io) return;
    const emitter = io.to(auctionRoom(commit.auctionId)) as unknown as {
      emit: (name: string, data: RealtimePayload) => void;
    };
    emitter.emit(event, payload);
  };

  const detail = {
    ...base,
    auctionPlayerId: commit.auctionPlayerId,
    bidId: commit.bidId,
    teamId: commit.teamId,
    amount: commit.amount,
    sequenceNumber: commit.sequenceNumber,
    decision: commit.decision,
    currentPlayer: state?.currentPlayer,
    teams: state?.teams,
  };

  emit(AUCTION_EVENTS.state, { ...base, state });
  const event = auctionEventFor(commit);
  if (event) emit(event, detail);
};
