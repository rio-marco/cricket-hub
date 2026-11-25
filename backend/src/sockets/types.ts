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

export interface SocketAckError {
  code: string;
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

export type SocketAck = SocketRoomAck | { ok: false; error: SocketAckError };

export interface SocketUser {
  id: string;
  role: string;
  name: string;
  tokenExp?: number;
}

export interface SocketData {
  user?: SocketUser;
  matchRooms: Set<string>;
}

export type RealtimePayload = Record<string, unknown>;

export interface ClientToServerEvents {
  'match:join': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
  'match:leave': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
  'match:sync': (payload: { matchId: string }, ack?: (response: SocketAck) => void) => void;
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
}

export interface InterServerEvents {
  ping: () => void;
}
