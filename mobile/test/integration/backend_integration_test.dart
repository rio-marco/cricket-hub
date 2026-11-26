import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mobile/features/matches/data/datasources/match_remote_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mobile/features/players/data/datasources/player_remote_datasource.dart';
import 'package:mobile/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:mobile/features/statistics/domain/entities/statistics_filter.dart';
import 'package:mobile/features/teams/data/datasources/team_remote_datasource.dart';
import 'package:mobile/features/tournaments/data/datasources/tournament_remote_datasource.dart';

class _VerifiedUser {
  final String id;
  final String email;
  final String password;
  final String accessToken;
  final String refreshToken;

  const _VerifiedUser({
    required this.id,
    required this.email,
    required this.password,
    required this.accessToken,
    required this.refreshToken,
  });
}

void main() {
  const baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:5001/api/v1',
  );

  late Dio dio;
  late ApiClient apiClient;
  late AuthRemoteDataSource auth;
  late PlayerRemoteDataSource players;
  late TeamRemoteDataSource teams;
  late TournamentRemoteDataSource tournaments;
  late MatchRemoteDataSource matches;
  late NotificationsRemoteDataSource notifications;
  late StatisticsRemoteDataSource statistics;

  Map<String, dynamic> dataOf(dynamic body) {
    final envelope = Map<String, dynamic>.from(body as Map);
    return Map<String, dynamic>.from(envelope['data'] as Map);
  }

  Future<_VerifiedUser> registerAndVerify(String prefix) async {
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final email = '$prefix.$stamp@example.com';
    final password = 'StrongPass123!';
    final registration = await dio.post(
      '/auth/register',
      data: {
        'name': '$prefix $stamp',
        'email': email,
        'password': password,
      },
    );
    final registered = dataOf(registration.data);
    final userId = registered['userId'] as String;
    final otp = registered['otp'] as String;
    expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);

    final verified = await auth.verifyOTP(userId, otp);
    final tokens = dataOf(verified)['tokens'] as Map<String, dynamic>;

    return _VerifiedUser(
      id: userId,
      email: email,
      password: password,
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
  }

  void authenticate(_VerifiedUser user) {
    dio.options.headers[HttpHeaders.authorizationHeader] =
        'Bearer ${user.accessToken}';
  }

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );
    apiClient = ApiClient(
      config: AppConfig.development(customBaseUrl: baseUrl),
      storage: SecureStorage(const FlutterSecureStorage()),
      dio: dio,
    );
    auth = AuthRemoteDataSourceImpl(dio);
    players = PlayerRemoteDataSourceImpl(dio);
    teams = TeamRemoteDataSourceImpl(dio);
    tournaments = TournamentRemoteDataSourceImpl(dio);
    matches = MatchRemoteDataSourceImpl(dio);
    notifications = NotificationsRemoteDataSourceImpl(apiClient);
    statistics = StatisticsRemoteDataSource(apiClient);
  });

  tearDownAll(() {
    dio.close();
  });

  test(
    'real backend integration flow persists auth, players, teams, tournaments and matches',
    () async {
      final organizer = await registerAndVerify('flutter-organizer');
      final ownerA = await registerAndVerify('flutter-owner-a');
      final ownerB = await registerAndVerify('flutter-owner-b');

      final login = await auth.login(organizer.email, organizer.password);
      expect(login.accessToken, isNotEmpty);
      expect(login.refreshToken, isNotEmpty);
      final refreshed = await auth.refreshToken(login.refreshToken);
      expect(refreshed.accessToken, isNotEmpty);
      expect(refreshed.accessToken, isNot(login.accessToken));

      authenticate(organizer);
      final profile = await auth.getProfile();
      expect(profile.id, organizer.id);

      final playerName = 'Flutter Player ${DateTime.now().microsecondsSinceEpoch}';
      final player = await players.createPlayer({
        'playingRole': 'BATSMAN',
        'battingStyle': 'RIGHT_HAND',
        'city': 'Integration City',
        'bio': playerName,
      });
      expect(player.id, isNotEmpty);
      expect(player.user, organizer.id);

      final foundPlayers = await players.getPlayers(search: playerName);
      expect(foundPlayers.items.any((item) => item.id == player.id), isTrue);

      final playerStats = await statistics.getPlayerStatistics(player.id);
      expect(playerStats.playerId, player.id);
      expect(playerStats.matches, 0);
      expect(playerStats.batting.runs, 0);

      final overview = await statistics.getOverview();
      expect(overview.topBatsmen.length, lessThanOrEqualTo(5));
      expect(overview.topBowlers.length, lessThanOrEqualTo(5));
      expect(overview.topFielders.length, lessThanOrEqualTo(5));

      final leaderboard = await statistics.getLeaderboard(
        metric: 'runs',
        limit: 5,
      );
      expect(leaderboard.page, 1);
      expect(leaderboard.limit, 5);
      expect(leaderboard.items.length, lessThanOrEqualTo(5));
      expect(leaderboard.items.every((item) => item.metric == 'runs'), isTrue);

      authenticate(ownerA);
      final teamA = await teams.createTeam(
        name: 'Flutter A ${DateTime.now().microsecondsSinceEpoch}',
        location: 'Integration Ground A',
      );
      expect(teamA.id, isNotEmpty);

      authenticate(ownerB);
      final teamB = await teams.createTeam(
        name: 'Flutter B ${DateTime.now().microsecondsSinceEpoch}',
        location: 'Integration Ground B',
      );
      expect(teamB.id, isNotEmpty);
      expect(teamB.id, isNot(teamA.id));

      final now = DateTime.now().toUtc();
      authenticate(organizer);
      final tournament = await tournaments.createTournament({
        'name': 'Flutter League ${now.microsecondsSinceEpoch}',
        'format': 'LEAGUE',
        'ballType': 'WHITE',
        'matchFormat': 'T20',
        'venues': ['Integration Ground'],
        'city': 'Integration City',
        'startDate': now.add(const Duration(days: 1)).toIso8601String(),
        'endDate': now.add(const Duration(days: 7)).toIso8601String(),
        'registrationStartDate':
            now.subtract(const Duration(minutes: 1)).toIso8601String(),
        'registrationEndDate': now.add(const Duration(days: 1)).toIso8601String(),
        'maxTeams': 4,
        'maxPlayersPerTeam': 15,
        'registrationFee': 0,
      });
      expect(tournament.id, isNotEmpty);

      final tournamentOverview = await statistics.getOverview(
        filter: StatisticsFilter(tournamentId: tournament.id, format: 'T20'),
      );
      expect(tournamentOverview.filters.tournamentId, tournament.id);
      expect(tournamentOverview.filters.format, 'T20');

      final opened = await tournaments.updateTournamentStatus(
        tournament.id,
        'REGISTRATION_OPEN',
      );
      expect(opened.status, 'REGISTRATION_OPEN');

      authenticate(ownerA);
      final registeredA =
          await tournaments.registerTeam(tournament.id, teamA.id);
      authenticate(ownerB);
      final registeredB =
          await tournaments.registerTeam(tournament.id, teamB.id);

      authenticate(organizer);
      final registeredTeams =
          await tournaments.getRegisteredTeams(tournament.id);
      expect(registeredTeams.length, 2);
      await tournaments.approveTeam(tournament.id, registeredA.id);
      await tournaments.approveTeam(tournament.id, registeredB.id);

      authenticate(ownerA);
      final myNotifications = await notifications.getNotifications();
      expect(
        myNotifications.items.any(
          (item) => item.type == 'TOURNAMENT_REGISTRATION_APPROVED',
        ),
        isTrue,
      );
      final unreadCount = await notifications.getUnreadCount();
      expect(unreadCount, greaterThan(0));
      final firstUnread = myNotifications.items.firstWhere(
        (item) => !item.isRead,
      );
      final markedNotification = await notifications.markAsRead(firstUnread.id);
      expect(markedNotification.isRead, isTrue);
      expect(markedNotification.readAt, isNotNull);

      final preferences = await notifications.getPreferences();
      final updatedPreferences = await notifications.updatePreferences(
        preferences.copyWith(auctionUpdates: false),
      );
      expect(updatedPreferences.auctionUpdates, isFalse);

      final pushToken = 'flutter-fcm-${now.microsecondsSinceEpoch}';
      await notifications.registerDeviceToken(
        token: pushToken,
        platform: 'ANDROID',
        deviceId: 'flutter-integration-device',
        appVersion: '1.0.0+1',
      );
      await notifications.removeDeviceToken(pushToken);

      authenticate(organizer);
      final fixtures = await tournaments.generateFixtures(tournament.id);
      expect(fixtures, hasLength(1));
      final persistedFixtures = await tournaments.getFixtures(tournament.id);
      expect(persistedFixtures, hasLength(1));

      authenticate(ownerA);
      final match = await matches.createMatch({
        'title': 'Flutter Match ${now.microsecondsSinceEpoch}',
        'teamA': teamA.id,
        'teamB': teamB.id,
        'format': 'T20',
        'totalOvers': 20,
        'ballType': 'WHITE',
        'venue': 'Integration Ground',
      });
      expect(match.id, isNotEmpty);

      final listed = await matches.getMatches(teamId: teamA.id, status: 'UPCOMING');
      expect(listed.any((item) => item.id == match.id), isTrue);

      final tossed = await matches.recordToss(match.id, teamA.id, 'BAT');
      expect(tossed.toss?.decision, 'BAT');

      final stored = await matches.getMatchById(match.id);
      expect(stored.id, match.id);
      expect(stored.status.toUpperCase(), isNot('UPCOMING'));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
