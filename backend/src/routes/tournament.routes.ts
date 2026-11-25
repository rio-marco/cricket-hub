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
import { validate } from '../middlewares/validate.middleware';
import {
  createTournamentSchema,
  updateTournamentSchema,
  registerTeamSchema,
  updateTournamentStatusSchema,
  tournamentQuerySchema,
} from '../validators/tournament.validator';

const router = Router();

// Public tournament routes
router.get('/', validate(tournamentQuerySchema, 'query'), getTournaments);
router.get('/:id', getTournamentById);
router.get('/:id/teams', getRegisteredTeams);
router.get('/:id/fixtures', getFixtures);
router.get('/:id/standings', getPointsTable);
router.get('/:id/stats', getTournamentStats);

// Protected tournament management routes
router.post('/', protect, validate(createTournamentSchema, 'body'), createTournament);
router.put('/:id', protect, validate(updateTournamentSchema, 'body'), updateTournament);
router.delete('/:id', protect, deleteTournament);
router.put('/:id/status', protect, validate(updateTournamentStatusSchema, 'body'), updateStatus);

// Team registration and approval routes
router.post('/:id/teams', protect, validate(registerTeamSchema, 'body'), registerTeam);
router.put('/:id/teams/:tournamentTeamId/approve', protect, approveTeam);
router.put('/:id/teams/:tournamentTeamId/reject', protect, rejectTeam);

// Tournament fixture generation
router.post('/:id/fixtures', protect, generateFixtures);

export default router;
