import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { TeamMemberRole, TeamMemberStatus } from '../constants/enums';

export interface ITeamMember {
  team: Types.ObjectId;
  player: Types.ObjectId;
  role: TeamMemberRole;
  status: TeamMemberStatus;
  joinedAt: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export type TeamMemberDocument = Document<unknown, {}, ITeamMember> & ITeamMember;
export type TeamMemberModel = Model<ITeamMember>;

const teamMemberSchema = new Schema<ITeamMember, TeamMemberModel>(
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
      required: [true, 'Player reference is required'],
      index: true,
    },
    role: {
      type: String,
      enum: Object.values(TeamMemberRole),
      default: TeamMemberRole.PLAYER,
    },
    status: {
      type: String,
      enum: Object.values(TeamMemberStatus),
      default: TeamMemberStatus.ACTIVE,
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Compound unique index preventing duplicate player enrollment in the same team
teamMemberSchema.index({ team: 1, player: 1 }, { unique: true });
teamMemberSchema.index({ player: 1, status: 1 });

export const TeamMember = mongoose.model<ITeamMember, TeamMemberModel>('TeamMember', teamMemberSchema);

export default TeamMember;
