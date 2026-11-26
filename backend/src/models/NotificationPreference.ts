import mongoose, { Schema, Document, Model, Types } from 'mongoose';

export interface INotificationPreference {
  user: Types.ObjectId;
  pushEnabled: boolean;
  teamInvitations: boolean;
  joinRequests: boolean;
  tournamentUpdates: boolean;
  matchReminders: boolean;
  matchResults: boolean;
  liveScoreUpdates: boolean;
  wicketAlerts: boolean;
  overAlerts: boolean;
  inningsAlerts: boolean;
  auctionUpdates: boolean;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type NotificationPreferenceDocument = Document<unknown, {}, INotificationPreference> &
  INotificationPreference;
export type NotificationPreferenceModel = Model<INotificationPreference>;

const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;

const notificationPreferenceSchema = new Schema<
  INotificationPreference,
  NotificationPreferenceModel
>(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User reference is required'],
      unique: true,
      index: true,
    },
    pushEnabled: { type: Boolean, default: true },
    teamInvitations: { type: Boolean, default: true },
    joinRequests: { type: Boolean, default: true },
    tournamentUpdates: { type: Boolean, default: true },
    matchReminders: { type: Boolean, default: true },
    matchResults: { type: Boolean, default: true },
    liveScoreUpdates: { type: Boolean, default: false },
    wicketAlerts: { type: Boolean, default: true },
    overAlerts: { type: Boolean, default: false },
    inningsAlerts: { type: Boolean, default: true },
    auctionUpdates: { type: Boolean, default: true },
    quietHoursEnabled: { type: Boolean, default: false },
    quietHoursStart: {
      type: String,
      default: '22:00',
      match: [timePattern, 'Quiet hours start must use HH:mm format'],
    },
    quietHoursEnd: {
      type: String,
      default: '08:00',
      match: [timePattern, 'Quiet hours end must use HH:mm format'],
    },
  },
  {
    timestamps: true,
  }
);

export const NotificationPreference = mongoose.model<
  INotificationPreference,
  NotificationPreferenceModel
>('NotificationPreference', notificationPreferenceSchema);

export default NotificationPreference;
