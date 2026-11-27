import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import fs from 'fs';
import { Request, RequestHandler, NextFunction, Response } from 'express';
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
const ALLOWED_EXTENSIONS = new Set(['.jpg', '.jpeg', '.png', '.gif', '.webp']);

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
  const ext = path.extname(file.originalname || '').toLowerCase();
  const mime = (file.mimetype || '').toLowerCase();
  if (ALLOWED_MIME_TYPES.includes(mime) && ALLOWED_EXTENSIONS.has(ext)) {
    cb(null, true);
    return;
  }
  cb(
    new ApiError(
      400,
      `Invalid file type: ${file.mimetype}. Allowed types are JPEG, JPG, PNG, GIF, and WEBP.`
    )
  );
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
const IMAGE_SIGNATURES: Array<{ mime: string; check: (buf: Buffer) => boolean }> = [
  { mime: 'image/jpeg', check: (b) => b.length >= 3 && b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  { mime: 'image/png', check: (b) => b.length >= 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47 },
  { mime: 'image/gif', check: (b) => b.length >= 6 && (b.toString('ascii', 0, 6) === 'GIF87a' || b.toString('ascii', 0, 6) === 'GIF89a') },
  { mime: 'image/webp', check: (b) => b.length >= 12 && b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP' },
];

const validateUploadedImage = (req: Request, _res: Response, next: NextFunction): void => {
  const file = req.file;
  if (!file) return next();
  try {
    const fd = fs.openSync(file.path, 'r');
    const buf = Buffer.alloc(16);
    fs.readSync(fd, buf, 0, 16, 0);
    fs.closeSync(fd);
    const mime = (file.mimetype || '').toLowerCase();
    const ok = IMAGE_SIGNATURES.some((s) => s.mime === mime && s.check(buf));
    if (!ok) {
      fs.unlinkSync(file.path);
      return next(new ApiError(400, 'Invalid image content.'));
    }
    return next();
  } catch {
    try { fs.unlinkSync(file.path); } catch {}
    return next(new ApiError(400, 'Unable to validate uploaded file.'));
  }
};

export const uploadSingle = (fieldName: string = 'avatar'): RequestHandler[] => {
  return [upload.single(fieldName), validateUploadedImage as RequestHandler];
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
