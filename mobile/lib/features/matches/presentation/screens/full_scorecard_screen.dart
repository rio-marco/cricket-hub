import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';

import '../../domain/entities/scoring.dart';
import '../providers/scoring_provider.dart';
import '../widgets/commentary_item.dart';

class FullScorecardScreen extends ConsumerWidget {
  final String matchId;

  const FullScorecardScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scoringControllerProvider(matchId));
    final notifier = ref.read(scoringControllerProvider(matchId).notifier);
    final match = state.snapshot.match;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Scorecard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
        ],
      ),
      body: state.isLoading && match == null
          ? const LoadingWidget(message: 'Loading scorecard...')
          : match == null
              ? AppErrorWidget(
                  title: 'Unable to load scorecard',
                  message: state.errorMessage ?? 'Match data is unavailable.',
                  onRetry: notifier.load,
                )
              : RefreshIndicator(
                  onRefresh: notifier.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(match),
                      const SizedBox(height: 14),
                      if (state.snapshot.innings.isEmpty)
                        const EmptyStateWidget(
                          title: 'No innings recorded yet',
                          subtitle: 'Start scoring this match to build the scorecard.',
                        )
                      else
                        ...state.snapshot.innings.map(_buildInnings),
                      const SizedBox(height: 14),
                      _buildResult(state.snapshot),
                      const SizedBox(height: 14),
                      _buildCommentary(state.snapshot),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(ScoringMatch match) {
    return AppCard(
      hasGradientHeader: true,
      headerTitle: '${match.teamAName} vs ${match.teamBName}',
      headerSubtitle: '${match.format} • ${match.venue ?? 'Venue TBD'}',
      headerLeading: const Icon(Icons.sports_cricket_rounded, color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status: ${match.status}'),
          Text('Overs: ${match.totalOvers}'),
        ],
      ),
    );
  }

  Widget _buildInnings(dynamic value) {
    if (value is! Map) return const SizedBox.shrink();
    final inning = Map<String, dynamic>.from(value);
    final number = _int(inning['inningsNumber']);
    final batting = entityName(inning['battingTeam'], fallback: 'Batting team');
    final runs = _int(inning['totalRuns']);
    final wickets = _int(inning['totalWickets']);
    final balls = _int(inning['totalBalls']);
    final target = inning['target'];

    return AppCard(
      headerTitle: 'Innings $number • $batting',
      headerSubtitle: '${statusText(inning['status'])} • $runs/$wickets (${_overs(balls)} ov)',
      headerLeading: const Icon(Icons.scoreboard_rounded, color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (target is num)
            Text(
              'Target: ${target.toInt()}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          if (target is num) const SizedBox(height: 12),
          _buildStatsTable(
            'Batting',
            ['Batter', 'R', 'B', '4s', '6s', 'SR'],
            _rows(inning['battingStats'], (stat) => [
              entityName(stat['player'], fallback: 'Player'),
              '${_int(stat['runs'])}',
              '${_int(stat['balls'])}',
              '${_int(stat['fours'])}',
              '${_int(stat['sixes'])}',
              '${_num(stat['strikeRate']).toStringAsFixed(1)}',
            ]),
          ),
          const SizedBox(height: 14),
          _buildStatsTable(
            'Bowling',
            ['Bowler', 'O', 'R', 'W', 'Econ', 'Wd', 'Nb'],
            _rows(inning['bowlingStats'], (stat) => [
              entityName(stat['player'], fallback: 'Player'),
              _overs(_int(stat['balls'])),
              '${_int(stat['runs'])}',
              '${_int(stat['wickets'])}',
              _num(stat['economy']).toStringAsFixed(1),
              '${_int(stat['wides'])}',
              '${_int(stat['noBalls'])}',
            ]),
          ),
          const SizedBox(height: 14),
          _buildSimpleList(
            'Fall of Wickets',
            _rows(inning['fallOfWickets'], (fow) =>
              '${fow['teamScore']}-${fow['wicketNumber']} '
              '${entityName(fow['player'], fallback: 'Batter')} '
              '(${fow['teamOvers']} ov)'),
          ),
          const SizedBox(height: 14),
          _buildSimpleList(
            'Partnerships',
            _rows(inning['partnerships'], (partnership) =>
              '${entityName(partnership['batter1'], fallback: 'Batter')} & '
              '${entityName(partnership['batter2'], fallback: 'Batter')}: '
              '${_int(partnership['runs'])} runs (${_int(partnership['balls'])} balls)'),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(ScoringSnapshot snapshot) {
    final result = snapshot.result;
    if (result is! Map<String, dynamic> || result.isEmpty) {
      return const SizedBox.shrink();
    }
    return AppCard(
      headerTitle: 'Match Result',
      headerLeading: const Icon(Icons.emoji_events_rounded, color: AppColors.primary),
      child: Text(
        result['description']?.toString() ??
            '${result['winner']?.toString() ?? 'No result'} • ${result['method']?.toString() ?? ''}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildCommentary(ScoringSnapshot snapshot) {
    if (snapshot.deliveries.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No commentary yet',
        subtitle: 'Ball-by-ball commentary will appear here as deliveries are recorded.',
      );
    }
    return AppCard(
      headerTitle: 'Ball by Ball Commentary',
      headerLeading: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primary),
      child: Column(
        children: snapshot.deliveries
            .map(
              (delivery) => CommentaryItemWidget(
                delivery: {
                  'over': delivery.overLabel,
                  'runs': delivery.totalRuns,
                  'isBoundary': delivery.isBoundary,
                  'isSix': delivery.isSix,
                  'isWicket': delivery.isWicket,
                  'isWide': delivery.extraType == 'WIDE',
                  'isNoBall': delivery.extraType == 'NO_BALL',
                  'batsman': entityName(delivery.batter, fallback: 'Batter'),
                  'bowler': entityName(delivery.bowler, fallback: 'Bowler'),
                  'text': delivery.commentary ?? '${delivery.totalRuns} runs',
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatsTable(
    String title,
    List<String> columns,
    List<List<String>> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 14,
            headingRowHeight: 32,
            dataRowMinHeight: 30,
            dataRowMaxHeight: 36,
            columns: columns.map((column) => DataColumn(label: Text(column))).toList(),
            rows: rows
                .map(
                  (row) => DataRow(
                    cells: row.map((cell) => DataCell(Text(cell))).toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleList(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Text('None')
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(item),
              )),
      ],
    );
  }

  List<T> _rows<T>(
    dynamic source,
    T Function(Map<String, dynamic> item) mapper,
  ) {
    if (source is! List) return const [];
    return source
        .whereType<Map<String, dynamic>>()
        .map((item) => mapper(item))
        .toList();
  }

  String statusText(dynamic status) => status?.toString().replaceAll('_', ' ') ?? 'SCHEDULED';

  String _overs(int balls) {
    return '${balls ~/ 6}.${balls % 6}';
  }

  int _int(dynamic value) => value is num ? value.toInt() : 0;

  double _num(dynamic value) => value is num ? value.toDouble() : 0;
}
