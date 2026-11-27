import { Router } from 'express';
import {
  createTeam,
  getTeams,
  getTeamById,
  updateTeam,
  deleteTeam,
  getTeamMembers,
  addPlayer,
  removePlayer,
  invitePlayer,
  requestToJoin,
  respondToInvitation,
  getTeamInvitations,
  getUserInvitations,
  updateMemberRole,
  getTeamStats,
  getTeamMatches,
} from '../controllers/team.controller';
import { protect } from '../middlewares/auth.middleware';
import { apiLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import { idParamSchema, idPlayerIdParamSchema, invitationIdParamSchema, idMemberIdParamSchema } from '../validators/params.validator';
import {
  createTeamSchema,
  updateTeamSchema,
  invitePlayerSchema,
  addPlayerSchema,
  respondInvitationSchema,
  updateMemberRoleSchema,
  teamQuerySchema,
} from '../validators/team.validator';

const router = Router();

// Base team routes
router.post('/', protect, validate(createTeamSchema, 'body'), createTeam);
router.get('/', apiLimiter, getTeams);

// Specific routes without dynamic :id placed first to avoid path collisions
router.get('/user/invitations', protect, getUserInvitations);
router.put('/invitations/:invitationId', protect, validate(invitationIdParamSchema, 'params'), validate(respondInvitationSchema, 'body'), respondToInvitation);

// Dynamic team routes by ID
router.get('/:id', validate(idParamSchema, 'params'), getTeamById);
router.put('/:id', protect, validate(idParamSchema, 'params'), validate(updateTeamSchema, 'body'), updateTeam);
router.delete('/:id', protect, validate(idParamSchema, 'params'), deleteTeam);

// Team membership routes
router.get('/:id/members', validate(idParamSchema, 'params'), getTeamMembers);
router.post('/:id/members', protect, validate(idParamSchema, 'params'), validate(addPlayerSchema, 'body'), addPlayer);
router.delete('/:id/members/:playerId', protect, validate(idPlayerIdParamSchema, 'params'), removePlayer);
router.put('/:id/members/:memberId/role', protect, validate(idMemberIdParamSchema, 'params'), validate(updateMemberRoleSchema, 'body'), updateMemberRole);

// Team invitation & join request routes
router.post('/:id/invite', protect, validate(idParamSchema, 'params'), validate(invitePlayerSchema, 'body'), invitePlayer);
router.post('/:id/join', protect, validate(idParamSchema, 'params'), requestToJoin);
router.get('/:id/invitations', protect, validate(idParamSchema, 'params'), getTeamInvitations);

// Statistics & matches
router.get('/:id/stats', validate(idParamSchema, 'params'), getTeamStats);
router.get('/:id/matches', validate(idParamSchema, 'params'), getTeamMatches);

export default router;
