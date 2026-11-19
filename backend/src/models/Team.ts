import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export interface ITeam {
  name: string;
  logo?: string;
  description?: string;
  location?: string;
  owner: Types.ObjectId;
  captain?: Types.ObjectId;
  viceCaptain?: Types.ObjectId;
  wicketkeeper?: Types.ObjectId;
  isActive: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export type TeamDocument = Document<unknown, {}, ITeam> & ITeam;
export type TeamModel = Model<ITeam>;

const teamSchema = new Schema<ITeam, TeamModel>(
  {
    name: {
      type: String,
      required: [true, 'Team name is required'],
      unique: true,
      trim: true,
      minlength: [2, 'Team name must be at least 2 characters'],
      maxlength: [100, 'Team name cannot exceed 100 characters'],
    },
    logo: {
      type: String,
      default: '',
    },
    description: {
      type: String,
      trim: true,
      maxlength: [1000, 'Description cannot exceed 1000 characters'],
    },
    location: {
      type: String,
      trim: true,
    },
    owner: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Team owner is required'],
      index: true,
    },
    captain: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    viceCaptain: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    wicketkeeper: {
      type: Schema.Types.ObjectId,
      ref: 'Player',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
teamSchema.index({ name: 1 }, { unique: true });
teamSchema.index({ owner: 1 });
teamSchema.index({ isActive: 1 });

export const Team = mongoose.model<ITeam, TeamModel>('Team', teamSchema);

export default Team;
