/**
 * User roles within the Cricket Hub platform
 */
export enum UserRole {
  NORMAL_USER = 'NORMAL_USER',
  TEAM_OWNER = 'TEAM_OWNER',
  PLAYER = 'PLAYER',
  TOURNAMENT_ORGANIZER = 'TOURNAMENT_ORGANIZER',
  SCORER = 'SCORER',
  ADMIN = 'ADMIN',
}

export const USER_ROLES = Object.values(UserRole);

export default UserRole;
