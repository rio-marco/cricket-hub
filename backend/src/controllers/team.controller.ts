import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { MESSAGES } from '../constants/messages';
import { InvitationStatus } from '../constants/enums';
import teamService from '../services/team.service';

/**
 * Create a new team
 * POST /api/v1/teams
 */
export const createTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const team = await teamService.createTeam(req.user!._id, req.body);
  ApiResponse.success(
    res,
    201,
    MESSAGES.TEAM.CREATED || 'Team created successfully.',
    team
  );
});

/**
 * Get paginated list of teams
 * GET /api/v1/teams
 */
export const getTeams = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await teamService.getTeams(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.TEAM.FETCHED || 'Teams retrieved successfully.'
  );
});

/**
 * Get single team by ID
 * GET /api/v1/teams/:id
 */
export const getTeamById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const team = await teamService.getTeamById(req.params.id as string);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TEAM.FETCHED || 'Team retrieved successfully.',
    team
  );
});

/**
 * Update team details (Owner only)
 * PUT /api/v1/teams/:id
 */
export const updateTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const team = await teamService.updateTeam(req.params.id as string, req.user!._id, req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TEAM.UPDATED || 'Team details updated successfully.',
    team
  );
});

/**
 * Delete team (Owner only)
 * DELETE /api/v1/teams/:id
 */
export const deleteTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await teamService.deleteTeam(req.params.id as string, req.user!._id);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TEAM.DELETED || 'Team deleted successfully.',
    result
  );
});

/**
 * Get active team members
 * GET /api/v1/teams/:id/members
 */
export const getTeamMembers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const members = await teamService.getTeamMembers(req.params.id as string);
  ApiResponse.success(
    res,
    200,
    'Team members retrieved successfully.',
    members
  );
});

/**
 * Add a player directly to team roster (Owner only)
 * POST /api/v1/teams/:id/members
 */
export const addPlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const member = await teamService.addPlayer(
    req.params.id as string,
    req.user!._id,
    req.body.playerId,
    req.body.role
  );
  ApiResponse.success(
    res,
    201,
    MESSAGES.TEAM.MEMBER_ADDED || 'Player added to team successfully.',
    member
  );
});

/**
 * Remove a player from team roster (Owner only)
 * DELETE /api/v1/teams/:id/members/:playerId
 */
export const removePlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await teamService.removePlayer(
    req.params.id as string,
    req.user!._id,
    req.params.playerId as string
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.TEAM.MEMBER_REMOVED || 'Player removed from team successfully.',
    result
  );
});

/**
 * Invite a player to join team (Owner only)
 * POST /api/v1/teams/:id/invite
 */
export const invitePlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const invitation = await teamService.invitePlayer(
    req.params.id as string,
    req.user!._id,
    req.body.playerId,
    req.body.message
  );
  ApiResponse.success(
    res,
    201,
    MESSAGES.TEAM.INVITATION_SENT || 'Invitation sent successfully.',
    invitation
  );
});

/**
 * Request to join a team as a player
 * POST /api/v1/teams/:id/join
 */
export const requestToJoin = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const joinRequest = await teamService.requestToJoin(req.params.id as string, req.user!._id);
  ApiResponse.success(
    res,
    201,
    MESSAGES.TEAM.JOIN_REQUEST_SENT || 'Join request sent successfully.',
    joinRequest
  );
});

/**
 * Respond to an invitation or join request (Accept / Reject)
 * PUT /api/v1/teams/invitations/:invitationId
 */
export const respondToInvitation = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await teamService.respondToInvitation(
    req.params.invitationId as string,
    req.user!._id,
    req.body.status
  );
  const message =
    req.body.status === InvitationStatus.ACCEPTED
      ? MESSAGES.TEAM.INVITATION_ACCEPTED || 'Invitation accepted successfully.'
      : MESSAGES.TEAM.INVITATION_REJECTED || 'Invitation rejected successfully.';

  ApiResponse.success(res, 200, message, result);
});

/**
 * Get pending and past invitations for a team (Owner only)
 * GET /api/v1/teams/:id/invitations
 */
export const getTeamInvitations = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const invitations = await teamService.getTeamInvitations(req.params.id as string, req.user!._id);
  ApiResponse.success(
    res,
    200,
    'Team invitations retrieved successfully.',
    invitations
  );
});

/**
 * Get all invitations received by the current authenticated user
 * GET /api/v1/teams/user/invitations
 */
export const getUserInvitations = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const invitations = await teamService.getUserInvitations(req.user!._id);
  ApiResponse.success(
    res,
    200,
    'User invitations retrieved successfully.',
    invitations
  );
});

/**
 * Update member role (CAPTAIN, VICE_CAPTAIN, WICKETKEEPER, PLAYER)
 * PUT /api/v1/teams/:id/members/:memberId/role
 */
export const updateMemberRole = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const member = await teamService.updateMemberRole(
    req.params.id as string,
    req.user!._id,
    req.params.memberId as string,
    req.body.role
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.TEAM.MEMBER_ROLE_UPDATED || 'Team member role updated successfully.',
    member
  );
});

/**
 * Get team performance and statistics
 * GET /api/v1/teams/:id/stats
 */
export const getTeamStats = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const stats = await teamService.getTeamStats(req.params.id as string);
  ApiResponse.success(
    res,
    200,
    'Team statistics retrieved successfully.',
    stats
  );
});

/**
 * Get match history for a team
 * GET /api/v1/teams/:id/matches
 */
export const getTeamMatches = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await teamService.getTeamMatches(req.params.id as string, req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Team matches retrieved successfully.'
  );
});

export default {
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
};
