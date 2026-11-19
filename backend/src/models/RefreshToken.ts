import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export interface IRefreshToken {
  user: Types.ObjectId;
  token: string;
  expiresAt: Date;
  isRevoked: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export type RefreshTokenDocument = Document<unknown, {}, IRefreshToken> & IRefreshToken;
export type RefreshTokenModel = Model<IRefreshToken>;

const refreshTokenSchema = new Schema<IRefreshToken, RefreshTokenModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      index: true,
    },
    token: {
      type: String,
      required: [true, 'Refresh token string is required'],
      unique: true,
      index: true,
    },
    expiresAt: {
      type: Date,
      required: [true, 'Expiration date is required'],
    },
    isRevoked: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
refreshTokenSchema.index({ token: 1 }, { unique: true });
refreshTokenSchema.index({ user: 1, isRevoked: 1 });
// TTL index to automatically purge expired tokens
refreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const RefreshToken = mongoose.model<IRefreshToken, RefreshTokenModel>(
  'RefreshToken',
  refreshTokenSchema
);

export default RefreshToken;
