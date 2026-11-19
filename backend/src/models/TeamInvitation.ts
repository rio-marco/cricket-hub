import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { InvitationType, InvitationStatus } from '../constants/enums';

export interface ITeamInvitation {
  team: Types.ObjectId;
  player?: Types.ObjectId;
  user?: Types.ObjectId;
  invitedBy: Types.ObjectId;
  type: InvitationType;
  status: InvitationStatus;
  message?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type TeamInvitationDocument = Document<unknown, {}, ITeamInvitation> & ITeamInvitation;
export type TeamInvitationModel = Model<ITeamInvitation>;

const teamInvitationSchema = new Schema<ITeamInvitation, TeamInvitationModel>(
  {
    team: {
      type: Schema.Types.ObjectId,
      ref: 'Team',
      required: [true, 'Team reference is required'],
      index: true,
    },
    player: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
      index: true,
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    invitedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'InvitedBy user reference is required'],
    },
    type: {
      type: String,
      enum: Object.values(InvitationType),
      required: [true, 'Invitation type is required'],
    },
    status: {
      type: String,
      enum: Object.values(InvitationStatus),
      default: InvitationStatus.PENDING,
      index: true,
    },
    message: {
      type: String,
      trim: true,
      maxlength: [500, 'Message cannot exceed 500 characters'],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
teamInvitationSchema.index({ team: 1, player: 1, status: 1 });
teamInvitationSchema.index({ team: 1, user: 1, status: 1 });
teamInvitationSchema.index({ invitedBy: 1, status: 1 });

export const TeamInvitation = mongoose.model<ITeamInvitation, TeamInvitationModel>(
  'TeamInvitation',
  teamInvitationSchema
);

export default TeamInvitation;
