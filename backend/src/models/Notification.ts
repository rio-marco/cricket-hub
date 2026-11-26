import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { NotificationCategory, NotificationType } from '../constants/enums';

export interface INotification {
  user: Types.ObjectId;
  type: NotificationType;
  category: NotificationCategory;
  title: string;
  body: string;
  data?: Record<string, any>;
  relatedEntityType?: string;
  relatedEntityId?: string;
  dedupeKey?: string;
  isRead: boolean;
  readAt?: Date;
  expiresAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export type NotificationDocument = Document<unknown, {}, INotification> & INotification;
export type NotificationModel = Model<INotification>;

const notificationSchema = new Schema<INotification, NotificationModel>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      index: true,
    },
    type: {
      type: String,
      enum: Object.values(NotificationType),
      required: [true, 'Notification type is required'],
    },
    category: {
      type: String,
      enum: Object.values(NotificationCategory),
      default: NotificationCategory.SYSTEM,
      index: true,
    },
    title: {
      type: String,
      required: [true, 'Notification title is required'],
      trim: true,
      maxlength: [150, 'Notification title cannot exceed 150 characters'],
    },
    body: {
      type: String,
      required: [true, 'Notification body is required'],
      trim: true,
      maxlength: [1000, 'Notification body cannot exceed 1000 characters'],
    },
    data: {
      type: Schema.Types.Mixed,
      default: {},
    },
    relatedEntityType: {
      type: String,
      trim: true,
      maxlength: [50, 'Related entity type cannot exceed 50 characters'],
    },
    relatedEntityId: {
      type: String,
      trim: true,
      maxlength: [50, 'Related entity ID cannot exceed 50 characters'],
    },
    dedupeKey: {
      type: String,
      trim: true,
      maxlength: [200, 'Dedupe key cannot exceed 200 characters'],
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
    readAt: {
      type: Date,
    },
    expiresAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

notificationSchema.index({ user: 1, isRead: 1 });
notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, category: 1, createdAt: -1 });
notificationSchema.index({ user: 1, dedupeKey: 1 }, { unique: true, sparse: true });
notificationSchema.index({ expiresAt: 1 }, { sparse: true });

export const Notification = mongoose.model<INotification, NotificationModel>(
  'Notification',
  notificationSchema
);

export default Notification;
