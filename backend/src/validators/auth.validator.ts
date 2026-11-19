import Joi from 'joi';
import { UserRole } from '../constants/roles';

// Password complexity: minimum 8 characters, at least 1 uppercase, 1 lowercase, and 1 numeric digit
const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
const passwordMessage =
  'Password must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, and one number';

// Phone number: optional leading +, followed by 10 to 15 numeric digits
const phonePattern = /^\+?[0-9]{10,15}$/;
const phoneMessage = 'Phone number must be a valid 10-15 digit number with optional leading +';

/**
 * User Registration Schema
 */
export const registerSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).required().messages({
    'string.base': 'Name must be a string',
    'string.empty': 'Name cannot be empty',
    'string.min': 'Name must be at least 2 characters long',
    'string.max': 'Name cannot exceed 50 characters',
    'any.required': 'Name is required',
  }),
  email: Joi.string().trim().email().lowercase().optional().messages({
    'string.email': 'Please provide a valid email address',
  }),
  phone: Joi.string().trim().pattern(phonePattern).optional().messages({
    'string.pattern.base': phoneMessage,
  }),
  password: Joi.string().min(8).pattern(passwordPattern).required().messages({
    'string.empty': 'Password is required',
    'string.min': 'Password must be at least 8 characters long',
    'string.pattern.base': passwordMessage,
    'any.required': 'Password is required',
  }),
  role: Joi.string()
    .valid(...Object.values(UserRole))
    .optional()
    .default(UserRole.NORMAL_USER)
    .messages({
      'any.only': `Role must be one of: ${Object.values(UserRole).join(', ')}`,
    }),
})
  .or('email', 'phone')
  .messages({
    'object.missing': 'Either email or phone number must be provided for registration',
  });

/**
 * User Login Schema
 */
export const loginSchema = Joi.object({
  email: Joi.string().trim().email().lowercase().optional().messages({
    'string.email': 'Please provide a valid email address',
  }),
  phone: Joi.string().trim().pattern(phonePattern).optional().messages({
    'string.pattern.base': phoneMessage,
  }),
  password: Joi.string().required().messages({
    'string.empty': 'Password is required',
    'any.required': 'Password is required',
  }),
})
  .or('email', 'phone')
  .messages({
    'object.missing': 'Either email or phone number is required to log in',
  });

/**
 * OTP Verification Schema
 */
export const verifyOTPSchema = Joi.object({
  userId: Joi.string().trim().required().messages({
    'string.empty': 'User ID is required',
    'any.required': 'User ID is required',
  }),
  otp: Joi.string().trim().length(6).required().messages({
    'string.empty': 'OTP is required',
    'string.length': 'OTP must be exactly 6 digits',
    'any.required': 'OTP is required',
  }),
});

/**
 * Forgot Password Schema
 */
export const forgotPasswordSchema = Joi.object({
  email: Joi.string().trim().email().lowercase().optional().messages({
    'string.email': 'Please provide a valid email address',
  }),
  phone: Joi.string().trim().pattern(phonePattern).optional().messages({
    'string.pattern.base': phoneMessage,
  }),
})
  .or('email', 'phone')
  .messages({
    'object.missing': 'Either email or phone number is required to request a password reset',
  });

/**
 * Reset Password Schema
 */
export const resetPasswordSchema = Joi.object({
  userId: Joi.string().trim().required().messages({
    'string.empty': 'User ID is required',
    'any.required': 'User ID is required',
  }),
  otp: Joi.string().trim().length(6).required().messages({
    'string.empty': 'OTP is required',
    'string.length': 'OTP must be exactly 6 digits',
    'any.required': 'OTP is required',
  }),
  newPassword: Joi.string().min(8).pattern(passwordPattern).required().messages({
    'string.empty': 'New password is required',
    'string.min': 'New password must be at least 8 characters long',
    'string.pattern.base': passwordMessage,
    'any.required': 'New password is required',
  }),
});

/**
 * Change Password Schema (Authenticated)
 */
export const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().required().messages({
    'string.empty': 'Current password is required',
    'any.required': 'Current password is required',
  }),
  newPassword: Joi.string().min(8).pattern(passwordPattern).required().messages({
    'string.empty': 'New password is required',
    'string.min': 'New password must be at least 8 characters long',
    'string.pattern.base': passwordMessage,
    'any.required': 'New password is required',
  }),
});

/**
 * Refresh Token Schema
 */
export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().trim().required().messages({
    'string.empty': 'Refresh token is required',
    'any.required': 'Refresh token is required',
  }),
});

/**
 * Update Profile Schema
 */
export const updateProfileSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).optional(),
  email: Joi.string().trim().email().lowercase().optional(),
  phone: Joi.string().trim().pattern(phonePattern).optional(),
  avatar: Joi.string().uri().optional().allow(''),
  fcmToken: Joi.string().trim().optional().allow(''),
});

export default {
  registerSchema,
  loginSchema,
  verifyOTPSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  refreshTokenSchema,
  updateProfileSchema,
};
