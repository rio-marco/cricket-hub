import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import fs from 'fs';
import { Request, RequestHandler } from 'express';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';

// Ensure upload directory exists synchronously on startup
const uploadDir = path.resolve(process.cwd(), env.UPLOAD_DIR || 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Allowed MIME types for image uploads
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
];

// Configure disk storage
const storage = multer.diskStorage({
  destination: (_req: Request, _file: Express.Multer.File, cb) => {
    // Re-verify folder exists
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (_req: Request, file: Express.Multer.File, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const sanitizedOriginalName = path
      .basename(file.originalname, ext)
      .replace(/[^a-zA-Z0-9_-]/g, '_');
    cb(null, `${sanitizedOriginalName}-${uniqueSuffix}${ext}`);
  },
});

// File filter validator
const fileFilter = (
  _req: Request,
  file: Express.Multer.File,
  cb: FileFilterCallback
): void => {
  if (ALLOWED_MIME_TYPES.includes(file.mimetype.toLowerCase())) {
    cb(null, true);
  } else {
    cb(
      new ApiError(
        400,
        `Invalid file type: ${file.mimetype}. Allowed types are JPEG, JPG, PNG, GIF, and WEBP.`
      )
    );
  }
};

// Multer upload instance
export const upload = multer({
  storage,
  limits: {
    fileSize: env.MAX_FILE_SIZE || 5 * 1024 * 1024, // 5MB default
  },
  fileFilter,
});

/**
 * Middleware for single file upload
 *
 * @param fieldName Form field name containing the file
 */
export const uploadSingle = (fieldName: string = 'avatar'): RequestHandler => {
  return upload.single(fieldName);
};

/**
 * Middleware for multiple files upload
 *
 * @param fieldName Form field name
 * @param maxCount Maximum number of files permitted
 */
export const uploadMultiple = (
  fieldName: string = 'images',
  maxCount: number = 5
): RequestHandler => {
  return upload.array(fieldName, maxCount);
};

export default {
  upload,
  uploadSingle,
  uploadMultiple,
};
