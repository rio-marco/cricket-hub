import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';

// Real Feature Screen Imports
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/teams/presentation/screens/teams_screen.dart';
import '../../features/teams/presentation/screens/create_team_screen.dart';
import '../../features/teams/presentation/screens/team_detail_screen.dart';
import '../../features/players/presentation/screens/player_list_screen.dart';
import '../../features/players/presentation/screens/player_detail_screen.dart';
import '../../features/players/presentation/screens/create_player_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/tournaments/presentation/screens/tournaments_screen.dart';
import '../../features/tournaments/presentation/screens/create_tournament_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_detail_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/matches/presentation/screens/create_match_screen.dart';
import '../../features/matches/presentation/screens/match_detail_screen.dart';
import '../../features/matches/presentation/screens/toss_screen.dart';
import '../../features/matches/presentation/screens/live_scoring_screen.dart' as live_scoring;
import '../../features/matches/presentation/screens/full_scorecard_screen.dart' as full_scorecard;
import '../../features/auction/presentation/screens/auctions_screen.dart';
import '../../features/auction/presentation/screens/create_auction_screen.dart';
import '../../features/auction/presentation/screens/auction_detail_screen.dart';
import '../../features/auction/presentation/screens/auction_bidding_screen.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bottom_nav_bar.dart';

// -----------------------------------------------------------------------------
// Route Names & Paths
// -----------------------------------------------------------------------------
class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Bottom Nav Shell Routes
  static const String home = '/home';
  static const String matches = '/matches';
  static const String tournaments = '/tournaments';
  static const String teams = '/teams';
  static const String profile = '/profile';

  // Feature Routes
  static const String createTeam = '/teams/create';
  static const String teamDetail = '/teams/:id';
  static const String players = '/players';
  static const String createPlayer = '/players/create';
  static const String playerDetail = '/players/:id';
  static const String createTournament = '/tournaments/create';
  static const String tournamentDetail = '/tournaments/:id';
  static const String createMatch = '/matches/create';
  static const String matchDetail = '/matches/:id';
  static const String matchToss = '/matches/:id/toss';
  static const String matchScoring = '/matches/:id/scoring';
  static const String matchScorecard = '/matches/:id/scorecard';
  static const String statistics = '/statistics';
  static const String auctions = '/auctions';
  static const String createAuction = '/auctions/create';
  static const String auctionDetail = '/auctions/:id';
  static const String auctionBidding = '/auctions/:id/bidding';
  static const String leaderboard = '/leaderboard';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
}

