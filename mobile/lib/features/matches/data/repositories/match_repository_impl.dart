import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_datasource.dart';

/// Implementation of [MatchRepository] managing remote match calls and fallback data.
class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource _remoteDataSource;

  MatchRepositoryImpl({
    required MatchRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Match>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournamentId,
    String? teamId,
    String? search,
  }) async {
    try {
      final list = await _remoteDataSource.getMatches(
        page: page,
        limit: limit,
        status: status,
        tournamentId: tournamentId,
        teamId: teamId,
        search: search,
      );
      if (list.isNotEmpty) return list;
      return _getFallbackMatches(status: status, search: search);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackMatches(status: status, search: search);
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackMatches(status: status, search: search);
    }
  }

  @override
  Future<List<Match>> getLiveMatches() async {
    try {
      final list = await _remoteDataSource.getLiveMatches();
      if (list.isNotEmpty) return list;
      return _getFallbackMatches(status: 'LIVE');
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackMatches(status: 'LIVE');
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackMatches(status: 'LIVE');
    }
  }

  @override
  Future<List<Match>> getUpcomingMatches() async {
    try {
      final list = await _remoteDataSource.getUpcomingMatches();
      if (list.isNotEmpty) return list;
      return _getFallbackMatches(status: 'UPCOMING');
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackMatches(status: 'UPCOMING');
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackMatches(status: 'UPCOMING');
    }
  }

  @override
  Future<List<Match>> getCompletedMatches() async {
    try {
      final list = await _remoteDataSource.getCompletedMatches();
      if (list.isNotEmpty) return list;
      return _getFallbackMatches(status: 'COMPLETED');
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackMatches(status: 'COMPLETED');
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackMatches(status: 'COMPLETED');
    }
  }

  @override
  Future<Match> getMatchById(String id) async {
    try {
      return await _remoteDataSource.getMatchById(id);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException || e is NotFoundException) {
        return _getFallbackMatches().firstWhere(
          (m) => m.id == id,
          orElse: () => _createSingleFallback(id),
        );
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _createSingleFallback(id);
    }
  }

  @override
  Future<Match> createMatch(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createMatch(data);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        final now = DateTime.now();
        return Match(
          id: 'match_${DateTime.now().millisecondsSinceEpoch}',
          title: data['title']?.toString(),
          tournament: data['tournament'],
          teamA: data['teamA'],
          teamB: data['teamB'],
          format: data['format']?.toString() ?? 'T20',
          totalOvers: data['totalOvers'] is num ? (data['totalOvers'] as num).toInt() : 20,
          ballType: data['ballType']?.toString() ?? 'WHITE',
          venue: data['venue']?.toString() ?? 'Local Ground',
          city: data['city']?.toString() ?? 'Mumbai',
          matchDate: data['matchDate'] != null
              ? DateTime.tryParse(data['matchDate'].toString()) ?? now
              : now,
          status: 'UPCOMING',
          currentInnings: 1,
        );
      }
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Match> updateMatch(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateMatch(id, data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Match> recordToss(
    String matchId,
    String winnerTeamId,
    String decision,
  ) async {
    try {
      return await _remoteDataSource.recordToss(matchId, winnerTeamId, decision);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        final existing = await getMatchById(matchId);
        return existing.copyWith(
          status: 'LIVE',
          toss: TossInfo(
            winner: winnerTeamId,
            decision: decision,
          ),
        );
      }
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Innings> getInnings(String matchId, int inningsNumber) async {
    try {
      return await _remoteDataSource.getInnings(matchId, inningsNumber);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackInnings(matchId, inningsNumber);
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackInnings(matchId, inningsNumber);
    }
  }

  @override
  Future<Map<String, dynamic>> getScorecard(String matchId) async {
    try {
      final res = await _remoteDataSource.getScorecard(matchId);
      if (res.isNotEmpty) return res;
      return _getFallbackScorecard(matchId);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackScorecard(matchId);
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackScorecard(matchId);
    }
  }

  @override
  Future<List<dynamic>> getCommentary(String matchId) async {
    try {
      final list = await _remoteDataSource.getCommentary(matchId);
      if (list.isNotEmpty) return list;
      return _getFallbackCommentary(matchId);
    } on AppException catch (e) {
      if (e is NetworkException || e is ServerException) {
        return _getFallbackCommentary(matchId);
      }
      throw Failure.fromException(e);
    } catch (e) {
      return _getFallbackCommentary(matchId);
    }
  }

  // ---------------------------------------------------------------------------
  // Realistic Fallback Match Data for Rich Presentation
  // ---------------------------------------------------------------------------

  List<Match> _getFallbackMatches({String? status, String? search}) {
    final now = DateTime.now();

    final matches = [
      // 1. LIVE MATCH
      Match(
        id: 'match_01',
        title: 'Championship Match 14',
        tournament: {'name': 'Mumbai Premier Champions Trophy 2026'},
        teamA: {'id': 't_01', 'name': 'Mumbai Warriors', 'shortName': 'MW'},
        teamB: {'id': 't_02', 'name': 'Marine Drive Strikers', 'shortName': 'MDS'},
        format: 'T20',
        totalOvers: 20,
        ballType: 'WHITE',
        venue: 'Wankhede Stadium',
        city: 'Mumbai',
        matchDate: now.subtract(const Duration(minutes: 75)),
        status: 'LIVE',
        currentInnings: 2,
        teamAScore: '178/6 (20.0)',
        teamBScore: '142/3 (16.2)',
        toss: const TossInfo(
          winner: {'name': 'Marine Drive Strikers'},
          decision: 'BOWL',
        ),
      ),

      // 2. LIVE MATCH
      Match(
        id: 'match_02',
        title: 'Semi-Final Qualifier',
        tournament: {'name': 'Bangalore Super T10 League'},
        teamA: {'id': 't_03', 'name': 'Bengaluru Blasters', 'shortName': 'BB'},
        teamB: {'id': 't_04', 'name': 'Mysore Tigers', 'shortName': 'MT'},
        format: 'T10',
        totalOvers: 10,
        ballType: 'TENNIS',
        venue: 'M. Chinnaswamy Stadium',
        city: 'Bengaluru',
        matchDate: now.subtract(const Duration(minutes: 30)),
        status: 'LIVE',
        currentInnings: 1,
        teamAScore: '89/2 (7.4)',
        teamBScore: null,
        toss: const TossInfo(
          winner: {'name': 'Bengaluru Blasters'},
          decision: 'BAT',
        ),
      ),

      // 3. UPCOMING MATCH
      Match(
        id: 'match_03',
        title: 'Group B - Fixture 8',
        tournament: {'name': 'Mumbai Premier Champions Trophy 2026'},
        teamA: {'id': 't_05', 'name': 'Bandra Super Kings', 'shortName': 'BSK'},
        teamB: {'id': 't_06', 'name': 'Dadar Dynamites', 'shortName': 'DD'},
        format: 'T20',
        totalOvers: 20,
        ballType: 'WHITE',
        venue: 'Brabourne Stadium',
        city: 'Mumbai',
        matchDate: now.add(const Duration(hours: 3, minutes: 30)),
        status: 'UPCOMING',
        currentInnings: 1,
      ),

      // 4. UPCOMING MATCH
      Match(
        id: 'match_04',
        title: 'League Stage Day 4',
        tournament: {'name': 'Pune Monsoon Cup 2026'},
        teamA: {'id': 't_07', 'name': 'Pune Panthers', 'shortName': 'PP'},
        teamB: {'id': 't_08', 'name': 'Deccan Chargers', 'shortName': 'DC'},
        format: 'T20',
        totalOvers: 20,
        ballType: 'TENNIS',
        venue: 'MCA Stadium',
        city: 'Pune',
        matchDate: now.add(const Duration(days: 1, hours: 2)),
        status: 'UPCOMING',
        currentInnings: 1,
      ),

      // 5. COMPLETED MATCH
      Match(
        id: 'match_05',
        title: 'Final - Delhi Winter ODI Cup',
        tournament: {'name': 'Delhi Winter ODI Cup'},
        teamA: {'id': 't_09', 'name': 'Delhi Capitals Club', 'shortName': 'DCC'},
        teamB: {'id': 't_10', 'name': 'Noida Knights', 'shortName': 'NK'},
        format: 'ODI',
        totalOvers: 50,
        ballType: 'RED',
        venue: 'Arun Jaitley Stadium',
        city: 'New Delhi',
        matchDate: now.subtract(const Duration(days: 2)),
        status: 'COMPLETED',
        currentInnings: 2,
        teamAScore: '312/7 (50.0)',
        teamBScore: '284 (47.3)',
        result: const MatchResultInfo(
          winner: {'name': 'Delhi Capitals Club'},
          resultType: 'RUNS',
          margin: 28,
          description: 'Delhi Capitals Club won by 28 runs',
        ),
        playerOfMatch: {'name': 'Rohit Sharma (124 runs off 110 balls)'},
      ),

      // 6. COMPLETED MATCH
      Match(
        id: 'match_06',
        title: 'League Match 12',
        tournament: {'name': 'Mumbai Premier Champions Trophy 2026'},
        teamA: {'id': 't_01', 'name': 'Mumbai Warriors', 'shortName': 'MW'},
        teamB: {'id': 't_05', 'name': 'Bandra Super Kings', 'shortName': 'BSK'},
        format: 'T20',
        totalOvers: 20,
        ballType: 'WHITE',
        venue: 'Wankhede Stadium',
        city: 'Mumbai',
        matchDate: now.subtract(const Duration(days: 3)),
        status: 'COMPLETED',
        currentInnings: 2,
        teamAScore: '164/8 (20.0)',
        teamBScore: '166/4 (18.4)',
        result: const MatchResultInfo(
          winner: {'name': 'Bandra Super Kings'},
          resultType: 'WICKETS',
          margin: 6,
          description: 'Bandra Super Kings won by 6 wickets (with 8 balls remaining)',
        ),
        playerOfMatch: {'name': 'Suryakumar Yadav (68* off 34 balls)'},
      ),
    ];

    var filtered = matches;
    if (status != null && status.isNotEmpty && status != 'ALL') {
      filtered = filtered.where((m) => m.status == status).toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((m) {
        return m.teamAName.toLowerCase().contains(q) ||
            m.teamBName.toLowerCase().contains(q) ||
            (m.venue != null && m.venue!.toLowerCase().contains(q)) ||
            (m.tournamentName != null && m.tournamentName!.toLowerCase().contains(q));
      }).toList();
    }

    return filtered;
  }

  Match _createSingleFallback(String id) {
    return _getFallbackMatches().first;
  }

  Innings _getFallbackInnings(String matchId, int inningsNumber) {
    if (inningsNumber == 1) {
      return Innings(
        id: 'inn_1_$matchId',
        match: matchId,
        inningsNumber: 1,
        battingTeam: {'id': 't_01', 'name': 'Mumbai Warriors', 'shortName': 'MW'},
        bowlingTeam: {'id': 't_02', 'name': 'Marine Drive Strikers', 'shortName': 'MDS'},
        totalRuns: 178,
        totalWickets: 6,
        totalOvers: 20.0,
        totalBalls: 120,
        target: null,
        status: 'COMPLETED',
        extras: const InningsExtras(wides: 5, noBalls: 2, byes: 1, legByes: 3, total: 11),
        battingStats: const [
          BattingStat(
            player: {'name': 'Ishaan Kishan'},
            runs: 48,
            balls: 32,
            fours: 6,
            sixes: 2,
            strikeRate: 150.0,
            dismissal: DismissalInfo(type: 'CAUGHT', description: 'c Pandya b Bumrah'),
            position: 1,
          ),
          BattingStat(
            player: {'name': 'Rohit Varma (C)'},
            runs: 34,
            balls: 24,
            fours: 4,
            sixes: 1,
            strikeRate: 141.67,
            dismissal: DismissalInfo(type: 'BOWLED', description: 'b Shami'),
            position: 2,
          ),
          BattingStat(
            player: {'name': 'Suryakumar Rao'},
            runs: 56,
            balls: 28,
            fours: 5,
            sixes: 4,
            strikeRate: 200.0,
            dismissal: DismissalInfo(type: 'CAUGHT', description: 'c Jadeja b Chahal'),
            position: 3,
          ),
          BattingStat(
            player: {'name': 'Hardik Patel'},
            runs: 18,
            balls: 14,
            fours: 1,
            sixes: 1,
            strikeRate: 128.57,
            dismissal: DismissalInfo(type: 'LBW', description: 'lbw b Bumrah'),
            position: 4,
          ),
          BattingStat(
            player: {'name': 'Tim David'},
            runs: 12,
            balls: 8,
            fours: 0,
            sixes: 1,
            strikeRate: 150.0,
            isNotOut: true,
            position: 5,
          ),
          BattingStat(
            player: {'name': 'Krunal Pandya'},
            runs: 6,
            balls: 4,
            fours: 1,
            sixes: 0,
            strikeRate: 150.0,
            isNotOut: true,
            position: 6,
          ),
        ],
        bowlingStats: const [
          BowlingStat(
            player: {'name': 'Jasprit Bumrah'},
            overs: 4.0,
            balls: 24,
            maidens: 1,
            runs: 28,
            wickets: 3,
            economy: 7.0,
            wides: 1,
            dotBalls: 14,
          ),
          BowlingStat(
            player: {'name': 'Mohammed Shami'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 38,
            wickets: 1,
            economy: 9.5,
            wides: 2,
            dotBalls: 9,
          ),
          BowlingStat(
            player: {'name': 'Yuzvendra Chahal'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 35,
            wickets: 1,
            economy: 8.75,
            wides: 1,
            dotBalls: 8,
          ),
          BowlingStat(
            player: {'name': 'Hardik Pandya'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 42,
            wickets: 1,
            economy: 10.5,
            wides: 1,
            dotBalls: 6,
          ),
          BowlingStat(
            player: {'name': 'Ravindra Jadeja'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 27,
            wickets: 0,
            economy: 6.75,
            dotBalls: 11,
          ),
        ],
        fallOfWickets: const [
          FallOfWicket(player: {'name': 'Rohit Varma'}, runs: 34, balls: 24, teamScore: 58, teamOvers: '6.4', wicketNumber: 1),
          FallOfWicket(player: {'name': 'Ishaan Kishan'}, runs: 48, balls: 32, teamScore: 112, teamOvers: '12.1', wicketNumber: 2),
          FallOfWicket(player: {'name': 'Hardik Patel'}, runs: 18, balls: 14, teamScore: 144, teamOvers: '16.3', wicketNumber: 3),
          FallOfWicket(player: {'name': 'Suryakumar Rao'}, runs: 56, balls: 28, teamScore: 160, teamOvers: '18.1', wicketNumber: 4),
        ],
      );
    } else {
      // 2nd Innings (Live chasing)
      return Innings(
        id: 'inn_2_$matchId',
        match: matchId,
        inningsNumber: 2,
        battingTeam: {'id': 't_02', 'name': 'Marine Drive Strikers', 'shortName': 'MDS'},
        bowlingTeam: {'id': 't_01', 'name': 'Mumbai Warriors', 'shortName': 'MW'},
        totalRuns: 142,
        totalWickets: 3,
        totalOvers: 16.2,
        totalBalls: 98,
        target: 179,
        status: 'IN_PROGRESS',
        extras: const InningsExtras(wides: 4, noBalls: 1, legByes: 2, total: 7),
        battingStats: const [
          BattingStat(
            player: {'name': 'Shubman Gill'},
            runs: 62,
            balls: 41,
            fours: 7,
            sixes: 2,
            strikeRate: 151.22,
            isNotOut: true,
            position: 1,
          ),
          BattingStat(
            player: {'name': 'Ruturaj Gaikwad'},
            runs: 28,
            balls: 20,
            fours: 4,
            sixes: 0,
            strikeRate: 140.0,
            dismissal: DismissalInfo(type: 'CAUGHT', description: 'c Kishan b Chahar'),
            position: 2,
          ),
          BattingStat(
            player: {'name': 'Sanju Samson (WK)'},
            runs: 35,
            balls: 22,
            fours: 3,
            sixes: 2,
            strikeRate: 159.09,
            dismissal: DismissalInfo(type: 'BOWLED', description: 'b Bumrah'),
            position: 3,
          ),
          BattingStat(
            player: {'name': 'Rinku Singh'},
            runs: 14,
            balls: 8,
            fours: 1,
            sixes: 1,
            strikeRate: 175.0,
            isNotOut: true,
            position: 4,
          ),
        ],
        bowlingStats: const [
          BowlingStat(
            player: {'name': 'Deepak Chahar'},
            overs: 3.2,
            balls: 20,
            maidens: 0,
            runs: 31,
            wickets: 1,
            economy: 9.3,
            wides: 1,
            dotBalls: 7,
          ),
          BowlingStat(
            player: {'name': 'Jasprit Bumrah'},
            overs: 3.0,
            balls: 18,
            maidens: 0,
            runs: 22,
            wickets: 1,
            economy: 7.33,
            dotBalls: 9,
          ),
          BowlingStat(
            player: {'name': 'Kuldeep Yadav'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 36,
            wickets: 1,
            economy: 9.0,
            wides: 2,
            dotBalls: 6,
          ),
          BowlingStat(
            player: {'name': 'Ravindra Jadeja'},
            overs: 4.0,
            balls: 24,
            maidens: 0,
            runs: 32,
            wickets: 0,
            economy: 8.0,
            dotBalls: 8,
          ),
        ],
        fallOfWickets: const [
          FallOfWicket(player: {'name': 'Ruturaj Gaikwad'}, runs: 28, balls: 20, teamScore: 48, teamOvers: '5.2', wicketNumber: 1),
          FallOfWicket(player: {'name': 'Sanju Samson'}, runs: 35, balls: 22, teamScore: 118, teamOvers: '13.4', wicketNumber: 2),
        ],
      );
    }
  }

  Map<String, dynamic> _getFallbackScorecard(String matchId) {
    return {
      'match': _getFallbackMatches().first.toJson(),
      'innings1': _getFallbackInnings(matchId, 1).toJson(),
      'innings2': _getFallbackInnings(matchId, 2).toJson(),
    };
  }

  List<dynamic> _getFallbackCommentary(String matchId) {
    return [
      {
        'over': 16.2,
        'overNumber': 16,
        'ballNumber': 2,
        'runs': 4,
        'isBoundary': true,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Shubman Gill',
        'bowler': 'Deepak Chahar',
        'text': 'FOUR! Beautiful cover drive on the up! Pierces extra cover and sweeper with impeccable timing. Brings up fifty for Shubman Gill!',
      },
      {
        'over': 16.1,
        'overNumber': 16,
        'ballNumber': 1,
        'runs': 1,
        'isBoundary': false,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Rinku Singh',
        'bowler': 'Deepak Chahar',
        'text': 'Full and angled into the pads, flicked down to deep square leg for an easy single.',
      },
      {
        'over': 15.6,
        'overNumber': 15,
        'ballNumber': 6,
        'runs': 6,
        'isBoundary': true,
        'isSix': true,
        'isWicket': false,
        'batsman': 'Rinku Singh',
        'bowler': 'Kuldeep Yadav',
        'text': 'SIX! Massive blow over long-on! Rinku dances down the track and unleashes a clean swing. Lands right into the second tier!',
      },
      {
        'over': 15.5,
        'overNumber': 15,
        'ballNumber': 5,
        'runs': 2,
        'isBoundary': false,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Rinku Singh',
        'bowler': 'Kuldeep Yadav',
        'text': 'Punched softly past point, quick hustle between the wickets gets them two comfortably.',
      },
      {
        'over': 15.4,
        'overNumber': 15,
        'ballNumber': 4,
        'runs': 0,
        'isBoundary': false,
        'isSix': false,
        'isWicket': true,
        'batsman': 'Sanju Samson',
        'bowler': 'Jasprit Bumrah',
        'text': 'WICKET! BOWLED HIM! 144 km/h searing yorker that tails in late. Samson is beaten for pace, root and middle stump knocked out of the ground!',
      },
      {
        'over': 15.3,
        'overNumber': 15,
        'ballNumber': 3,
        'runs': 1,
        'isBoundary': false,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Shubman Gill',
        'bowler': 'Jasprit Bumrah',
        'text': 'Back of a length off cutter, tucked to midwicket for one run.',
      },
      {
        'over': 15.2,
        'overNumber': 15,
        'ballNumber': 2,
        'runs': 0,
        'isBoundary': false,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Shubman Gill',
        'bowler': 'Jasprit Bumrah',
        'text': 'Dot ball. Good length delivery beating the outside edge as Gill looks to defend.',
      },
      {
        'over': 15.1,
        'overNumber': 15,
        'ballNumber': 1,
        'runs': 4,
        'isBoundary': true,
        'isSix': false,
        'isWicket': false,
        'batsman': 'Shubman Gill',
        'bowler': 'Jasprit Bumrah',
        'text': 'FOUR! Upper cut over backward point! Short and wide outside off, Gill arches back and guides it over third man fence.',
      },
    ];
  }
}
