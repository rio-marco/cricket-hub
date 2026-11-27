import { UserRole } from './roles';

export enum AdminPermission {
  DASHBOARD_READ = 'DASHBOARD_READ',
  USERS_READ = 'USERS_READ',
  USERS_MANAGE = 'USERS_MANAGE',
  TEAMS_READ = 'TEAMS_READ',
  TEAMS_MANAGE = 'TEAMS_MANAGE',
  PLAYERS_READ = 'PLAYERS_READ',
  TOURNAMENTS_READ = 'TOURNAMENTS_READ',
  TOURNAMENTS_MANAGE = 'TOURNAMENTS_MANAGE',
  MATCHES_READ = 'MATCHES_READ',
  MATCHES_MANAGE = 'MATCHES_MANAGE',
  SCORING_AUDIT_READ = 'SCORING_AUDIT_READ',
  AUCTIONS_READ = 'AUCTIONS_READ',
  NOTIFICATIONS_READ = 'NOTIFICATIONS_READ',
  NOTIFICATIONS_SEND = 'NOTIFICATIONS_SEND',
  REPORTS_READ = 'REPORTS_READ',
  AUDITS_READ = 'AUDITS_READ',
}

export enum AdminAction {
  ADMIN_LOGIN = 'ADMIN_LOGIN',
  ADMIN_LOGIN_FAILED = 'ADMIN_LOGIN_FAILED',
  USER_STATUS_CHANGED = 'USER_STATUS_CHANGED',
  USER_ROLE_CHANGED = 'USER_ROLE_CHANGED',
  USER_UPDATED = 'USER_UPDATED',
  USER_DELETED = 'USER_DELETED',
  TEAM_STATUS_CHANGED = 'TEAM_STATUS_CHANGED',
  TOURNAMENT_STATUS_CHANGED = 'TOURNAMENT_STATUS_CHANGED',
  TOURNAMENT_TEAM_DECISION = 'TOURNAMENT_TEAM_DECISION',
  MATCH_STATUS_CHANGED = 'MATCH_STATUS_CHANGED',
  MATCH_CORRECTION = 'MATCH_CORRECTION',
  NOTIFICATION_BROADCAST = 'NOTIFICATION_BROADCAST',
  NOTIFICATION_USERS = 'NOTIFICATION_USERS',
}

export const ADMIN_PERMISSIONS: readonly AdminPermission[] = Object.values(AdminPermission);

export const ADMIN_READ_PERMISSIONS: ReadonlySet<AdminPermission> = new Set([
  AdminPermission.DASHBOARD_READ,
  AdminPermission.USERS_READ,
  AdminPermission.TEAMS_READ,
  AdminPermission.PLAYERS_READ,
  AdminPermission.TOURNAMENTS_READ,
  AdminPermission.MATCHES_READ,
  AdminPermission.SCORING_AUDIT_READ,
  AdminPermission.AUCTIONS_READ,
  AdminPermission.NOTIFICATIONS_READ,
  AdminPermission.REPORTS_READ,
  AdminPermission.AUDITS_READ,
]);

export const ADMIN_WRITE_PERMISSIONS: ReadonlySet<AdminPermission> = new Set([
  AdminPermission.USERS_MANAGE,
  AdminPermission.TEAMS_MANAGE,
  AdminPermission.TOURNAMENTS_MANAGE,
  AdminPermission.MATCHES_MANAGE,
  AdminPermission.NOTIFICATIONS_SEND,
]);

export const ADMIN_SENSITIVE_ACTIONS: ReadonlySet<AdminAction> = new Set([
  AdminAction.USER_STATUS_CHANGED,
  AdminAction.USER_ROLE_CHANGED,
  AdminAction.USER_UPDATED,
  AdminAction.USER_DELETED,
  AdminAction.TEAM_STATUS_CHANGED,
  AdminAction.TOURNAMENT_STATUS_CHANGED,
  AdminAction.TOURNAMENT_TEAM_DECISION,
  AdminAction.MATCH_STATUS_CHANGED,
  AdminAction.MATCH_CORRECTION,
]);

export const ADMIN_ROLE_PERMISSIONS: Record<string, readonly AdminPermission[]> = {
  [UserRole.ADMIN]: ADMIN_PERMISSIONS,
};

export type AdminRole = UserRole | string;

export const isAdminRole = (role?: string | null): boolean =>
  Boolean(role && Object.prototype.hasOwnProperty.call(ADMIN_ROLE_PERMISSIONS, role));

export const getPermissionsForRole = (role?: string | null): readonly AdminPermission[] =>
  role && Object.prototype.hasOwnProperty.call(ADMIN_ROLE_PERMISSIONS, role)
    ? ADMIN_ROLE_PERMISSIONS[role]
    : [];

export const hasAdminPermission = (role?: string | null, permission?: AdminPermission): boolean => {
  if (!isAdminRole(role)) return false;
  if (!permission) return true;
  return getPermissionsForRole(role).includes(permission);
};

export default {
  AdminPermission,
  AdminAction,
  ADMIN_PERMISSIONS,
  ADMIN_READ_PERMISSIONS,
  ADMIN_WRITE_PERMISSIONS,
  ADMIN_SENSITIVE_ACTIONS,
  ADMIN_ROLE_PERMISSIONS,
  isAdminRole,
  getPermissionsForRole,
  hasAdminPermission,
};
