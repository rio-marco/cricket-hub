import mongoose, { ConnectOptions } from 'mongoose';
import config from './env';
import { logger } from '../utils/logger';

const MAX_RETRIES = 5;
const RETRY_INTERVAL_MS = 5000;

let isConnecting = false;
let retryCount = 0;

/**
 * Connect to MongoDB with automatic retry mechanism
 */
export const connectDatabase = async (
  options: ConnectOptions = {}
): Promise<typeof mongoose> => {
  if (mongoose.connection.readyState === 1) {
    return mongoose;
  }

  if (isConnecting) {
    return mongoose;
  }

  isConnecting = true;

  const connectWithRetry = async (): Promise<typeof mongoose> => {
    try {
      const conn = await mongoose.connect(config.MONGODB_URI, {
        autoIndex: !config.isProduction, // Disable autoIndex in production for performance
        serverSelectionTimeoutMS: 5000,
        ...options,
      });

      retryCount = 0;
      isConnecting = false;
      return conn;
    } catch (err) {
      retryCount += 1;
      logger.error(`[Database] MongoDB connection error (Attempt ${retryCount}/${MAX_RETRIES})`, {
        message: err instanceof Error ? err.message : 'Unknown error',
      });

      if (retryCount >= MAX_RETRIES) {
        isConnecting = false;
        logger.error('[Database] Maximum retry attempts reached. Could not connect to MongoDB.');
        if (config.isProduction) {
          process.exit(1);
        }
        throw err;
      }

      logger.info(`[Database] Retrying connection in ${RETRY_INTERVAL_MS / 1000}s...`);
      await new Promise((resolve) => setTimeout(resolve, RETRY_INTERVAL_MS));
      return connectWithRetry();
    }
  };

  return connectWithRetry();
};

/**
 * Disconnect from MongoDB gracefully
 */
export const disconnectDatabase = async (): Promise<void> => {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
    logger.info('[Database] MongoDB disconnected cleanly.');
  }
};

// Setup connection event listeners
mongoose.connection.on('connected', () => {
  logger.info(`[Database] MongoDB connected to ${mongoose.connection.host}:${mongoose.connection.port}/${mongoose.connection.name}`);
});

mongoose.connection.on('error', (err) => {
  logger.error('[Database] MongoDB connection error encountered', {
    message: err instanceof Error ? err.message : 'Unknown error',
  });
});

mongoose.connection.on('disconnected', () => {
  logger.warn('[Database] MongoDB connection disconnected.');
});

mongoose.connection.on('reconnected', () => {
  logger.info('[Database] MongoDB connection re-established.');
});

export default connectDatabase;
