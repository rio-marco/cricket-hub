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
import { validate } from '../middlewares/validate.middleware';
import {
  createTeamSchema,
  updateTeamSchema,
  invitePlayerSchema,
  addPlayerSchema,
  respondInvitationSchema,
  updateMemberRoleSchema,
} from '../validators/team.validator';

const router = Router();

// Base team routes
router.post('/', protect, validate(createTeamSchema, 'body'), createTeam);
router.get('/', getTeams);

// Specific routes without dynamic :id placed first to avoid path collisions
router.get('/user/invitations', protect, getUserInvitations);
router.put('/invitations/:invitationId', protect, validate(respondInvitationSchema, 'body'), respondToInvitation);

// Dynamic team routes by ID
router.get('/:id', getTeamById);
router.put('/:id', protect, validate(updateTeamSchema, 'body'), updateTeam);
router.delete('/:id', protect, deleteTeam);

// Team membership routes
router.get('/:id/members', getTeamMembers);
router.post('/:id/members', protect, validate(addPlayerSchema, 'body'), addPlayer);
router.delete('/:id/members/:playerId', protect, removePlayer);
router.put('/:id/members/:memberId/role', protect, validate(updateMemberRoleSchema, 'body'), updateMemberRole);

// Team invitation & join request routes
router.post('/:id/invite', protect, validate(invitePlayerSchema, 'body'), invitePlayer);
router.post('/:id/join', protect, requestToJoin);
router.get('/:id/invitations', protect, getTeamInvitations);

// Statistics & matches
router.get('/:id/stats', getTeamStats);
router.get('/:id/matches', getTeamMatches);

export default router;
