import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { app } from './app';
import { env } from './config/env';
import { connectDatabase, disconnectDatabase } from './config/database';
import { logger } from './utils/logger';

// Create HTTP server instance
const server = http.createServer(app);

// Initialize Socket.IO instance for real-time live scoring and auctions
const corsOrigin = env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(',').map((o) => o.trim());

const io = new SocketIOServer(server, {
  cors: {
    origin: corsOrigin,
    methods: ['GET', 'POST'],
    credentials: true,
  },
  pingTimeout: 60000,
  pingInterval: 25000,
});

// Setup default Socket.IO connection handling
io.on('connection', (socket) => {
  logger.info(`[Socket.IO] Client connected: ${socket.id}`);

  socket.on('disconnect', (reason) => {
    logger.info(`[Socket.IO] Client disconnected: ${socket.id} (Reason: ${reason})`);
  });
});

/**
 * Start the HTTP server and database connections
 */
const startServer = async (): Promise<void> => {
  try {
    // Connect to MongoDB
    await connectDatabase();

    const PORT = env.PORT || 5000;

    server.listen(PORT, () => {
      logger.info(`==================================================`);
      logger.info(`🏏 Cricket Hub Server is running on port ${PORT}`);
      logger.info(`🌐 Environment: ${env.NODE_ENV}`);
      logger.info(`📖 API Docs: http://localhost:${PORT}/api-docs`);
      logger.info(`🏥 Health Check: http://localhost:${PORT}/health`);
      logger.info(`==================================================`);
    });
  } catch (error) {
    logger.error('Failed to start Cricket Hub server:', error);
    process.exit(1);
  }
};

/**
 * Graceful server shutdown handler
 */
const gracefulShutdown = async (signal: string): Promise<void> => {
  logger.info(`[Server] Received ${signal}. Initiating graceful shutdown...`);

  // Stop accepting new connections
  server.close(async () => {
    logger.info('[Server] HTTP and Socket.IO server closed.');

    try {
      // Disconnect from MongoDB
      await disconnectDatabase();
      logger.info('[Server] Graceful shutdown completed cleanly.');
      process.exit(0);
    } catch (err) {
      logger.error('[Server] Error during shutdown database disconnect:', err);
      process.exit(1);
    }
  });

  // Force close after 10s timeout
  setTimeout(() => {
    logger.error('[Server] Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

// Listen for process termination signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions and unhandled promise rejections
process.on('uncaughtException', (error: Error) => {
  logger.error(`[Server] Uncaught Exception: ${error.message}`, error.stack);
  process.exit(1);
});

process.on('unhandledRejection', (reason: any, promise: Promise<any>) => {
  logger.error('[Server] Unhandled Rejection at:', promise, 'reason:', reason);
});

// Boot server
if (process.env.NODE_ENV !== 'test') {
  startServer();
}

export { server, io };
export default server;
