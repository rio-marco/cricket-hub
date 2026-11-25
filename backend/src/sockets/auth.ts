import jwt from 'jsonwebtoken';
import { Socket } from 'socket.io';
import { env } from '../config/env';
import { IJwtPayload } from '../middlewares/auth.middleware';
import User from '../models/User';
import {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
  SocketData,
} from './types';

type AuthenticatedSocket = Socket<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

const reject = (
  next: (error?: Error) => void,
  code: string,
  message: string
): void => {
  const error = new Error(message) as Error & { data: { code: string; message: string } };
  error.data = { code, message };
  next(error);
};

const extractToken = (socket: AuthenticatedSocket): string | undefined => {
  const authToken = socket.handshake.auth?.token;
  if (typeof authToken === 'string' && authToken.trim()) {
    return authToken.trim();
  }

  const authorization = socket.handshake.headers.authorization;
  if (authorization && authorization.startsWith('Bearer ')) {
    return authorization.slice(7).trim();
  }

  const queryToken = socket.handshake.query.token;
  if (typeof queryToken === 'string' && queryToken.trim()) {
    return queryToken.trim();
  }

  return undefined;
};

export const socketAuth = async (
  socket: AuthenticatedSocket,
  next: (error?: Error) => void
): Promise<void> => {
  const token = extractToken(socket);
  if (!token) {
    reject(next, 'UNAUTHENTICATED', 'Authentication token is required.');
    return;
  }

  let decoded: IJwtPayload;
  try {
    decoded = jwt.verify(token, env.JWT_SECRET) as IJwtPayload;
  } catch (error: any) {
    if (error?.name === 'TokenExpiredError') {
      reject(next, 'TOKEN_EXPIRED', 'Authentication token has expired.');
      return;
    }
    reject(next, 'INVALID_TOKEN', 'Invalid authentication token.');
    return;
  }

  const userId = decoded.id || decoded.userId || decoded.sub;
  if (!userId) {
    reject(next, 'INVALID_TOKEN', 'Authentication token has no user id.');
    return;
  }

  const user = await User.findById(userId).select('name role isVerified isBlocked');
  if (!user) {
    reject(next, 'USER_NOT_FOUND', 'User belonging to this token no longer exists.');
    return;
  }
  if (user.isBlocked) {
    reject(next, 'ACCOUNT_BLOCKED', 'Your account has been suspended.');
    return;
  }
  if (!user.isVerified) {
    reject(next, 'VERIFICATION_REQUIRED', 'Please verify your account first.');
    return;
  }

  socket.data.user = {
    id: String(user._id),
    role: String(user.role),
    name: String(user.name || ''),
    tokenExp: decoded.exp,
  };
  socket.data.matchRooms = new Set<string>();
  next();
};
