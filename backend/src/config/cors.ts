import { env } from './env';

export type CorsOrigins = '*' | string[];

export const resolveCorsOrigins = (): CorsOrigins =>
  env.CORS_ORIGIN === '*' ? '*' : env.CORS_ORIGIN.split(',').map((origin) => origin.trim());
