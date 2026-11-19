import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import path from 'path';
import swaggerUi from 'swagger-ui-express';
import { env } from './config/env';
import { swaggerSpec } from './config/swagger';
import routes from './routes';
import { apiLimiter } from './middlewares/rateLimiter.middleware';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware';
import { ApiResponse } from './utils/apiResponse';

const app: Application = express();

// Security HTTP headers
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  })
);

// CORS configuration
const allowAllOrigins = env.CORS_ORIGIN === '*';
const corsOrigin = allowAllOrigins ? true : env.CORS_ORIGIN.split(',').map((o) => o.trim());
app.use(
  cors({
    origin: corsOrigin,
    credentials: !allowAllOrigins,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  })
);

// HTTP request logging
app.use(morgan(env.isProduction ? 'combined' : 'dev'));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Apply general API rate limiting to all /api endpoints
app.use('/api', apiLimiter);

// Serve static assets from uploads directory
const uploadPath = path.resolve(process.cwd(), env.UPLOAD_DIR || 'uploads');
app.use('/uploads', express.static(uploadPath));

// Swagger API Documentation
app.use(
  '/api-docs',
  swaggerUi.serve,
  swaggerUi.setup(swaggerSpec, {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'Cricket Hub API Documentation',
  })
);

// Basic health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  ApiResponse.success(res, 200, 'Cricket Hub Service is online', {
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    nodeEnv: env.NODE_ENV,
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
