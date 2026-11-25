import { Router, Request, Response } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import teamRoutes from './team.routes';
import playerRoutes from './player.routes';
import tournamentRoutes from './tournament.routes';
import matchRoutes from './match.routes';
import scoringRoutes from './scoring.routes';
import { ApiResponse } from '../utils/apiResponse';

const router = Router();

/**
 * Health check endpoint under API prefix
 * GET /api/v1/health
 */
router.get('/health', (_req: Request, res: Response) => {
  ApiResponse.success(res, 200, 'Cricket Hub API is operational and healthy', {
    status: 'UP',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Mount module routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/teams', teamRoutes);
router.use('/players', playerRoutes);
router.use('/tournaments', tournamentRoutes);
router.use('/matches', matchRoutes);
router.use('/scoring', scoringRoutes);

export default router;
