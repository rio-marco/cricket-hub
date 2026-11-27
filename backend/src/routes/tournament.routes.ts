import { Router } from 'express';
import {
  createTournament,
  getTournaments,
  getTournamentById,
  updateTournament,
  deleteTournament,
  updateStatus,
  registerTeam,
  approveTeam,
  rejectTeam,
  getRegisteredTeams,
  generateFixtures,
  getFixtures,
  getPointsTable,
  getTournamentStats,
} from '../controllers/tournament.controller';
import { protect } from '../middlewares/auth.middleware';
import { apiLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import { idParamSchema, idTournamentTeamIdParamSchema } from '../validators/params.validator';
import {
  createTournamentSchema,
  updateTournamentSchema,
  registerTeamSchema,
  updateTournamentStatusSchema,
  tournamentQuerySchema,
} from '../validators/tournament.validator';

const router = Router();

// Public tournament routes
router.get('/', apiLimiter, validate(tournamentQuerySchema, 'query'), getTournaments);
router.get('/:id', validate(idParamSchema, 'params'), getTournamentById);
router.get('/:id/teams', validate(idParamSchema, 'params'), getRegisteredTeams);
router.get('/:id/fixtures', validate(idParamSchema, 'params'), getFixtures);
router.get('/:id/standings', validate(idParamSchema, 'params'), getPointsTable);
router.get('/:id/stats', validate(idParamSchema, 'params'), getTournamentStats);

// Protected tournament management routes
router.post('/', protect, validate(createTournamentSchema, 'body'), createTournament);
router.put('/:id', protect, validate(idParamSchema, 'params'), validate(updateTournamentSchema, 'body'), updateTournament);
router.delete('/:id', protect, validate(idParamSchema, 'params'), deleteTournament);
router.put('/:id/status', protect, validate(idParamSchema, 'params'), validate(updateTournamentStatusSchema, 'body'), updateStatus);

// Team registration and approval routes
router.post('/:id/teams', protect, validate(idParamSchema, 'params'), validate(registerTeamSchema, 'body'), registerTeam);
router.put('/:id/teams/:tournamentTeamId/approve', protect, validate(idTournamentTeamIdParamSchema, 'params'), approveTeam);
router.put('/:id/teams/:tournamentTeamId/reject', protect, validate(idTournamentTeamIdParamSchema, 'params'), rejectTeam);

// Tournament fixture generation
router.post('/:id/fixtures', protect, validate(idParamSchema, 'params'), generateFixtures);

export default router;
