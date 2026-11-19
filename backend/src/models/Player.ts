import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { PlayingRole, BattingStyle, BowlingStyle } from '../constants/enums';

export interface IPlayer {
  user: Types.ObjectId;
  playingRole: PlayingRole;
  battingStyle: BattingStyle;
  bowlingStyle: BowlingStyle;
  jerseyNumber?: number;
  dateOfBirth?: Date;
  city?: string;
  bio?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type PlayerDocument = Document<unknown, {}, IPlayer> & IPlayer;
export type PlayerModel = Model<IPlayer>;

const playerSchema = new Schema<IPlayer, PlayerModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required for player profile'],
      unique: true,
      index: true,
    },
    playingRole: {
      type: String,
      enum: Object.values(PlayingRole),
      required: [true, 'Playing role is required'],
    },
    battingStyle: {
      type: String,
      enum: Object.values(BattingStyle),
      required: [true, 'Batting style is required'],
    },
    bowlingStyle: {
      type: String,
      enum: Object.values(BowlingStyle),
      default: BowlingStyle.NONE,
    },
    jerseyNumber: {
      type: Number,
      min: [0, 'Jersey number cannot be negative'],
      max: [999, 'Jersey number exceeds maximum allowed'],
    },
    dateOfBirth: {
      type: Date,
    },
    city: {
      type: String,
      trim: true,
    },
    bio: {
      type: String,
      trim: true,
      maxlength: [500, 'Bio cannot exceed 500 characters'],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
playerSchema.index({ playingRole: 1 });
playerSchema.index({ city: 1 });

export const Player = mongoose.model<IPlayer, PlayerModel>('Player', playerSchema);

export default Player;
