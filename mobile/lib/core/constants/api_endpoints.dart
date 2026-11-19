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
  static const String avatar = '/auth/avatar';

  // ---------------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------------
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static String userSearch(String query) => '/users/search?q=$query';

  // ---------------------------------------------------------------------------
  // Teams
  // ---------------------------------------------------------------------------
  static const String teams = '/teams';
  static String teamById(String id) => '/teams/$id';
  static String teamMembers(String id) => '/teams/$id/members';
  static String teamMemberById(String teamId, String memberId) =>
      '/teams/$teamId/members/$memberId';
  static String teamInvite(String id) => '/teams/$id/invite';
  static String teamJoin(String id) => '/teams/$id/join';
  static String teamStats(String id) => '/teams/$id/stats';
  static String teamMatches(String id) => '/teams/$id/matches';

  // ---------------------------------------------------------------------------
  // Players
  // ---------------------------------------------------------------------------
  static const String players = '/players';
  static String playerById(String id) => '/players/$id';
  static String playerStats(String id) => '/players/$id/stats';
  static String playerMatches(String id) => '/players/$id/matches';
  static String playerSearch(String query) => '/players/search?q=$query';

  // ---------------------------------------------------------------------------
  // Tournaments
  // ---------------------------------------------------------------------------
  static const String tournaments = '/tournaments';
  static String tournamentById(String id) => '/tournaments/$id';
  static String tournamentTeams(String id) => '/tournaments/$id/teams';
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
  static String matchToss(String id) => '/matches/$id/toss';
  static String matchPlayingXi(String id) => '/matches/$id/playing-xi';
  static String matchStart(String id) => '/matches/$id/start';
  static String matchEnd(String id) => '/matches/$id/end';

  // ---------------------------------------------------------------------------
  // Scoring
  // ---------------------------------------------------------------------------
  static const String scoring = '/scoring';
  static String scoringByMatchId(String matchId) => '/scoring/$matchId';
  static String scoringBall(String matchId) => '/scoring/$matchId/ball';
  static String scoringUndo(String matchId) => '/scoring/$matchId/undo';
  static String scoringWicket(String matchId) => '/scoring/$matchId/wicket';
  static String scoringExtras(String matchId) => '/scoring/$matchId/extras';
  static String scoringOverEnd(String matchId) => '/scoring/$matchId/over-end';
  static String scoringInningsEnd(String matchId) =>
      '/scoring/$matchId/innings-end';

  // ---------------------------------------------------------------------------
  // Scorecards
  // ---------------------------------------------------------------------------
  static const String scorecards = '/scorecards';
  static String scorecardByMatchId(String matchId) => '/scorecards/$matchId';
  static String commentaryByMatchId(String matchId) =>
      '/scorecards/$matchId/commentary';
  static String matchHighlights(String matchId) =>
      '/scorecards/$matchId/highlights';

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
