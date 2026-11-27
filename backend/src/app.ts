import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import mongoose from 'mongoose';
import path from 'path';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { resolveCorsOrigins } from './config/cors';
import { swaggerSpec } from './config/swagger';
import routes from './routes';
import { apiLimiter } from './middlewares/rateLimiter.middleware';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware';
import { sanitizeRequest } from './middlewares/sanitize.middleware';
import { ApiResponse } from './utils/apiResponse';

const app: Application = express();
app.disable('x-powered-by');
if (env.TRUST_PROXY) {
  app.set('trust proxy', env.TRUST_PROXY);
}

// Security HTTP headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

// CORS configuration
const corsOrigins = resolveCorsOrigins();
const allowAllOrigins = corsOrigins === '*';
const corsOrigin = allowAllOrigins ? true : corsOrigins;
app.use(
  cors({
    origin: corsOrigin,
    credentials: !allowAllOrigins,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Idempotency-Key',
      'If-Match',
    ],
  })
);

// HTTP request logging
app.use(morgan(env.isProduction ? 'combined' : 'dev'));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(sanitizeRequest);

// Apply general API rate limiting to all /api endpoints
app.use('/api', apiLimiter);

// Serve static assets from uploads directory
const uploadPath = path.resolve(process.cwd(), env.UPLOAD_DIR || 'uploads');
app.use('/uploads', express.static(uploadPath));

// Swagger API Documentation (disabled by default in production)
if (env.ENABLE_API_DOCS) {
  app.use(
    '/api-docs',
    swaggerUi.serve,
    swaggerUi.setup(swaggerSpec, {
      customCss: '.swagger-ui .topbar { display: none }',
      customSiteTitle: 'Cricket Hub API Documentation',
    })
  );
}

// Basic health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  const dbReady = mongoose.connection.readyState === 1;
  const statusCode = dbReady ? 200 : 503;
  ApiResponse[dbReady ? 'success' : 'error'](res, statusCode, 'Cricket Hub Service health check', {
    status: dbReady ? 'UP' : 'DEGRADED',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    nodeEnv: env.NODE_ENV,
    database: {
      connected: dbReady,
      readyState: mongoose.connection.readyState,
    },
  });
});

// Mount application API v1 routes
app.use('/api/v1', routes);

// Fallback 404 Route Not Found handler
app.use(notFoundHandler);

// Centralized Global Error Handler
app.use(errorHandler);

export { app };
export default app;
