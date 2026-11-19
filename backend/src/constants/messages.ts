/**
 * Standard API message constants across Cricket Hub modules
 */

export const AUTH_MESSAGES = {
  REGISTER_SUCCESS: 'User registered successfully. Verification OTP has been sent.',
  LOGIN_SUCCESS: 'Logged in successfully.',
  LOGOUT_SUCCESS: 'Logged out successfully.',
  TOKEN_REFRESH_SUCCESS: 'Access token refreshed successfully.',
  OTP_SENT: 'OTP sent successfully.',
  OTP_VERIFIED: 'OTP verified successfully.',
  PASSWORD_RESET_SUCCESS: 'Password has been reset successfully.',
  PROFILE_UPDATED: 'Profile updated successfully.',
  USER_NOT_FOUND: 'User not found.',
  INVALID_CREDENTIALS: 'Invalid email/phone or password.',
  EMAIL_ALREADY_EXISTS: 'An account with this email already exists.',
  PHONE_ALREADY_EXISTS: 'An account with this phone number already exists.',
  INVALID_OTP: 'Invalid or expired OTP.',
  OTP_EXPIRED: 'OTP has expired. Please request a new one.',
  ACCOUNT_BLOCKED: 'Your account has been suspended. Please contact support.',
  UNAUTHORIZED: 'Authentication required to access this resource.',
  FORBIDDEN: 'You do not have permission to perform this action.',
  TOKEN_EXPIRED: 'Authentication token has expired.',
  INVALID_TOKEN: 'Invalid authentication token.',
  REFRESH_TOKEN_REQUIRED: 'Refresh token is required.',
  REFRESH_TOKEN_INVALID: 'Refresh token is invalid or has been revoked.',
};

export const PLAYER_MESSAGES = {
  CREATED: 'Player profile created successfully.',
  UPDATED: 'Player profile updated successfully.',
  FETCHED: 'Player profile retrieved successfully.',
  NOT_FOUND: 'Player profile not found.',
  ALREADY_EXISTS: 'Player profile already exists for this user.',
  LIST_FETCHED: 'Players list retrieved successfully.',
  STATS_FETCHED: 'Player statistics retrieved successfully.',
};

export const TEAM_MESSAGES = {
  CREATED: 'Team created successfully.',
  UPDATED: 'Team details updated successfully.',
  DELETED: 'Team deleted successfully.',
  FETCHED: 'Team retrieved successfully.',
  NOT_FOUND: 'Team not found.',
  NAME_TAKEN: 'A team with this name already exists.',
  MEMBER_ADDED: 'Player added to team successfully.',
  MEMBER_REMOVED: 'Player removed from team successfully.',
  MEMBER_ROLE_UPDATED: 'Team member role updated successfully.',
  ALREADY_MEMBER: 'Player is already a member of this team.',
  NOT_MEMBER: 'Player is not a member of this team.',
  INVITATION_SENT: 'Invitation sent successfully.',
  INVITATION_ACCEPTED: 'Invitation accepted successfully.',
  INVITATION_REJECTED: 'Invitation rejected successfully.',
  INVITATION_CANCELLED: 'Invitation cancelled successfully.',
  INVITATION_NOT_FOUND: 'Invitation not found.',
  JOIN_REQUEST_SENT: 'Join request sent successfully.',
  JOIN_REQUEST_APPROVED: 'Join request approved successfully.',
  JOIN_REQUEST_REJECTED: 'Join request rejected successfully.',
  CAPTAIN_ASSIGNED: 'Captain assigned successfully.',
  VICE_CAPTAIN_ASSIGNED: 'Vice captain assigned successfully.',
  WICKETKEEPER_ASSIGNED: 'Wicketkeeper assigned successfully.',
  ONLY_OWNER: 'Only team owner can perform this operation.',
};

export const TOURNAMENT_MESSAGES = {
  CREATED: 'Tournament created successfully.',
  UPDATED: 'Tournament updated successfully.',
  DELETED: 'Tournament deleted successfully.',
  FETCHED: 'Tournament retrieved successfully.',
  NOT_FOUND: 'Tournament not found.',
  REGISTRATION_OPENED: 'Registration has been opened for the tournament.',
  REGISTRATION_CLOSED: 'Registration has been closed for the tournament.',
  REGISTRATION_SUCCESS: 'Team registration submitted successfully.',
  TEAM_APPROVED: 'Team registration approved.',
  TEAM_REJECTED: 'Team registration rejected.',
  MAX_TEAMS_REACHED: 'Tournament has reached maximum registered teams limit.',
  NOT_REGISTRATION_WINDOW: 'Registration is not currently open for this tournament.',
  ALREADY_REGISTERED: 'This team is already registered for this tournament.',
  STANDINGS_FETCHED: 'Tournament standings retrieved successfully.',
  SCHEDULE_FETCHED: 'Tournament schedule retrieved successfully.',
  STATUS_UPDATED: 'Tournament status updated successfully.',
};

