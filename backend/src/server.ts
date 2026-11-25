import http from 'http';
import { app } from './app';
import { env } from './config/env';
import { configureSocketIO } from './config/socket';
import { connectDatabase, disconnectDatabase } from './config/database';
import { logger } from './utils/logger';

// Create HTTP server instance
const server = http.createServer(app);

const io = configureSocketIO(server);

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
