import mongoose from 'mongoose';
import config from './env';

const MAX_RETRIES = 5;
const RETRY_INTERVAL_MS = 5000;

let isConnecting = false;
let retryCount = 0;

/**
 * Connect to MongoDB with automatic retry mechanism
 */
export const connectDatabase = async (): Promise<typeof mongoose> => {
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
      });

      retryCount = 0;
      isConnecting = false;
      return conn;
    } catch (err) {
      retryCount += 1;
      console.error(`[Database] MongoDB connection error (Attempt ${retryCount}/${MAX_RETRIES}):`, err);

      if (retryCount >= MAX_RETRIES) {
        isConnecting = false;
        console.error('[Database] Maximum retry attempts reached. Could not connect to MongoDB.');
        if (config.isProduction) {
          process.exit(1);
        }
        throw err;
      }

      console.info(`[Database] Retrying connection in ${RETRY_INTERVAL_MS / 1000}s...`);
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
    console.info('[Database] MongoDB disconnected cleanly.');
  }
};

// Setup connection event listeners
mongoose.connection.on('connected', () => {
  console.info(`[Database] MongoDB connected successfully to ${mongoose.connection.host}:${mongoose.connection.port}/${mongoose.connection.name}`);
});

mongoose.connection.on('error', (err) => {
  console.error('[Database] MongoDB connection error encountered:', err);
});

mongoose.connection.on('disconnected', () => {
  console.warn('[Database] MongoDB connection disconnected.');
});

mongoose.connection.on('reconnected', () => {
  console.info('[Database] MongoDB connection re-established.');
});

// Setup graceful shutdown handlers
const handleGracefulShutdown = async (signal: string): Promise<void> => {
  console.info(`[Database] Received ${signal}. Closing MongoDB connection...`);
  try {
    await disconnectDatabase();
    console.info('[Database] MongoDB connection closed due to app termination.');
    process.exit(0);
  } catch (error) {
    console.error('[Database] Error closing MongoDB connection during shutdown:', error);
    process.exit(1);
  }
};

process.on('SIGINT', () => handleGracefulShutdown('SIGINT'));
process.on('SIGTERM', () => handleGracefulShutdown('SIGTERM'));

export default connectDatabase;
