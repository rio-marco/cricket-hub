import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';

import '../../domain/entities/scoring.dart';
import '../providers/realtime_provider.dart';
import '../providers/scoring_provider.dart';
import '../widgets/commentary_item.dart';

class LiveScoringScreen extends ConsumerStatefulWidget {
  final String matchId;

  const LiveScoringScreen({super.key, required this.matchId});

  @override
  ConsumerState<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends ConsumerState<LiveScoringScreen> {
  String? _striker;
  String? _nonStriker;
  String? _openingBowler;
  String? _nextBowler;
  String _wicketType = 'BOWLED';

  @override
  Widget build(BuildContext context) {
    ref.watch(matchRoomProvider(widget.matchId));
    final state = ref.watch(scoringControllerProvider(widget.matchId));
    final notifier = ref.read(scoringControllerProvider(widget.matchId).notifier);
    final active = state.activeInnings;
    final match = state.snapshot.match;
    final battingXI = _battingXI(state.snapshot);
    final bowlingXI = _bowlingXI(state.snapshot);
    _ensureSelections(battingXI, bowlingXI, active);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scoring Console'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: notifier.load,
          ),
          IconButton(
            tooltip: 'Undo last ball',
            icon: const Icon(Icons.undo_rounded),
            onPressed: state.snapshot.deliveries.isEmpty || state.isSaving
                ? null
                : () async {
                    final ok = await notifier.undoLastBall();
                    _showResult(ok, 'Undo failed.');
                  },
          ),
          IconButton(
            tooltip: 'Full scorecard',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => context.push('/matches/${widget.matchId}/scorecard'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.errorMessage != null)
            Container(
              width: double.infinity,
              color: AppColors.wicket.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: AppColors.wicket),
              ),
            ),
          if (state.successMessage != null)
            Container(
              width: double.infinity,
              color: AppColors.primary.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                state.successMessage!,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          Expanded(
            child: state.isLoading && match == null
                ? const LoadingWidget(message: 'Loading live scoring state...')
                : match == null
                    ? AppErrorWidget(
                        title: 'Unable to open scorer',
                        message: state.errorMessage ?? 'Match data is unavailable.',
                        onRetry: notifier.load,
                      )
                    : RefreshIndicator(
                        onRefresh: notifier.load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildScoreCard(active, match),
                            const SizedBox(height: 14),
                            if (_needsInningsStart(active)) ...[
                              _buildStartInningsCard(
                                notifier,
                                battingXI,
                                bowlingXI,
                                state.isSaving,
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (_needsNewBowler(active)) ...[
                              _buildBowlerSelectionCard(
                                bowlingXI,
                                active,
                                state.isSaving,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _buildScoringControls(
                              notifier,
                              active,
                              bowlingXI,
                              state.isSaving,
                            ),
                            const SizedBox(height: 14),
                            _buildFallOfWickets(active),
                            const SizedBox(height: 14),
                            _buildCommentary(state.snapshot, notifier, state.isSaving),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Map<String, dynamic>? active, ScoringMatch match) {
    final runs = _int(active?['totalRuns']);
    final wickets = _int(active?['totalWickets']);
    final balls = _int(active?['totalBalls']);
    final target = active?['target'];
    final striker = active?['currentBatters'] is Map
        ? entityName((active!['currentBatters'] as Map)['striker'], fallback: 'Yet to bat')
        : 'Yet to bat';
    final nonStriker = active?['currentBatters'] is Map
        ? entityName((active!['currentBatters'] as Map)['nonStriker'], fallback: 'Yet to bat')
        : 'Yet to bat';
    final bowler = entityName(active?['currentBowler'], fallback: 'Select bowler');

    return AppCard(
      hasGradientHeader: true,
      headerTitle: '${match.teamAName} vs ${match.teamBName}',
      headerSubtitle: '${match.format} • ${match.totalOvers} overs per innings',
      headerLeading: const Icon(Icons.sports_cricket_rounded, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$runs/$wickets (${_overs(balls, match.ballsPerOver)} ov)',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (target is num)
            Text(
              'Target ${target.toInt()} • Need ${target.toInt() - runs} runs',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Text('Striker: $striker')),
              Expanded(child: Text('Non-striker: $nonStriker')),
            ],
          ),
          const SizedBox(height: 4),
          Text('Bowler: $bowler'),
        ],
      ),
    );
  }

  Widget _buildStartInningsCard(
    ScoringNotifier notifier,
    List<String> battingXI,
    List<String> bowlingXI,
    bool isSaving,
  ) {
    return AppCard(
      headerTitle: 'Start this innings',
      headerLeading: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
      child: Column(
        children: [
          _playerDropdown('Striker', _striker, battingXI, (value) => setState(() => _striker = value)),
          _playerDropdown(
            'Non-striker',
            _nonStriker,
            battingXI,
            (value) => setState(() => _nonStriker = value),
          ),
          _playerDropdown(
            'Opening bowler',
            _openingBowler,
            bowlingXI,
            (value) => setState(() => _openingBowler = value),
          ),
          const SizedBox(height: 10),
          AppButton(
            text: 'Start Innings',
            isLoading: isSaving,
            isDisabled: _striker == null || _nonStriker == null || _openingBowler == null,
            onPressed: () async {
              final ok = await notifier.startInnings(
                striker: _striker!,
                nonStriker: _nonStriker!,
                bowler: _openingBowler!,
              );
              _showResult(ok, 'Unable to start innings.');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBowlerSelectionCard(
    List<String> bowlingXI,
    Map<String, dynamic>? active,
    bool isSaving,
  ) {
    final lastBowler = active?['lastOverBowler'] is Map
        ? entityId((active!['lastOverBowler'] as Map)['_id'] ?? active['lastOverBowler'])
        : entityId(active?['lastOverBowler']);
    final options = bowlingXI.where((id) => id != lastBowler).toList();
    if (_nextBowler == null || !options.contains(_nextBowler)) {
      _nextBowler = options.isEmpty ? null : options.first;
    }
    return AppCard(
      headerTitle: 'Choose next over bowler',
      headerLeading: const Icon(Icons.sports_rounded, color: AppColors.primary),
      child: _playerDropdown(
        'Bowler',
        _nextBowler,
        options,
        (value) => setState(() => _nextBowler = value),
      ),
    );
  }

  Widget _buildScoringControls(
    ScoringNotifier notifier,
    Map<String, dynamic>? active,
    List<String> bowlingXI,
    bool isSaving,
  ) {
    final canScore = _canScore(active, isSaving);
    final bowler = _effectiveBowler(active);
    return AppCard(
      headerTitle: 'Record delivery',
      headerLeading: const Icon(Icons.touch_app_rounded, color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final runs in [0, 1, 2, 3, 4, 6])
                SizedBox(
                  width: 62,
                  child: AppButton(
                    text: runs == 0 ? 'DOT' : '$runs',
                    height: 46,
                    isDisabled: !canScore,
                    onPressed: () async {
                      final ok = await notifier.recordRuns(runs, bowler: bowler);
                      _showResult(ok, 'Unable to record runs.');
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final extra in [
                ('WIDE', 'Wd'),
                ('NO_BALL', 'Nb'),
                ('BYE', 'B'),
                ('LEG_BYE', 'Lb'),
                ('PENALTY', 'P'),
              ])
                SizedBox(
                  width: 62,
                  child: AppButton.outlined(
                    text: extra.$2,
                    height: 42,
                    isDisabled: !canScore,
                    onPressed: () async {
                      final ok = await notifier.recordExtra(
                        extra.$1,
                        bowler: bowler,
                      );
                      _showResult(ok, 'Unable to record extra.');
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton.secondary(
            text: 'Wicket',
            icon: Icons.back_hand_rounded,
            isDisabled: !canScore,
            onPressed: () => _showWicketDialog(notifier, active, bowler),
          ),
          if (active?['status'] == 'COMPLETED' ||
              (stateSnapshot.snapshot.match?.status ?? '') == 'COMPLETED')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: AppButton.outlined(
                text: 'Record Match Result',
                isLoading: isSaving,
                onPressed: () async {
                  final ok = await notifier.completeMatch();
                  _showResult(ok, 'Unable to record result.');
                },
              ),
            ),
        ],
      ),
    );
  }

  ScoringUiState get stateSnapshot =>
      ref.read(scoringControllerProvider(widget.matchId));

  Widget _buildFallOfWickets(Map<String, dynamic>? active) {
    final wickets = active?['fallOfWickets'];
    final items = wickets is List ? wickets : <dynamic>[];
    return AppCard(
      headerTitle: 'Fall of Wickets',
      headerLeading: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
      child: items.isEmpty
          ? const Text('No wickets yet.')
          : Column(
              children: items
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '${item['teamScore']}-${item['wicketNumber']} '
                        '${entityName(item['player'], fallback: 'Batter')} '
                        '(${item['teamOvers']} ov)',
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildCommentary(
    ScoringSnapshot snapshot,
    ScoringNotifier notifier,
    bool isSaving,
  ) {
    if (snapshot.deliveries.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No deliveries yet',
        subtitle: 'Use the scoring controls to record the first ball.',
      );
    }
    return AppCard(
      headerTitle: 'Ball by ball',
      headerLeading: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primary),
      child: Column(
        children: snapshot.deliveries.take(30).map((delivery) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommentaryItemWidget(
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
              if (!isSaving)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showCorrectionDialog(notifier, delivery),
                    child: const Text('Correct'),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _playerDropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue = value != null && options.contains(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((id) => DropdownMenuItem<String>(
                  value: id,
                  child: Text(_playerName(id)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _showWicketDialog(
    ScoringNotifier notifier,
    Map<String, dynamic>? active,
    String? bowler,
  ) async {
    final currentBatters = active?['currentBatters'];
    final dismissedOptions = <String>[];
    if (currentBatters is Map) {
      final striker = entityId(currentBatters['striker']);
      final nonStriker = entityId(currentBatters['nonStriker']);
      if (striker.isNotEmpty) dismissedOptions.add(striker);
      if (nonStriker.isNotEmpty && nonStriker != striker) {
        dismissedOptions.add(nonStriker);
      }
    }
    final bowlingXI = _bowlingXI(stateSnapshot.snapshot);
    if (dismissedOptions.isEmpty) return;
    String dismissed = dismissedOptions.first;
    String? fielder;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Record wicket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _wicketType,
              decoration: const InputDecoration(labelText: 'Dismissal'),
              items: [
                'BOWLED',
                'CAUGHT',
                'LBW',
                'RUN_OUT',
                'STUMPED',
                'HIT_WICKET',
              ]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => _wicketType = value ?? 'BOWLED',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: dismissed,
              decoration: const InputDecoration(labelText: 'Dismissed batter'),
              items: dismissedOptions
                  .map((id) => DropdownMenuItem(value: id, child: Text(_playerName(id))))
                  .toList(),
              onChanged: (value) => dismissed = value ?? dismissed,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: fielder,
              decoration: const InputDecoration(labelText: 'Fielder (optional)'),
              items: [
                const DropdownMenuItem<String>(value: null, child: Text('None')),
                ...bowlingXI.map(
                  (id) => DropdownMenuItem<String?>(value: id, child: Text(_playerName(id))),
                ),
              ],
              onChanged: (value) => fielder = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Record'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final success = await notifier.recordWicket(
        type: _wicketType,
        dismissedPlayerId: dismissed,
        fielderId: fielder,
        bowler: bowler,
      );
      _showResult(success, 'Unable to record wicket.');
    }
  }

  Future<void> _showCorrectionDialog(
    ScoringNotifier notifier,
    ScoringDelivery delivery,
  ) async {
    int runs = delivery.batterRuns;
    String extraType = delivery.extraType;
    int extraRuns = delivery.extraRuns;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Correct delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: runs,
              decoration: const InputDecoration(labelText: 'Batter runs'),
              items: [0, 1, 2, 3, 4, 6]
                  .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                  .toList(),
              onChanged: (value) => runs = value ?? 0,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: extraType,
              decoration: const InputDecoration(labelText: 'Extra type'),
              items: ['NONE', 'WIDE', 'NO_BALL', 'BYE', 'LEG_BYE', 'PENALTY']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => extraType = value ?? 'NONE',
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: extraRuns,
              decoration: const InputDecoration(labelText: 'Extra runs'),
              items: [0, 1, 2]
                  .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                  .toList(),
              onChanged: (value) => extraRuns = value ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await notifier.correctDelivery(
        delivery.id,
        runs: runs,
        extraType: extraType,
        extraRuns: extraRuns,
      );
      _showResult(success, 'Unable to correct delivery.');
    }
  }

  void _showResult(bool success, String failureMessage) {
    if (! mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Saved.' : failureMessage)),
    );
  }

  List<String> _battingXI(ScoringSnapshot snapshot) {
    final match = snapshot.match;
    final active = snapshot.activeInnings;
    if (match == null) return const [];
    final battingTeam = active is Map ? active['battingTeam'] : match.teamA;
    return entityId(battingTeam) == entityId(match.teamA)
        ? match.playingXI_A
        : match.playingXI_B;
  }

  List<String> _bowlingXI(ScoringSnapshot snapshot) {
    final match = snapshot.match;
    final active = snapshot.activeInnings;
    if (match == null) return const [];
    final battingTeam = active is Map ? active['battingTeam'] : match.teamA;
    return entityId(battingTeam) == entityId(match.teamA)
        ? match.playingXI_B
        : match.playingXI_A;
  }

  void _ensureSelections(
    List<String> battingXI,
    List<String> bowlingXI,
    Map<String, dynamic>? active,
  ) {
    if (battingXI.isNotEmpty) {
      if (_striker == null || !battingXI.contains(_striker)) _striker = battingXI.first;
      if (_nonStriker == null || !battingXI.contains(_nonStriker)) {
        _nonStriker = battingXI.length > 1 ? battingXI[1] : null;
      }
    }
    if (bowlingXI.isNotEmpty) {
      if (_openingBowler == null || !bowlingXI.contains(_openingBowler)) {
        _openingBowler = bowlingXI.first;
      }
    }
  }

  bool _needsInningsStart(Map<String, dynamic>? active) {
    if (active == null) return false;
    final status = (active['status']?.toString() ?? '').toUpperCase();
    if (status == 'COMPLETED' || status == 'DECLARED') return false;
    final balls = _int(active['totalBalls']);
    final bowler = active['currentBowler'];
    return balls == 0 && bowler == null;
  }

  bool _needsNewBowler(Map<String, dynamic>? active) {
    if (active == null || _needsInningsStart(active)) return false;
    final status = (active['status']?.toString() ?? '').toUpperCase();
    if (status == 'COMPLETED' || status == 'DECLARED') return false;
    return active['currentBowler'] == null;
  }

  bool _canScore(Map<String, dynamic>? active, bool isSaving) {
    if (active == null || isSaving) return false;
    final status = (active['status']?.toString() ?? '').toUpperCase();
    if (status != 'IN_PROGRESS') return false;
    if ((stateSnapshot.snapshot.match?.status ?? '').toUpperCase() == 'COMPLETED') {
      return false;
    }
    return _effectiveBowler(active) != null;
  }

  String? _effectiveBowler(Map<String, dynamic>? active) {
    final current = active?['currentBowler'];
    if (current != null) return entityId(current);
    return _nextBowler;
  }

  String _playerName(String id) {
    final snapshot = stateSnapshot.snapshot;
    for (final inning in snapshot.innings) {
      if (inning is! Map<String, dynamic>) continue;
      for (final key in ['battingStats', 'bowlingStats']) {
        final stats = inning[key];
        if (stats is! List) continue;
        for (final stat in stats) {
          if (stat is Map<String, dynamic> && entityId(stat['player']) == id) {
            return entityName(stat['player'], fallback: 'Player');
          }
        }
      }
    }
    return 'Player ${id.substring(id.length > 6 ? id.length - 6 : 0)}';
  }

  String _overs(int balls, int ballsPerOver) {
    if (ballsPerOver < 1) ballsPerOver = 6;
    return '${balls ~/ ballsPerOver}.${balls % ballsPerOver}';
  }

  int _int(dynamic value) => value is num ? value.toInt() : 0;
}