// -----------------------------------------------------------------------------
// GoRouter Provider & Navigation Graph
// -----------------------------------------------------------------------------
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _ListenableAdapter(authNotifier),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final isAuth = authState is Authenticated;
      final isInitial = authState is AuthInitial || authState is AuthLoading;
      final location = state.uri.path;

      // Allow splash to perform initialization check
      if (isInitial && location != AppRoutes.splash) {
        return AppRoutes.splash;
      }

      // Public authentication and onboarding routes
      final isPublicRoute = location == AppRoutes.splash ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.verifyOtp ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.resetPassword;

      // Not logged in -> send to login screen
      if (!isAuth && !isPublicRoute) {
        return AppRoutes.login;
      }

      // Logged in user attempting to visit auth pages -> redirect to home
      if (isAuth &&
          (location == AppRoutes.login ||
              location == AppRoutes.register ||
              location == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // -----------------------------------------------------------------------
      // Public / Auth Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verifyOtp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationScreen(
            destination: extra?['email'] ?? extra?['phone'],
            userId: extra?['userId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResetPasswordScreen(
            userId: extra?['userId'],
            initialOtp: extra?['otp'],
          );
        },
      ),

      // -----------------------------------------------------------------------
      // Main Application Shell Route with Bottom Navigation
      // -----------------------------------------------------------------------
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          final currentPath = state.uri.path;
          int currentIndex = 0;
          if (currentPath.startsWith(AppRoutes.home)) {
            currentIndex = 0;
          } else if (currentPath.startsWith(AppRoutes.matches)) {
            currentIndex = 1;
          } else if (currentPath.startsWith(AppRoutes.tournaments)) {
            currentIndex = 2;
          } else if (currentPath.startsWith(AppRoutes.teams)) {
            currentIndex = 3;
          } else if (currentPath.startsWith(AppRoutes.profile)) {
            currentIndex = 4;
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: CricketBottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go(AppRoutes.home);
                    break;
                  case 1:
                    context.go(AppRoutes.matches);
                    break;
                  case 2:
                    context.go(AppRoutes.tournaments);
                    break;
                  case 3:
                    context.go(AppRoutes.teams);
                    break;
                  case 4:
                    context.go(AppRoutes.profile);
                    break;
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.matches,
            name: 'matches',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MatchesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.tournaments,
            name: 'tournaments',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TournamentsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.teams,
            name: 'teams',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TeamsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // -----------------------------------------------------------------------
      // Teams Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.createTeam,
        name: 'createTeam',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: AppRoutes.teamDetail,
        name: 'teamDetail',
        builder: (context, state) => TeamDetailScreen(
          teamId: state.pathParameters['id'] ?? '',
        ),
      ),

      // -----------------------------------------------------------------------
      // Players Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.createPlayer,
        name: 'createPlayer',
        builder: (context, state) => const CreatePlayerScreen(),
      ),
      GoRoute(
        path: AppRoutes.players,
        name: 'players',
        builder: (context, state) => const PlayerListScreen(),
      ),
      GoRoute(
        path: AppRoutes.playerDetail,
        name: 'playerDetail',
        builder: (context, state) => PlayerDetailScreen(
          playerId: state.pathParameters['id'] ?? '',
        ),
      ),

      // -----------------------------------------------------------------------
      // Tournaments Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.createTournament,
        name: 'createTournament',
        builder: (context, state) => const CreateTournamentScreen(),
      ),
      GoRoute(
        path: AppRoutes.tournamentDetail,
        name: 'tournamentDetail',
        builder: (context, state) => TournamentDetailScreen(
          tournamentId: state.pathParameters['id'] ?? '',
        ),
      ),

      // -----------------------------------------------------------------------
      // Matches & Live Scoring Routes
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.createMatch,
        name: 'createMatch',
        builder: (context, state) => const CreateMatchScreen(),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        name: 'matchDetail',
        builder: (context, state) => MatchDetailScreen(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.matchToss,
        name: 'matchToss',
        builder: (context, state) => TossScreen(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.matchScoring,
        name: 'matchScoring',
        builder: (context, state) => live_scoring.LiveScoringScreen(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.matchScorecard,
        name: 'matchScorecard',
        builder: (context, state) => full_scorecard.FullScorecardScreen(
          matchId: state.pathParameters['id'] ?? '',
        ),
      ),

      // -----------------------------------------------------------------------
      // Statistics, Auctions, Leaderboard & Settings
      // -----------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.auctions,
        name: 'auctions',
        builder: (context, state) => const AuctionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAuction,
        name: 'createAuction',
        builder: (context, state) => const CreateAuctionScreen(),
      ),
      GoRoute(
        path: AppRoutes.auctionDetail,
        name: 'auctionDetail',
        builder: (context, state) => AuctionDetailScreen(
          auctionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.auctionBidding,
        name: 'auctionBidding',
        builder: (context, state) => AuctionBiddingScreen(
          auctionId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

/// Listenable adapter wrapping StateNotifier for GoRouter refreshListenable.
class _ListenableAdapter extends ChangeNotifier {
  final StateNotifier<dynamic> _notifier;

  _ListenableAdapter(this._notifier) {
    _notifier.addListener((_) {
      notifyListeners();
    });
  }
}

// =============================================================================
// Placeholder Screen Implementations (Designed with Cricket Hub Design System)
// =============================================================================

class _CricketScreenTemplate extends StatelessWidget {
  final String title;
  final String routePath;
  final IconData icon;
  final String? subtitle;
  final List<Widget>? extraContent;

  const _CricketScreenTemplate({
    required this.title,
    required this.routePath,
    required this.icon,
    this.subtitle,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: title,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppCard(
                hasGradientHeader: true,
                headerTitle: title,
                headerSubtitle: 'Route: $routePath',
                headerLeading: Icon(icon, color: Colors.white, size: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: (isDark
                              ? AppTextStyles.headlineSmallDark
                              : AppTextStyles.headlineSmallLight)
                          .copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle ??
                          'This module is part of Cricket Hub architecture. Complete UI screen coming in the next feature iteration.',
                      style: isDark
                          ? AppTextStyles.bodyMediumDark
                          : AppTextStyles.bodyMediumLight,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Coming Soon',
                        style: AppTextStyles.labelMediumLight.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (extraContent != null) ...[
                      const SizedBox(height: 16),
                      ...extraContent!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Application Feature Screens
// -----------------------------------------------------------------------------


class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CricketScreenTemplate(
      title: 'Statistics & Analytics',
      routePath: AppRoutes.statistics,
      icon: Icons.bar_chart_rounded,
      subtitle: 'Top run scorers, wicket takers, strike rates, and team comparisons.',
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CricketScreenTemplate(
      title: 'Leaderboard',
      routePath: AppRoutes.leaderboard,
      icon: Icons.leaderboard_rounded,
      subtitle: 'Orange Cap, Purple Cap, Most Valuable Player, and team rankings.',
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CricketScreenTemplate(
      title: 'Notifications',
      routePath: AppRoutes.notifications,
      icon: Icons.notifications_active_outlined,
      subtitle: 'Match reminders, team invitations, auction alerts, and scores.',
    );
  }
}

