import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { DevicePlatform } from '../constants/enums';

export interface IDeviceToken {
  user: Types.ObjectId;
  token: string;
  platform: DevicePlatform;
  deviceId?: string;
  appVersion?: string;
  isActive: boolean;
  lastUsedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export type DeviceTokenDocument = Document<unknown, {}, IDeviceToken> & IDeviceToken;
export type DeviceTokenModel = Model<IDeviceToken>;

const deviceTokenSchema = new Schema<IDeviceToken, DeviceTokenModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      index: true,
    },
    token: {
      type: String,
      required: [true, 'Device token is required'],
      trim: true,
      unique: true,
    },
    platform: {
      type: String,
      enum: Object.values(DevicePlatform),
      required: [true, 'Device platform is required'],
    },
    deviceId: {
      type: String,
      trim: true,
      maxlength: [150, 'Device ID cannot exceed 150 characters'],
    },
    appVersion: {
      type: String,
      trim: true,
      maxlength: [50, 'App version cannot exceed 50 characters'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastUsedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

deviceTokenSchema.index({ user: 1, isActive: 1 });
deviceTokenSchema.index({ user: 1, platform: 1 });

export const DeviceToken = mongoose.model<IDeviceToken, DeviceTokenModel>(
  'DeviceToken',
  deviceTokenSchema
);

export default DeviceToken;
