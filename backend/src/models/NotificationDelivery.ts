import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { NotificationDeliveryStatus } from '../constants/enums';

export interface INotificationDelivery {
  notification: Types.ObjectId;
  deviceToken: Types.ObjectId;
  status: NotificationDeliveryStatus;
  attempts: number;
  maxAttempts: number;
  lastAttemptAt?: Date;
  nextAttemptAt?: Date;
  sentAt?: Date;
  lastErrorCode?: string;
  lastError?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type NotificationDeliveryDocument = Document<unknown, {}, INotificationDelivery> &
  INotificationDelivery;
export type NotificationDeliveryModel = Model<INotificationDelivery>;

const notificationDeliverySchema = new Schema<INotificationDelivery, NotificationDeliveryModel>(
  {
    notification: {
      type: Schema.Types.ObjectId,
      ref: 'Notification',
      required: [true, 'Notification reference is required'],
      index: true,
    },
    deviceToken: {
      type: Schema.Types.ObjectId,
      ref: 'DeviceToken',
      required: [true, 'Device token reference is required'],
      index: true,
    },
    status: {
      type: String,
      enum: Object.values(NotificationDeliveryStatus),
      default: NotificationDeliveryStatus.PENDING,
      index: true,
    },
    attempts: {
      type: Number,
      default: 0,
      min: 0,
    },
    maxAttempts: {
      type: Number,
      default: 5,
      min: 1,
    },
    lastAttemptAt: {
      type: Date,
    },
    nextAttemptAt: {
      type: Date,
      default: Date.now,
    },
    sentAt: {
      type: Date,
    },
    lastErrorCode: {
      type: String,
      trim: true,
      maxlength: [100, 'Error code cannot exceed 100 characters'],
    },
    lastError: {
      type: String,
      trim: true,
      maxlength: [500, 'Error message cannot exceed 500 characters'],
    },
  },
  {
    timestamps: true,
  }
);

notificationDeliverySchema.index({ status: 1, nextAttemptAt: 1 });
notificationDeliverySchema.index({ notification: 1, deviceToken: 1 });

export const NotificationDelivery = mongoose.model<INotificationDelivery, NotificationDeliveryModel>(
  'NotificationDelivery',
  notificationDeliverySchema
);

export default NotificationDelivery;