export const MATCH_MESSAGES = {
  CREATED: 'Match created and scheduled successfully.',
  UPDATED: 'Match details updated successfully.',
  DELETED: 'Match deleted successfully.',
  FETCHED: 'Match details retrieved successfully.',
  NOT_FOUND: 'Match not found.',
  TOSS_RECORDED: 'Toss result recorded successfully.',
  PLAYING_XI_SUBMITTED: 'Playing XI submitted successfully.',
  STATUS_UPDATED: 'Match status updated successfully.',
  COMPLETED: 'Match completed successfully.',
  ABANDONED: 'Match abandoned.',
  ALREADY_STARTED: 'Match has already started.',
  NOT_IN_PROGRESS: 'Match is not currently in progress.',
  INVALID_TEAMS: 'Teams for the match must be different.',
  PLAYER_NOT_IN_TEAM: 'One or more selected players are not part of the team roster.',
};

export const SCORING_MESSAGES = {
  BALL_RECORDED: 'Delivery recorded successfully.',
  BALL_UNDONE: 'Last delivery undone successfully.',
  INNINGS_STARTED: 'Innings started successfully.',
  INNINGS_COMPLETED: 'Innings marked as completed.',
  MATCH_RESULT_CALCULATED: 'Match result calculated and updated.',
  INVALID_BATTER: 'Selected batter is not eligible to bat.',
  INVALID_BOWLER: 'Selected bowler cannot bowl consecutive overs.',
  OVERS_COMPLETED: 'Maximum overs for the innings have already been bowled.',
  ALL_OUT: 'Innings terminated: All wickets have fallen.',
  TARGET_REACHED: 'Target has been reached. Match concluded.',
  DELIVERY_NOT_FOUND: 'Delivery record not found.',
  CANNOT_UNDO: 'Cannot undo past delivery at this stage.',
  DUPLICATE_DELIVERY: 'Duplicate delivery request detected.',
};

export const AUCTION_MESSAGES = {
  CREATED: 'Auction created successfully.',
  UPDATED: 'Auction updated successfully.',
  FETCHED: 'Auction details retrieved successfully.',
  NOT_FOUND: 'Auction not found.',
  STARTED: 'Auction started and live.',
  PAUSED: 'Auction paused.',
  COMPLETED: 'Auction completed.',
  PLAYER_ADDED: 'Player added to auction pool.',
  PLAYER_REMOVED: 'Player removed from auction pool.',
  PLAYER_BROUGHT_FORWARD: 'Player brought forward for bidding.',
  BID_PLACED: 'Bid placed successfully.',
  BID_TOO_LOW: 'Bid amount must exceed current highest bid by minimum increment.',
  INSUFFICIENT_PURSE: 'Team does not have sufficient purse balance.',
  PLAYER_SOLD: 'Player sold successfully.',
  PLAYER_UNSOLD: 'Player marked as unsold.',
  NOT_ACTIVE: 'Auction is not currently live.',
  TEAM_SLOTS_FULL: 'Team squad limit has already been reached.',
};

export const NOTIFICATION_MESSAGES = {
  FETCHED: 'Notifications retrieved successfully.',
  MARKED_READ: 'Notification marked as read.',
  ALL_MARKED_READ: 'All notifications marked as read.',
  NOT_FOUND: 'Notification not found.',
};

export const COMMON_MESSAGES = {
  SERVER_ERROR: 'An unexpected internal server error occurred.',
  VALIDATION_ERROR: 'Request validation failed.',
  NOT_FOUND: 'Requested resource was not found.',
  BAD_REQUEST: 'Bad request syntax or invalid parameters.',
  SUCCESS: 'Operation completed successfully.',
  CREATED: 'Resource created successfully.',
  FILE_UPLOADED: 'File uploaded successfully.',
  INVALID_FILE_TYPE: 'Invalid file format. Only image files (jpg, jpeg, png, webp) are allowed.',
  FILE_TOO_LARGE: 'File size exceeds maximum allowed limit.',
  RATE_LIMIT_EXCEEDED: 'Too many requests from this IP, please try again later.',
};

export const MESSAGES = {
  AUTH: AUTH_MESSAGES,
  PLAYER: PLAYER_MESSAGES,
  TEAM: TEAM_MESSAGES,
  TOURNAMENT: TOURNAMENT_MESSAGES,
  MATCH: MATCH_MESSAGES,
  SCORING: SCORING_MESSAGES,
  AUCTION: AUCTION_MESSAGES,
  NOTIFICATION: NOTIFICATION_MESSAGES,
  COMMON: COMMON_MESSAGES,
};

export default MESSAGES;
