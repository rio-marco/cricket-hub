/**
 * Cricket match format types
 */
export enum MatchFormat {
  T10 = 'T10',
  T20 = 'T20',
  ODI = 'ODI',
  CUSTOM = 'CUSTOM',
}

/**
 * Types of cricket balls used in matches
 */
export enum BallType {
  TENNIS = 'TENNIS',
  RED = 'RED',
  WHITE = 'WHITE',
}

/**
 * Primary playing role of a cricket player
 */
export enum PlayingRole {
  BATSMAN = 'BATSMAN',
  BOWLER = 'BOWLER',
  ALL_ROUNDER = 'ALL_ROUNDER',
  WICKETKEEPER = 'WICKETKEEPER',
}

/**
 * Batting stance/style
 */
export enum BattingStyle {
  RIGHT_HAND = 'RIGHT_HAND',
  LEFT_HAND = 'LEFT_HAND',
}

/**
 * Bowling arm and style
 */
export enum BowlingStyle {
  RIGHT_ARM_FAST = 'RIGHT_ARM_FAST',
  RIGHT_ARM_MEDIUM = 'RIGHT_ARM_MEDIUM',
  LEFT_ARM_FAST = 'LEFT_ARM_FAST',
  LEFT_ARM_MEDIUM = 'LEFT_ARM_MEDIUM',
  RIGHT_ARM_OFF_SPIN = 'RIGHT_ARM_OFF_SPIN',
  RIGHT_ARM_LEG_SPIN = 'RIGHT_ARM_LEG_SPIN',
  LEFT_ARM_ORTHODOX = 'LEFT_ARM_ORTHODOX',
  LEFT_ARM_CHINAMAN = 'LEFT_ARM_CHINAMAN',
  NONE = 'NONE',
}

/**
 * Modes of batsman dismissal in cricket
 */
export enum DismissalType {
  BOWLED = 'BOWLED',
  CAUGHT = 'CAUGHT',
  LBW = 'LBW',
  RUN_OUT = 'RUN_OUT',
  STUMPED = 'STUMPED',
  HIT_WICKET = 'HIT_WICKET',
  RETIRED_OUT = 'RETIRED_OUT',
  OBSTRUCTING_FIELD = 'OBSTRUCTING_FIELD',
}

/**
 * Types of extra runs awarded in an innings
 */
export enum ExtraType {
  NONE = 'NONE',
  WIDE = 'WIDE',
  NO_BALL = 'NO_BALL',
  BYE = 'BYE',
  LEG_BYE = 'LEG_BYE',
  PENALTY = 'PENALTY',
}

/**
 * Overall match status
 */
export enum MatchStatus {
  UPCOMING = 'UPCOMING',
  TOSS = 'TOSS',
  LIVE = 'LIVE',
  COMPLETED = 'COMPLETED',
  ABANDONED = 'ABANDONED',
  CANCELLED = 'CANCELLED',
}

/**
 * Innings progression status
 */
export enum InningsStatus {
  NOT_STARTED = 'NOT_STARTED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  DECLARED = 'DECLARED',
}

/**
 * Tournament structure formats
 */
export enum TournamentFormat {
  LEAGUE = 'LEAGUE',
  KNOCKOUT = 'KNOCKOUT',
  LEAGUE_KNOCKOUT = 'LEAGUE_KNOCKOUT',
}

/**
 * Tournament lifecycle status
 */
export enum TournamentStatus {
  DRAFT = 'DRAFT',
  REGISTRATION_OPEN = 'REGISTRATION_OPEN',
  REGISTRATION_CLOSED = 'REGISTRATION_CLOSED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

/**
 * Team member status
 */
export enum TeamMemberStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
}

/**
 * Designation/role within a team
 */
export enum TeamMemberRole {
  PLAYER = 'PLAYER',
  CAPTAIN = 'CAPTAIN',
  VICE_CAPTAIN = 'VICE_CAPTAIN',
  WICKETKEEPER = 'WICKETKEEPER',
}

/**
 * Invitation direction/intent
 */
export enum InvitationType {
  INVITE = 'INVITE',
  JOIN_REQUEST = 'JOIN_REQUEST',
}

/**
 * Status of team invitations or join requests
 */
export enum InvitationStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED',
  CANCELLED = 'CANCELLED',
}

/**
 * Team enrollment status in a tournament
 */
export enum TournamentTeamStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

/**
 * Lifecycle status of player auctions
 */
export enum AuctionStatus {
  DRAFT = 'DRAFT',
  UPCOMING = 'UPCOMING',
  LIVE = 'LIVE',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

/**
 * State of a player during an auction
 */
export enum AuctionPlayerStatus {
  AVAILABLE = 'AVAILABLE',
  SOLD = 'SOLD',
  UNSOLD = 'UNSOLD',
}

/**
 * Final match result classification
 */
export enum ResultType {
  RUNS = 'RUNS',
  WICKETS = 'WICKETS',
  TIE = 'TIE',
  DRAW = 'DRAW',
  NO_RESULT = 'NO_RESULT',
  ABANDONED = 'ABANDONED',
}

/**
 * Toss outcome selection
 */
export enum TossDecision {
  BAT = 'BAT',
  BOWL = 'BOWL',
}

/**
 * Push and in-app notification types
 */
export enum NotificationType {
  TEAM_INVITATION = 'TEAM_INVITATION',
  JOIN_REQUEST = 'JOIN_REQUEST',
  TOURNAMENT_REGISTRATION = 'TOURNAMENT_REGISTRATION',
  MATCH_REMINDER = 'MATCH_REMINDER',
  MATCH_RESULT = 'MATCH_RESULT',
  AUCTION_UPDATE = 'AUCTION_UPDATE',
  GENERAL = 'GENERAL',
}
