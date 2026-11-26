import { AuctionBidDecision } from '../constants/enums';
import { AuctionAuditAction } from '../constants/enums';

export type ScoringCommitKind =
  | 'START_INNINGS'
  | 'BALL'
  | 'UNDO'
  | 'CORRECT'
  | 'INNINGS_END'
  | 'MATCH_COMPLETE';

export interface ScoringCommit {
  committed: true;
  matchId: string;
  kind: ScoringCommitKind;
  action: string;
  requestKey: string;
  stateVersion: number;
  inningsNumber: number;
  actorId: string;
  deliveryId?: string;
  correctedDeliveryId?: string;
  undoneDeliveryId?: string;
  overCompleted?: boolean;
  isWicket?: boolean;
}

export interface AuctionCommit {
  committed: true;
  auctionId: string;
  kind: AuctionAuditAction;
  action: string;
  requestKey: string;
  stateVersion: number;
  actorId: string;
  auctionPlayerId?: string;
  bidId?: string;
  teamId?: string;
  amount?: number;
  sequenceNumber?: number;
  decision?: AuctionBidDecision;
}

export interface SocketAckError {
  code: string | number;
  message: string;
}

export interface SocketRoomAck {
  ok: true;
  matchId: string;
  room: string;
  canScore: boolean;
  stateVersion: number;
  state: any;
}

export interface AuctionRoomAck {
  ok: true;
  auctionId: string;
  room: string;
  canBid: boolean;
  canManage: boolean;
  stateVersion: number;
  state: any;
}

export type SocketAck = SocketRoomAck | AuctionRoomAck | { ok: false; error: SocketAckError };

export interface SocketUser {
  id: string;
  role: string;
  name: string;
  tokenExp?: number;
}

export interface SocketData {
  user?: SocketUser;
  matchRooms: Set<string>;
  auctionRooms: Set<string>;
}

export type RealtimePayload = Record<string, unknown>;

export interface ClientToServerEvents {
  'match:join': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
  'match:leave': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
  'match:sync': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
  'auction:join': (payload: { auctionId: string }, ack?: (response: SocketAck) => void) => void;
  'auction:leave': (payload: { auctionId: string }, ack?: (response: SocketAck) => void) => void;
  'auction:sync': (payload: { auctionId: string }, ack?: (response: SocketAck) => void) => void;
  'auction:bid': (
    payload: { auctionId: string; team: string; amount?: number; expectedVersion?: number; idempotencyKey?: string },
    ack?: (response: SocketAck) => void
  ) => void;
}

export interface ServerToClientEvents {
  'connection:status': (payload: RealtimePayload) => void;
  'match:state': (payload: RealtimePayload) => void;
  'match:error': (payload: RealtimePayload) => void;
  'score:delivery': (payload: RealtimePayload) => void;
  'wicket:recorded': (payload: RealtimePayload) => void;
  'score:corrected': (payload: RealtimePayload) => void;
  'score:undone': (payload: RealtimePayload) => void;
  'match:over-completed': (payload: RealtimePayload) => void;
  'match:innings-started': (payload: RealtimePayload) => void;
  'match:innings-ended': (payload: RealtimePayload) => void;
  'match:completed': (payload: RealtimePayload) => void;
  'auction:state': (payload: RealtimePayload) => void;
  'auction:started': (payload: RealtimePayload) => void;
  'auction:player_changed': (payload: RealtimePayload) => void;
  'auction:bid_placed': (payload: RealtimePayload) => void;
  'auction:bid_rejected': (payload: RealtimePayload) => void;
  'auction:player_sold': (payload: RealtimePayload) => void;
  'auction:player_unsold': (payload: RealtimePayload) => void;
  'auction:paused': (payload: RealtimePayload) => void;
  'auction:resumed': (payload: RealtimePayload) => void;
  'auction:completed': (payload: RealtimePayload) => void;
  'auction:error': (payload: RealtimePayload) => void;
}

export interface InterServerEvents {
  ping: () => void;
}
