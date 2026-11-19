import config from '../config/env';

// ANSI escape codes for console styling
const COLORS = {
  RESET: '\x1b[0m',
  BRIGHT: '\x1b[1m',
  DIM: '\x1b[2m',
  RED: '\x1b[31m',
  GREEN: '\x1b[32m',
  YELLOW: '\x1b[33m',
  BLUE: '\x1b[34m',
  MAGENTA: '\x1b[35m',
  CYAN: '\x1b[36m',
  GRAY: '\x1b[90m',
};

const LOG_LEVEL_PRIORITY: Record<string, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

class Logger {
  private currentLevel: number;

  constructor() {
    const configuredLevel = (config.LOG_LEVEL || 'debug').toLowerCase();
    this.currentLevel = LOG_LEVEL_PRIORITY[configuredLevel] ?? 0;
  }

  private getTimestamp(): string {
    return new Date().toISOString();
  }

  private formatMessage(prefix: string, color: string, message: string): string {
    const timestamp = `${COLORS.GRAY}[${this.getTimestamp()}]${COLORS.RESET}`;
    const tag = `${color}[${prefix}]${COLORS.RESET}`;
    return `${timestamp} ${tag} ${message}`;
  }

  public debug(message: string, ...args: any[]): void {
    if (this.currentLevel <= LOG_LEVEL_PRIORITY.debug) {
      const formatted = this.formatMessage('DEBUG', COLORS.MAGENTA, message);
      if (args.length > 0) {
        console.debug(formatted, ...args);
      } else {
        console.debug(formatted);
      }
    }
  }

  public info(message: string, ...args: any[]): void {
    if (this.currentLevel <= LOG_LEVEL_PRIORITY.info) {
      const formatted = this.formatMessage('INFO', COLORS.CYAN, message);
      if (args.length > 0) {
        console.info(formatted, ...args);
      } else {
        console.info(formatted);
      }
    }
  }

  public warn(message: string, ...args: any[]): void {
    if (this.currentLevel <= LOG_LEVEL_PRIORITY.warn) {
      const formatted = this.formatMessage('WARN', COLORS.YELLOW, message);
      if (args.length > 0) {
        console.warn(formatted, ...args);
      } else {
        console.warn(formatted);
      }
    }
  }

  public error(message: string, ...args: any[]): void {
    if (this.currentLevel <= LOG_LEVEL_PRIORITY.error) {
      const formatted = this.formatMessage('ERROR', COLORS.RED, message);
      if (args.length > 0) {
        console.error(formatted, ...args);
      } else {
        console.error(formatted);
      }
    }
  }
}

export const logger = new Logger();

export default logger;
