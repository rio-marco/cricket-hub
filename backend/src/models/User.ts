import mongoose, { Schema, Document, Model } from 'mongoose';
import bcrypt from 'bcrypt';
import { UserRole } from '../constants/roles';

export type OtpPurpose = 'VERIFICATION' | 'PASSWORD_RESET';

export interface IUserOtp {
  code?: string;
  expiresAt?: Date;
  purpose?: OtpPurpose;
  attempts?: number;
  resendCount?: number;
  lastSentAt?: Date;
}

export interface IUser {
  name: string;
  email?: string;
  phone?: string;
  password?: string;
  avatar?: string;
  role?: UserRole | string;
  isVerified?: boolean;
  isBlocked?: boolean;
  otp?: IUserOtp;
  fcmToken?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IUserMethods {
  comparePassword(candidatePassword: string): Promise<boolean>;
}

export type UserDocument = Document<unknown, {}, IUser> & IUser & IUserMethods;
export type UserModel = Model<IUser, {}, IUserMethods>;

const userOtpSchema = new Schema<IUserOtp>(
  {
    code: {
      type: String,
      trim: true,
    },
    expiresAt: {
      type: Date,
    },
    purpose: {
      type: String,
      enum: ['VERIFICATION', 'PASSWORD_RESET'],
    },
    attempts: {
      type: Number,
      default: 0,
    },
    resendCount: {
      type: Number,
      default: 0,
    },
    lastSentAt: {
      type: Date,
    },
  },
  { _id: false }
);

const userSchema = new Schema<IUser, UserModel, IUserMethods>(
  {
    name: {
      type: String,
      required: [true, 'User name is required'],
      trim: true,
    },
    email: {
      type: String,
      unique: true,
      sparse: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      select: false,
    },
    avatar: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      enum: Object.values(UserRole),
      default: UserRole.NORMAL_USER,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
    isBlocked: {
      type: Boolean,
      default: false,
    },
    otp: {
      type: userOtpSchema,
      default: undefined,
    },
    fcmToken: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

// Indexes
userSchema.index({ email: 1 }, { unique: true, sparse: true });
userSchema.index({ phone: 1 }, { unique: true, sparse: true });
userSchema.index({ role: 1 });

// Password hashing middleware
userSchema.pre('save', async function () {
  if (!this.isModified('password') || !this.password) {
    return;
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword: string): Promise<boolean> {
  if (!this.password) {
    return false;
  }
  return bcrypt.compare(candidatePassword, this.password);
};

export const User = mongoose.model<IUser, UserModel>('User', userSchema);

export default User;
