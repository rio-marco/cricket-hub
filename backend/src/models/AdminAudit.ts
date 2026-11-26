import mongoose, { Schema, Document, Model, Types } from 'mongoose';
import { AdminAction } from '../constants/admin';

export interface IAdminAudit {
  adminId?: Types.ObjectId;
  adminRole?: string;
  action: AdminAction;
  targetType: string;
  targetId?: string;
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  reason?: string;
  metadata?: Record<string, unknown>;
  ipAddress?: string;
  userAgent?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export type AdminAuditDocument = Document<unknown, {}, IAdminAudit> & IAdminAudit;
export type AdminAuditModel = Model<IAdminAudit>;

const SENSITIVE_KEYS = new Set([
  'password',
  'otp',
  'token',
  'refreshtoken',
  'fcmtoken',
  'secret',
  'jwt',
  'authorization',
  'cookies',
]);

export const redactSensitive = (value: unknown, seen: WeakSet<object> = new WeakSet()): any => {
  if (value === null || value === undefined) return undefined;
  if (value instanceof Date) return value;
  if (typeof value !== 'object') return value;
  if (seen.has(value as object)) return '[Circular]';
  seen.add(value as object);

  const source: any =
    typeof (value as any).toObject === 'function' ? (value as any).toObject() : value;

  if (Array.isArray(source)) {
    return source.map((item) => redactSensitive(item, seen));
  }

  const result: Record<string, any> = {};
  Object.keys(source).forEach((key) => {
    if (SENSITIVE_KEYS.has(key.toLowerCase().replace(/[-_]/g, ''))) return;
    const child = redactSensitive(source[key], seen);
    if (child !== undefined) result[key] = child;
  });
  return result;
};

const adminAuditSchema = new Schema<IAdminAudit, AdminAuditModel>(
  {
    adminId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    adminRole: {
      type: String,
      trim: true,
    },
    action: {
      type: String,
      enum: Object.values(AdminAction),
      required: [true, 'Audit action is required'],
      index: true,
    },
    targetType: {
      type: String,
      trim: true,
      required: [true, 'Audit target type is required'],
    },
    targetId: {
      type: String,
      trim: true,
      index: true,
    },
    before: {
      type: Schema.Types.Mixed,
      default: undefined,
    },
    after: {
      type: Schema.Types.Mixed,
      default: undefined,
    },
    reason: {
      type: String,
      trim: true,
      maxlength: [1000, 'Reason cannot exceed 1000 characters'],
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: undefined,
    },
    ipAddress: {
      type: String,
      trim: true,
    },
    userAgent: {
      type: String,
      trim: true,
      maxlength: [500, 'User agent cannot exceed 500 characters'],
    },
  },
  {
    timestamps: true,
  }
);

adminAuditSchema.pre('validate', function () {
  this.before = redactSensitive(this.before);
  this.after = redactSensitive(this.after);
  this.metadata = redactSensitive(this.metadata);
});

adminAuditSchema.index({ adminId: 1, createdAt: -1 });
adminAuditSchema.index({ action: 1, createdAt: -1 });
adminAuditSchema.index({ targetType: 1, targetId: 1, createdAt: -1 });

export const AdminAudit = mongoose.model<IAdminAudit, AdminAuditModel>('AdminAudit', adminAuditSchema);

export default AdminAudit;
