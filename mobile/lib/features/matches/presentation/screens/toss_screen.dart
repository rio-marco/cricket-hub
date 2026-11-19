import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';
import '../../domain/entities/match.dart';
import '../providers/match_provider.dart';

/// Interactive cricket toss screen with 3D coin flip physics animation,
/// toss winner selection, and Bat First / Bowl First decision recorder.
class TossScreen extends ConsumerStatefulWidget {
  final String matchId;

  const TossScreen({
    super.key,
    required this.matchId,
  });

  @override
  ConsumerState<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends ConsumerState<TossScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _flipAnimation;

  String? _selectedWinnerTeam; // 'teamA' or 'teamB'
  String _selectedDecision = 'BAT'; // 'BAT' or 'BOWL'
  bool _isCoinFlipping = false;
  String _coinOutcome = 'HEADS'; // 'HEADS' or 'TAILS'

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 6 * math.pi).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOutCubic),
    );

    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isCoinFlipping = false;
          _coinOutcome = math.Random().nextBool() ? 'HEADS' : 'TAILS';
        });
      }
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _flipCoin() {
    if (_isCoinFlipping) return;
    setState(() => _isCoinFlipping = true);
    _coinController.forward(from: 0);
  }

  Future<void> _confirmToss(Match match) async {
    if (_selectedWinnerTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select which team won the toss')),
      );
      return;
    }

    final winnerTeamId = _selectedWinnerTeam == 'teamA'
        ? match.teamAName
        : match.teamBName;

    final updated = await ref.read(matchActionProvider.notifier).recordToss(
          matchId: match.id,
          winnerTeamId: winnerTeamId,
          decision: _selectedDecision,
        );

    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$winnerTeamId won toss & chose to ${_selectedDecision == "BAT" ? "Bat" : "Bowl"}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(matchDetailProvider(widget.matchId));
      ref.read(matchesListProvider.notifier).loadMatches(refresh: true);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final actionState = ref.watch(matchActionProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Match Toss',
          style: (isDark ? AppTextStyles.titleLargeDark : AppTextStyles.titleLargeLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: matchAsync.when(
        loading: () => const LoadingWidget(message: 'Preparing coin toss...'),
        error: (err, _) => AppErrorWidget(
          title: 'Failed to Load Match',
          message: err.toString(),
          onRetry: () => ref.invalidate(matchDetailProvider(widget.matchId)),
        ),
        data: (match) => _buildTossContent(context, match, isDark, actionState.isLoading),
      ),
    );
  }

  Widget _buildTossContent(
    BuildContext context,
    Match match,
    bool isDark,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Teams Face-off Banner Card
          _buildTeamsBanner(match, isDark),
          const SizedBox(height: 24),

          // 2. Animated Coin Flip Display
          _buildCoinFlipSection(isDark),
          const SizedBox(height: 28),

          // 3. "Who won the toss?" Selector
          _buildTossWinnerSelector(match, isDark),
          const SizedBox(height: 24),

          // 4. "What did they choose?" Decision Selector
          _buildDecisionSelector(isDark),
          const SizedBox(height: 32),

          // 5. Confirm Toss Button
          AppButton(
            text: 'Confirm Toss & Start Match',
            icon: Icons.check_circle_rounded,
            isLoading: isLoading,
            onPressed: () => _confirmToss(match),
            height: 52,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTeamsBanner(Match match, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Team A
          Expanded(
            child: Column(
              children: [
                _buildTeamAvatar(match.teamAShortName, AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  match.teamAName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // VS Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),

          // Team B
          Expanded(
            child: Column(
              children: [
                _buildTeamAvatar(match.teamBShortName, AppColors.secondaryLight),
                const SizedBox(height: 6),
                Text(
                  match.teamBName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamAvatar(String short, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          short,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3D Coin Flip
  // ---------------------------------------------------------------------------
  Widget _buildCoinFlipSection(bool isDark) {
    return Column(
      children: [
        GestureDetector(
          onTap: _flipCoin,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value;
              final isUnder = (angle % (2 * math.pi)) > (math.pi / 2) &&
                  (angle % (2 * math.pi)) < (3 * math.pi / 2);

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateX(angle),
                alignment: Alignment.center,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA000),
                        Color(0xFFFFB300),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFB300).withOpacity(0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFFF8E1),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Transform(
                      transform: Matrix4.identity()..rotateX(isUnder ? math.pi : 0),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isUnder ? Icons.toll_rounded : Icons.sports_cricket,
                            size: 38,
                            color: const Color(0xFF5D4037),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isUnder ? 'TAILS' : 'HEADS',
                            style: const TextStyle(
                              color: Color(0xFF5D4037),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        OutlinedButton.icon(
          onPressed: _isCoinFlipping ? null : _flipCoin,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(
            _isCoinFlipping ? 'Flipping Coin...' : 'Flip Coin (Tap Coin)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Winner Team Selector
  // ---------------------------------------------------------------------------
  Widget _buildTossWinnerSelector(Match match, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who Won The Toss? *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildSelectableTeamButton(
                title: match.teamAName,
                short: match.teamAShortName,
                isSelected: _selectedWinnerTeam == 'teamA',
                onTap: () => setState(() => _selectedWinnerTeam = 'teamA'),
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSelectableTeamButton(
                title: match.teamBName,
                short: match.teamBShortName,
                isSelected: _selectedWinnerTeam == 'teamB',
                onTap: () => setState(() => _selectedWinnerTeam = 'teamB'),
                color: AppColors.secondaryLight,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectableTeamButton({
    required String title,
    required String short,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  short,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
                color: isSelected ? color : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_off,
                  size: 16,
                  color: isSelected ? color : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                ),
                const SizedBox(width: 4),
                Text(
                  isSelected ? 'Winner' : 'Select',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : (isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Decision Selector (Bat / Bowl)
  // ---------------------------------------------------------------------------
  Widget _buildDecisionSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What did they choose to do? *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildDecisionCard(
                title: 'Bat First',
                icon: Icons.sports_cricket,
                isSelected: _selectedDecision == 'BAT',
                onTap: () => setState(() => _selectedDecision = 'BAT'),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDecisionCard(
                title: 'Bowl First',
                icon: Icons.sports_baseball_rounded,
                isSelected: _selectedDecision == 'BOWL',
                onTap: () => setState(() => _selectedDecision = 'BOWL'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDecisionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
