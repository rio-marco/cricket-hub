/// All API endpoint paths for the Cricket Hub backend services.
class ApiEndpoints {
  ApiEndpoints._();

  // ---------------------------------------------------------------------------
  // Authentication & User Profile
  // ---------------------------------------------------------------------------
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';
  static const String avatar = '/auth/avatar';

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------
  static const String users = '/users';
  static const String dashboardStats = '/users/dashboard/stats';
  static String userById(String id) => '/users/$id';

  // ---------------------------------------------------------------------------
  // Teams
  // ---------------------------------------------------------------------------
  static const String teams = '/teams';
  static const String userInvitations = '/teams/user/invitations';
  static String teamById(String id) => '/teams/$id';
  static String teamMembers(String id) => '/teams/$id/members';
  static String teamMemberById(String teamId, String memberId) =>
      '/teams/$teamId/members/$memberId';
  static String teamMemberRole(String teamId, String memberId) =>
      '/teams/$teamId/members/$memberId/role';
  static String teamInvite(String id) => '/teams/$id/invite';
  static String teamJoin(String id) => '/teams/$id/join';
  static String teamInvitations(String id) => '/teams/$id/invitations';
  static String respondToInvitation(String invitationId) =>
      '/teams/invitations/$invitationId';
  static String teamStats(String id) => '/teams/$id/stats';
  static String teamMatches(String id) => '/teams/$id/matches';

  // ---------------------------------------------------------------------------
  // Players
  // ---------------------------------------------------------------------------
  static const String players = '/players';
  static String playerById(String id) => '/players/$id';
  static String playerStats(String id) => '/players/$id/stats';
  static String playerTeams(String id) => '/players/$id/teams';
  static String playerMatches(String id) => '/players/$id/matches';

  // ---------------------------------------------------------------------------
  // Tournaments
  // ---------------------------------------------------------------------------
  static const String tournaments = '/tournaments';
  static String tournamentById(String id) => '/tournaments/$id';
  static String tournamentStatus(String id) => '/tournaments/$id/status';
  static String tournamentTeams(String id) => '/tournaments/$id/teams';
  static String tournamentTeamApprove(String tournamentId, String tournamentTeamId) =>
      '/tournaments/$tournamentId/teams/$tournamentTeamId/approve';
  static String tournamentTeamReject(String tournamentId, String tournamentTeamId) =>
      '/tournaments/$tournamentId/teams/$tournamentTeamId/reject';
  static String tournamentFixtures(String id) => '/tournaments/$id/fixtures';
  static String tournamentStandings(String id) => '/tournaments/$id/standings';
  static String tournamentStats(String id) => '/tournaments/$id/stats';

  // ---------------------------------------------------------------------------
  // Matches
  // ---------------------------------------------------------------------------
  static const String matches = '/matches';
  static const String liveMatches = '/matches/live';
  static const String upcomingMatches = '/matches/upcoming';
  static const String completedMatches = '/matches/completed';
  static String matchById(String id) => '/matches/$id';
  static String matchScorecard(String id) => '/matches/$id/scorecard';
  static String matchToss(String id) => '/matches/$id/toss';
  static String matchPlayingXi(String id) => '/matches/$id/playing-xi';
  static String matchScorer(String id) => '/matches/$id/scorer';
  static String matchStart(String id) => '/matches/$id/start';

  // ---------------------------------------------------------------------------
  // Scoring
  // ---------------------------------------------------------------------------
  static const String scoring = '/scoring';
  static String scoringByMatchId(String matchId) => '/scoring/$matchId';
  static String scoringState(String matchId) => '/scoring/$matchId/state';
  static String scoringInnings(String matchId, int inningsNumber) =>
      '/scoring/$matchId/innings/$inningsNumber';
  static String scoringCommentary(String matchId) => '/scoring/$matchId/commentary';
  static String scoringStartInnings(String matchId) =>
      '/scoring/$matchId/start-innings';
  static String scoringBall(String matchId) => '/scoring/$matchId/ball';
  static String scoringUndo(String matchId) => '/scoring/$matchId/undo';
  static String scoringCorrect(String matchId, String deliveryId) =>
      '/scoring/$matchId/ball/$deliveryId/correct';
  static String scoringWicket(String matchId) => '/scoring/$matchId/wicket';
  static String scoringExtras(String matchId) => '/scoring/$matchId/extras';
  static String scoringOverEnd(String matchId) => '/scoring/$matchId/over-end';
  static String scoringInningsEnd(String matchId) =>
      '/scoring/$matchId/innings-end';
  static String scoringComplete(String matchId) => '/scoring/$matchId/complete';

  // ---------------------------------------------------------------------------
  // Scorecards
  // ---------------------------------------------------------------------------
  static String scorecardByMatchId(String matchId) => matchScorecard(matchId);
  static String commentaryByMatchId(String matchId) => scoringCommentary(matchId);
  static String matchHighlights(String matchId) => matchScorecard(matchId);

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------
  static const String statistics = '/statistics';
  static const String topBatsmen = '/statistics/top-batsmen';
  static const String topBowlers = '/statistics/top-bowlers';
  static String tournamentStatistics(String tournamentId) =>
      '/statistics/tournament/$tournamentId';

  // ---------------------------------------------------------------------------
  // Auctions
  // ---------------------------------------------------------------------------
  static const String auctions = '/auctions';
  static String auctionById(String id) => '/auctions/$id';
  static String auctionPlayers(String id) => '/auctions/$id/players';
  static String auctionBid(String id) => '/auctions/$id/bid';
  static String auctionCurrentPlayer(String id) => '/auctions/$id/current-player';
  static String auctionTeamPurse(String id, String teamId) =>
      '/auctions/$id/teams/$teamId/purse';

  // ---------------------------------------------------------------------------
  // Leaderboards
  // ---------------------------------------------------------------------------
  static const String leaderboards = '/leaderboards';
  static const String batsmanLeaderboard = '/leaderboards/batsmen';
  static const String bowlerLeaderboard = '/leaderboards/bowlers';
  static const String teamLeaderboard = '/leaderboards/teams';
  static const String mvpLeaderboard = '/leaderboards/mvp';

  // ---------------------------------------------------------------------------
  // Notifications & Device Registration
  // ---------------------------------------------------------------------------
  static const String notifications = '/notifications';
  static String notificationById(String id) => '/notifications/$id';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerPushToken = '/notifications/device-token';
}
