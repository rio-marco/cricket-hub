import mongoose, { Types } from 'mongoose';
import Team, { ITeam } from '../models/Team';
import TeamMember from '../models/TeamMember';
import TeamInvitation from '../models/TeamInvitation';
import Player from '../models/Player';
import User from '../models/User';
import Match from '../models/Match';
import Innings from '../models/Innings';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import {
  TeamMemberRole,
  TeamMemberStatus,
  InvitationType,
  InvitationStatus,
  MatchStatus,
  ResultType,
  NotificationCategory,
  NotificationType,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import { getPaginationParams, IPaginationMeta, buildPaginationResponse } from '../utils/pagination';
import { notifySafely } from './notificationHooks.service';

export interface ICreateTeamData {
  name: string;
  description?: string;
  location?: string;
  logo?: string;
}

export interface IUpdateTeamData {
  name?: string;
  description?: string;
  location?: string;
  logo?: string;
  captain?: string | null;
  viceCaptain?: string | null;
  wicketkeeper?: string | null;
  isActive?: boolean;
}

export interface IPaginatedResult<T> {
  data: T[];
  pagination: IPaginationMeta;
}

export class TeamService {
  /**
   * Create a new team, assign user as owner, and enroll owner if player profile exists
   */
  public async createTeam(
    userId: string | Types.ObjectId,
    data: ICreateTeamData
  ): Promise<ITeam> {
    const trimmedName = data.name.trim();

    // Check for duplicate team name (case-insensitive)
    const existingTeam = await Team.findOne({
      name: { $regex: new RegExp(`^${trimmedName}$`, 'i') },
    });
    if (existingTeam) {
      throw ApiError.conflict(MESSAGES.TEAM.NAME_TAKEN || 'A team with this name already exists.');
    }

    const team = await Team.create({
      name: trimmedName,
      description: data.description?.trim(),
      location: data.location?.trim(),
      logo: data.logo?.trim() || '',
      owner: new Types.ObjectId(userId.toString()),
      isActive: true,
    });

    // Update user role to TEAM_OWNER if currently NORMAL_USER
    const user = await User.findById(userId);
    if (user && user.role === UserRole.NORMAL_USER) {
      user.role = UserRole.TEAM_OWNER;
      await user.save();
    }

    // If owner already has a Player profile, automatically enroll them as Captain
    const ownerPlayer = await Player.findOne({ user: userId });
    if (ownerPlayer) {
      await TeamMember.create({
        team: team._id,
        player: ownerPlayer._id,
        role: TeamMemberRole.CAPTAIN,
        status: TeamMemberStatus.ACTIVE,
        joinedAt: new Date(),
      });

      team.captain = ownerPlayer._id;
      await team.save();
    }

    const populatedTeam = await Team.findById(team._id)
      .populate('owner', 'name email phone avatar role')
      .populate({
        path: 'captain',
        populate: { path: 'user', select: 'name avatar' },
      })
      .lean();

    return populatedTeam as unknown as ITeam;
  }

  /**
   * Get paginated list of teams with optional search and location filters
   */
  public async getTeams(
    query: Record<string, any> = {}
  ): Promise<IPaginatedResult<ITeam>> {
    const { page, limit, skip, sort } = getPaginationParams(query, 10, 100, '-createdAt');

    const filter: Record<string, any> = {};

    // Filter active teams by default unless explicit
    if (query.isActive !== undefined) {
      filter.isActive = query.isActive === 'true' || query.isActive === true;
    } else {
      filter.isActive = true;
    }

    // Text search on name or location
    if (query.search) {
      const searchRegex = new RegExp(String(query.search).trim(), 'i');
      filter.$or = [{ name: searchRegex }, { location: searchRegex }];
    }

    // Exact or partial location filter
    if (query.location) {
      filter.location = new RegExp(String(query.location).trim(), 'i');
    }

    if (query.owner && mongoose.Types.ObjectId.isValid(query.owner)) {
      filter.owner = new Types.ObjectId(String(query.owner));
    }

    const [teams, total] = await Promise.all([
      Team.find(filter)
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .populate('owner', 'name email phone avatar')
        .populate({
          path: 'captain',
          populate: { path: 'user', select: 'name avatar' },
        })
        .populate({
          path: 'viceCaptain',
          populate: { path: 'user', select: 'name avatar' },
        })
        .populate({
          path: 'wicketkeeper',
          populate: { path: 'user', select: 'name avatar' },
        })
        .lean(),
      Team.countDocuments(filter),
    ]);

    return {
      data: teams as unknown as ITeam[],
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  /**
   * Get single team by ID with owner, leadership, and active roster members
   */
  public async getTeamById(id: string | Types.ObjectId): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(id.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(id)
      .populate('owner', 'name email phone avatar role')
      .populate({
        path: 'captain',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .populate({
        path: 'viceCaptain',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .populate({
        path: 'wicketkeeper',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .lean();

    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    // Retrieve active roster members with full player and user data
    const members = await TeamMember.find({
      team: id,
      status: TeamMemberStatus.ACTIVE,
    })
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .sort({ role: 1, joinedAt: 1 })
      .lean();

    return {
      ...team,
      members,
      memberCount: members.length,
    };
  }

  /**
   * Update team details. Only the team owner or admin is authorized.
   */
  public async updateTeam(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    data: IUpdateTeamData
  ): Promise<ITeam> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    // Owner authorization
    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can perform this operation.');
    }

    // Check name uniqueness if name is being changed
    if (data.name && data.name.trim().toLowerCase() !== team.name.toLowerCase()) {
      const trimmedName = data.name.trim();
      const nameConflict = await Team.findOne({
        name: { $regex: new RegExp(`^${trimmedName}$`, 'i') },
        _id: { $ne: team._id },
      });
      if (nameConflict) {
        throw ApiError.conflict(MESSAGES.TEAM.NAME_TAKEN || 'A team with this name already exists.');
      }
      team.name = trimmedName;
    }

    if (data.description !== undefined) team.description = data.description.trim();
    if (data.location !== undefined) team.location = data.location.trim();
    if (data.logo !== undefined) team.logo = data.logo.trim();
    if (data.isActive !== undefined) team.isActive = Boolean(data.isActive);

    // Validate and update captain
    if (data.captain !== undefined) {
      if (data.captain) {
        const member = await TeamMember.findOne({
          team: teamId,
          player: data.captain,
          status: TeamMemberStatus.ACTIVE,
        });
        if (!member) {
          throw ApiError.badRequest('Captain must be an active member of this team.');
        }
        // Demote previous captain in roster if present
        await TeamMember.updateMany(
          { team: teamId, role: TeamMemberRole.CAPTAIN, player: { $ne: data.captain } },
          { role: TeamMemberRole.PLAYER }
        );
        member.role = TeamMemberRole.CAPTAIN;
        await member.save();
        team.captain = new Types.ObjectId(data.captain);
      } else {
        if (team.captain) {
          await TeamMember.updateOne(
            { team: teamId, player: team.captain, role: TeamMemberRole.CAPTAIN },
            { role: TeamMemberRole.PLAYER }
          );
        }
        team.captain = undefined;
      }
    }

    // Validate and update vice captain
    if (data.viceCaptain !== undefined) {
      if (data.viceCaptain) {
        const member = await TeamMember.findOne({
          team: teamId,
          player: data.viceCaptain,
          status: TeamMemberStatus.ACTIVE,
        });
        if (!member) {
          throw ApiError.badRequest('Vice captain must be an active member of this team.');
        }
        await TeamMember.updateMany(
          { team: teamId, role: TeamMemberRole.VICE_CAPTAIN, player: { $ne: data.viceCaptain } },
          { role: TeamMemberRole.PLAYER }
        );
        member.role = TeamMemberRole.VICE_CAPTAIN;
        await member.save();
        team.viceCaptain = new Types.ObjectId(data.viceCaptain);
      } else {
        if (team.viceCaptain) {
          await TeamMember.updateOne(
            { team: teamId, player: team.viceCaptain, role: TeamMemberRole.VICE_CAPTAIN },
            { role: TeamMemberRole.PLAYER }
          );
        }
        team.viceCaptain = undefined;
      }
    }

    // Validate and update wicketkeeper
    if (data.wicketkeeper !== undefined) {
      if (data.wicketkeeper) {
        const member = await TeamMember.findOne({
          team: teamId,
          player: data.wicketkeeper,
          status: TeamMemberStatus.ACTIVE,
        });
        if (!member) {
          throw ApiError.badRequest('Wicketkeeper must be an active member of this team.');
        }
        member.role = TeamMemberRole.WICKETKEEPER;
        await member.save();
        team.wicketkeeper = new Types.ObjectId(data.wicketkeeper);
      } else {
        team.wicketkeeper = undefined;
      }
    }

    await team.save();

    const updated = await Team.findById(team._id)
      .populate('owner', 'name email phone avatar')
      .populate({
        path: 'captain',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'viceCaptain',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'wicketkeeper',
        populate: { path: 'user', select: 'name avatar' },
      })
      .lean();

    return updated as unknown as ITeam;
  }

  /**
   * Delete team and purge associated roster memberships and invitations
   */
  public async deleteTeam(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId
  ): Promise<{ teamId: string; deleted: boolean }> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can perform this operation.');
    }

    // Remove all team members and invitations
    await Promise.all([
      TeamMember.deleteMany({ team: team._id }),
      TeamInvitation.deleteMany({ team: team._id }),
      team.deleteOne(),
    ]);

    return {
      teamId: team._id.toString(),
      deleted: true,
    };
  }

  /**
   * Add a player directly to a team (Owner action)
   */
  public async addPlayer(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    playerId: string | Types.ObjectId,
    role: TeamMemberRole = TeamMemberRole.PLAYER
  ): Promise<any> {
    if (
      !mongoose.Types.ObjectId.isValid(teamId.toString()) ||
      !mongoose.Types.ObjectId.isValid(playerId.toString())
    ) {
      throw ApiError.badRequest('Invalid ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can perform this operation.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    const existingMember = await TeamMember.findOne({
      team: teamId,
      player: playerId,
    });

    if (existingMember) {
      if (existingMember.status === TeamMemberStatus.ACTIVE) {
        throw ApiError.conflict(MESSAGES.TEAM.ALREADY_MEMBER || 'Player is already a member of this team.');
      }
      existingMember.status = TeamMemberStatus.ACTIVE;
      existingMember.role = role || TeamMemberRole.PLAYER;
      existingMember.joinedAt = new Date();
      await existingMember.save();

      return TeamMember.findById(existingMember._id)
        .populate({
          path: 'player',
          populate: { path: 'user', select: 'name email phone avatar' },
        })
        .lean();
    }

    const newMember = await TeamMember.create({
      team: team._id,
      player: player._id,
      role: role || TeamMemberRole.PLAYER,
      status: TeamMemberStatus.ACTIVE,
      joinedAt: new Date(),
    });

    return TeamMember.findById(newMember._id)
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .lean();
  }

  /**
   * Remove a player from the team roster (Owner action)
   */
  public async removePlayer(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    playerId: string | Types.ObjectId
  ): Promise<{ teamId: string; playerId: string; removed: boolean }> {
    if (
      !mongoose.Types.ObjectId.isValid(teamId.toString()) ||
      !mongoose.Types.ObjectId.isValid(playerId.toString())
    ) {
      throw ApiError.badRequest('Invalid ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can perform this operation.');
    }

    const member = await TeamMember.findOne({
      team: teamId,
      player: playerId,
      status: TeamMemberStatus.ACTIVE,
    });

    if (!member) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_MEMBER || 'Player is not an active member of this team.');
    }

    // Delete membership record
    await TeamMember.deleteOne({ _id: member._id });

    // Clean up team leadership positions if occupied by the removed player
    let teamModified = false;
    if (team.captain && team.captain.toString() === playerId.toString()) {
      team.captain = undefined;
      teamModified = true;
    }
    if (team.viceCaptain && team.viceCaptain.toString() === playerId.toString()) {
      team.viceCaptain = undefined;
      teamModified = true;
    }
    if (team.wicketkeeper && team.wicketkeeper.toString() === playerId.toString()) {
      team.wicketkeeper = undefined;
      teamModified = true;
    }
    if (teamModified) {
      await team.save();
    }

    return {
      teamId: team._id.toString(),
      playerId: playerId.toString(),
      removed: true,
    };
  }

  /**
   * Retrieve all active members for a given team
   */
  public async getTeamMembers(teamId: string | Types.ObjectId): Promise<any[]> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    return TeamMember.find({
      team: teamId,
      status: TeamMemberStatus.ACTIVE,
    })
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .sort({ role: 1, joinedAt: 1 })
      .lean();
  }

  /**
   * Send an invitation from a team owner to a player
   */
  public async invitePlayer(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    playerId: string | Types.ObjectId,
    message?: string
  ): Promise<any> {
    if (
      !mongoose.Types.ObjectId.isValid(teamId.toString()) ||
      !mongoose.Types.ObjectId.isValid(playerId.toString())
    ) {
      throw ApiError.badRequest('Invalid ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can send invitations.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    // Check if player is already an active member
    const existingMember = await TeamMember.findOne({
      team: teamId,
      player: playerId,
      status: TeamMemberStatus.ACTIVE,
    });
    if (existingMember) {
      throw ApiError.conflict(MESSAGES.TEAM.ALREADY_MEMBER || 'Player is already a member of this team.');
    }

    // Check if a pending invitation or request already exists
    const pendingInvitation = await TeamInvitation.findOne({
      team: teamId,
      player: playerId,
      status: InvitationStatus.PENDING,
    });
    if (pendingInvitation) {
      throw ApiError.conflict('An invitation or join request is already pending for this player.');
    }

    const invitation = await TeamInvitation.create({
      team: team._id,
      player: player._id,
      user: player.user,
      invitedBy: new Types.ObjectId(userId.toString()),
      type: InvitationType.INVITE,
      status: InvitationStatus.PENDING,
      message: message?.trim() || '',
    });

    await notifySafely([player.user], {
      type: NotificationType.TEAM_INVITATION,
      category: NotificationCategory.TEAM,
      title: 'Team invitation',
      body: `${team.name} invited you to join the team${message?.trim() ? `: ${message.trim()}` : '.'}`,
      data: { teamId: String(team._id), invitationId: String(invitation._id), playerId: String(player._id) },
      relatedEntityType: 'TeamInvitation',
      relatedEntityId: String(invitation._id),
      dedupeKey: `team-invitation:${invitation._id}`,
    });

    return TeamInvitation.findById(invitation._id)
      .populate('team', 'name logo location')
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email avatar' },
      })
      .populate('invitedBy', 'name email avatar')
      .lean();
  }

  /**
   * Request to join a team as an authenticated player
   */
  public async requestToJoin(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId
  ): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() === userId.toString()) {
      throw ApiError.badRequest('You are the owner of this team.');
    }

    const player = await Player.findOne({ user: userId });
    if (!player) {
      throw ApiError.badRequest('You must create a player profile before requesting to join a team.');
    }

    // Check if player is already an active member
    const existingMember = await TeamMember.findOne({
      team: teamId,
      player: player._id,
      status: TeamMemberStatus.ACTIVE,
    });
    if (existingMember) {
      throw ApiError.conflict(MESSAGES.TEAM.ALREADY_MEMBER || 'You are already a member of this team.');
    }

    // Check for pending join request
    const pendingRequest = await TeamInvitation.findOne({
      team: teamId,
      player: player._id,
      status: InvitationStatus.PENDING,
    });
    if (pendingRequest) {
      throw ApiError.conflict('A request or invitation is already pending for this team.');
    }

    const joinRequest = await TeamInvitation.create({
      team: team._id,
      player: player._id,
      user: new Types.ObjectId(userId.toString()),
      invitedBy: new Types.ObjectId(userId.toString()),
      type: InvitationType.JOIN_REQUEST,
      status: InvitationStatus.PENDING,
    });

    await notifySafely([team.owner], {
      type: NotificationType.JOIN_REQUEST,
      category: NotificationCategory.TEAM,
      title: 'New join request',
      body: `A player requested to join ${team.name}.`,
      data: { teamId: String(team._id), invitationId: String(joinRequest._id), playerId: String(player._id) },
      relatedEntityType: 'TeamInvitation',
      relatedEntityId: String(joinRequest._id),
      dedupeKey: `join-request:${joinRequest._id}`,
    });

    return TeamInvitation.findById(joinRequest._id)
      .populate('team', 'name logo location')
      .populate('invitedBy', 'name email avatar')
      .lean();
  }

  /**
   * Respond to an invitation or join request (Accept or Reject)
   */
  public async respondToInvitation(
    invitationId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    status: InvitationStatus
  ): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(invitationId.toString())) {
      throw ApiError.badRequest('Invalid invitation ID format.');
    }

    if (![InvitationStatus.ACCEPTED, InvitationStatus.REJECTED].includes(status)) {
      throw ApiError.badRequest(`Status must be either '${InvitationStatus.ACCEPTED}' or '${InvitationStatus.REJECTED}'.`);
    }

    const invitation = await TeamInvitation.findById(invitationId).populate('team');
    if (!invitation) {
      throw ApiError.notFound(MESSAGES.TEAM.INVITATION_NOT_FOUND || 'Invitation not found.');
    }

    if (invitation.status !== InvitationStatus.PENDING) {
      throw ApiError.badRequest('This invitation has already been processed.');
    }

    const team = invitation.team as any;

    // Authorization checks based on invitation direction
    if (invitation.type === InvitationType.INVITE) {
      // The invited player/user must respond
      let isRecipient = invitation.user && invitation.user.toString() === userId.toString();
      if (!isRecipient && invitation.player) {
        const player = await Player.findById(invitation.player);
        if (player && player.user.toString() === userId.toString()) {
          isRecipient = true;
        }
      }

      if (!isRecipient) {
        throw ApiError.forbidden(MESSAGES.AUTH.FORBIDDEN || 'You are not authorized to respond to this invitation.');
      }
    } else if (invitation.type === InvitationType.JOIN_REQUEST) {
      // Team owner must respond
      if (team.owner.toString() !== userId.toString()) {
        throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only the team owner can respond to join requests.');
      }
    }

    invitation.status = status;
    await invitation.save();

    if (status === InvitationStatus.ACCEPTED && invitation.player) {
      // Enroll or reactivate member
      const existingMember = await TeamMember.findOne({
        team: team._id,
        player: invitation.player,
      });

      if (existingMember) {
        existingMember.status = TeamMemberStatus.ACTIVE;
        existingMember.joinedAt = new Date();
        await existingMember.save();
      } else {
        await TeamMember.create({
          team: team._id,
          player: invitation.player,
          role: TeamMemberRole.PLAYER,
          status: TeamMemberStatus.ACTIVE,
          joinedAt: new Date(),
        });
      }
    }

    const accepted = status === InvitationStatus.ACCEPTED;
    const isInvite = invitation.type === InvitationType.INVITE;
    const recipient = isInvite ? invitation.invitedBy || invitation.user : invitation.user;
    const notificationType = isInvite
      ? accepted
        ? NotificationType.TEAM_INVITATION_ACCEPTED
        : NotificationType.TEAM_INVITATION_REJECTED
      : accepted
      ? NotificationType.JOIN_REQUEST_APPROVED
      : NotificationType.JOIN_REQUEST_REJECTED;
    const outcome = isInvite
      ? accepted
        ? 'accepted'
        : 'declined'
      : accepted
      ? 'approved'
      : 'rejected';

    await notifySafely([recipient], {
      type: notificationType,
      category: NotificationCategory.TEAM,
      title: `Team ${outcome}`,
      body: `Your ${isInvite ? 'invitation to' : 'request to join'} ${team.name} was ${outcome}.`,
      data: {
        teamId: String(team._id),
        invitationId: String(invitation._id),
        status,
      },
      relatedEntityType: 'TeamInvitation',
      relatedEntityId: String(invitation._id),
      dedupeKey: `team-invitation-response:${invitation._id}:${status}`,
    });

    return TeamInvitation.findById(invitation._id)
      .populate('team', 'name logo location')
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email avatar' },
      })
      .populate('invitedBy', 'name email avatar')
      .lean();
  }

  /**
   * Get all invitations sent by or received for a specific team (Owner action)
   */
  public async getTeamInvitations(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId
  ): Promise<any[]> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can view team invitations.');
    }

    return TeamInvitation.find({ team: teamId })
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .populate('user', 'name email avatar')
      .populate('invitedBy', 'name email avatar')
      .sort('-createdAt')
      .lean();
  }

  /**
   * Get all invitations received by the current user or their player profile
   */
  public async getUserInvitations(userId: string | Types.ObjectId): Promise<any[]> {
    const player = await Player.findOne({ user: userId });

    const queryConditions: any[] = [{ user: userId }];
    if (player) {
      queryConditions.push({ player: player._id });
    }

    return TeamInvitation.find({
      $or: queryConditions,
      type: InvitationType.INVITE,
    })
      .populate('team', 'name logo location owner')
      .populate('invitedBy', 'name email avatar')
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email avatar' },
      })
      .sort('-createdAt')
      .lean();
  }

  /**
   * Update a member's role (CAPTAIN, VICE_CAPTAIN, WICKETKEEPER, PLAYER)
   */
  public async updateMemberRole(
    teamId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    memberId: string | Types.ObjectId,
    role: TeamMemberRole
  ): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    if (team.owner.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.TEAM.ONLY_OWNER || 'Only team owner can update member roles.');
    }

    // Match member by either TeamMember _id or player _id
    const member = await TeamMember.findOne({
      team: teamId,
      status: TeamMemberStatus.ACTIVE,
      $or: [
        ...(mongoose.Types.ObjectId.isValid(memberId.toString())
          ? [{ _id: memberId }, { player: memberId }]
          : []),
      ],
    });

    if (!member) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_MEMBER || 'Team member not found.');
    }

    const previousRole = member.role;
    member.role = role;
    await member.save();

    // Synchronize leadership fields on the team document
    if (role === TeamMemberRole.CAPTAIN) {
      await TeamMember.updateMany(
        { team: teamId, _id: { $ne: member._id }, role: TeamMemberRole.CAPTAIN },
        { role: TeamMemberRole.PLAYER }
      );
      team.captain = member.player;
      await team.save();
    } else if (role === TeamMemberRole.VICE_CAPTAIN) {
      await TeamMember.updateMany(
        { team: teamId, _id: { $ne: member._id }, role: TeamMemberRole.VICE_CAPTAIN },
        { role: TeamMemberRole.PLAYER }
      );
      team.viceCaptain = member.player;
      await team.save();
    } else if (role === TeamMemberRole.WICKETKEEPER) {
      team.wicketkeeper = member.player;
      await team.save();
    } else {
      // If demoted from leadership position, clear corresponding team reference
      if (previousRole === TeamMemberRole.CAPTAIN && team.captain?.toString() === member.player.toString()) {
        team.captain = undefined;
        await team.save();
      }
      if (previousRole === TeamMemberRole.VICE_CAPTAIN && team.viceCaptain?.toString() === member.player.toString()) {
        team.viceCaptain = undefined;
        await team.save();
      }
      if (previousRole === TeamMemberRole.WICKETKEEPER && team.wicketkeeper?.toString() === member.player.toString()) {
        team.wicketkeeper = undefined;
        await team.save();
      }
    }

    return TeamMember.findById(member._id)
      .populate({
        path: 'player',
        populate: { path: 'user', select: 'name email phone avatar' },
      })
      .lean();
  }

  /**
   * Calculate comprehensive team statistics from match records
   */
  public async getTeamStats(teamId: string | Types.ObjectId): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    const teamObjId = new Types.ObjectId(teamId.toString());

    // Fetch all completed matches involving this team
    const [allMatches, completedMatches, inningsList] = await Promise.all([
      Match.find({
        $or: [{ teamA: teamObjId }, { teamB: teamObjId }],
      }).lean(),
      Match.find({
        $or: [{ teamA: teamObjId }, { teamB: teamObjId }],
        status: MatchStatus.COMPLETED,
      }).lean(),
      Innings.find({
        $or: [{ battingTeam: teamObjId }, { bowlingTeam: teamObjId }],
      }).lean(),
    ]);

    const totalMatchesPlayed = completedMatches.length;

    let won = 0;
    let lost = 0;
    let tied = 0;
    let noResult = 0;

    completedMatches.forEach((m) => {
      if (m.result?.winner && m.result.winner.toString() === teamObjId.toString()) {
        won++;
      } else if (m.result?.resultType === ResultType.TIE) {
        tied++;
      } else if (
        m.result?.resultType === ResultType.NO_RESULT ||
        m.result?.resultType === ResultType.ABANDONED
      ) {
        noResult++;
      } else if (m.result?.winner && m.result.winner.toString() !== teamObjId.toString()) {
        lost++;
      }
    });

    const winPercentage =
      totalMatchesPlayed > 0 ? Number(((won / totalMatchesPlayed) * 100).toFixed(2)) : 0;

    let totalRunsScored = 0;
    let highestScore = 0;
    let lowestScore = Number.MAX_SAFE_INTEGER;
    let totalWicketsTaken = 0;

    inningsList.forEach((inn) => {
      if (inn.battingTeam && inn.battingTeam.toString() === teamObjId.toString()) {
        totalRunsScored += inn.totalRuns || 0;
        if (inn.totalRuns > highestScore) {
          highestScore = inn.totalRuns;
        }
        if (inn.totalRuns < lowestScore) {
          lowestScore = inn.totalRuns;
        }
      }

      if (inn.bowlingTeam && inn.bowlingTeam.toString() === teamObjId.toString()) {
        totalWicketsTaken += inn.totalWickets || 0;
      }
    });

    if (lowestScore === Number.MAX_SAFE_INTEGER) {
      lowestScore = 0;
    }

    return {
      team: {
        id: team._id,
        name: team.name,
        logo: team.logo,
        location: team.location,
      },
      matches: {
        totalScheduled: allMatches.length,
        played: totalMatchesPlayed,
        won,
        lost,
        tied,
        noResult,
        winPercentage,
      },
      batting: {
        totalRunsScored,
        highestScore,
        lowestScore,
      },
      bowling: {
        totalWicketsTaken,
      },
    };
  }

  /**
   * Retrieve paginated match history for a given team
   */
  public async getTeamMatches(
    teamId: string | Types.ObjectId,
    query: Record<string, any> = {}
  ): Promise<IPaginatedResult<any>> {
    if (!mongoose.Types.ObjectId.isValid(teamId.toString())) {
      throw ApiError.badRequest('Invalid team ID format.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound(MESSAGES.TEAM.NOT_FOUND || 'Team not found.');
    }

    const { page, limit, skip, sort } = getPaginationParams(query, 10, 50, '-matchDate');
    const teamObjId = new Types.ObjectId(teamId.toString());

    const filter: Record<string, any> = {
      $or: [{ teamA: teamObjId }, { teamB: teamObjId }],
    };

    if (query.status) {
      filter.status = query.status;
    }

    if (query.format) {
      filter.format = query.format;
    }

    const [matches, total] = await Promise.all([
      Match.find(filter)
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .populate('teamA', 'name logo location')
        .populate('teamB', 'name logo location')
        .populate('tournament', 'name')
        .populate('result.winner', 'name logo')
        .populate({
          path: 'playerOfMatch',
          populate: { path: 'user', select: 'name avatar' },
        })
        .lean(),
      Match.countDocuments(filter),
    ]);

    return {
      data: matches,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }
}

export const teamService = new TeamService();
export default teamService;
