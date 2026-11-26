import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/auction_state.dart';
import '../providers/auction_provider.dart';
import 'auction_bid_tile.dart';
import 'auction_card.dart';
import 'auction_player_tile.dart';

class AuctionLiveView extends StatefulWidget {
  final AuctionLiveController controller;
  final AuctionLiveState state;
  final bool showAllTabs;

  const AuctionLiveView({
    super.key,
    required this.controller,
    required this.state,
    this.showAllTabs = true,
  });

  @override
  State<AuctionLiveView> createState() => _AuctionLiveViewState();
}

class _AuctionLiveViewState extends State<AuctionLiveView> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedTeamId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.isLoading && state.snapshot == null) {
      return const LoadingWidget(message: 'Loading auction state...');
    }
    if (state.errorMessage != null && state.snapshot == null) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () => widget.controller.load(),
      );
    }
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const LoadingWidget(message: 'Loading auction state...');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final biddableTeams = snapshot.biddableTeams;
    if (_selectedTeamId == null ||
        !biddableTeams.any((team) => team.teamId == _selectedTeamId)) {
      _selectedTeamId = biddableTeams.isEmpty ? null : biddableTeams.first.teamId;
    }

    final tabs = widget.showAllTabs
        ? const [
            Tab(text: 'Live'),
            Tab(text: 'Teams'),
            Tab(text: 'Players'),
            Tab(text: 'Bids'),
            Tab(text: 'Results'),
          ]
        : const <Tab>[Tab(text: 'Live')];

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          _buildMessageBanner(state, isDark),
          TabBar(
            tabs: tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            indicatorColor: AppColors.primary,
            isScrollable: true,
          ),
          Expanded(
            child: TabBarView(
              children: widget.showAllTabs
                  ? [
                      _buildLiveTab(snapshot, biddableTeams, isDark),
                      _buildTeamsTab(snapshot, isDark),
                      _buildPlayersTab(snapshot, isDark),
                      _buildBidsTab(snapshot, isDark),
                      _buildResultsTab(snapshot, isDark),
                    ]
                  : [
                      _buildLiveTab(snapshot, biddableTeams, isDark),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBanner(AuctionLiveState state, bool isDark) {
    final message = state.errorMessage ?? state.successMessage;
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    final isError = state.errorMessage != null;
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: (isDark
                      ? AppTextStyles.bodySmallDark
                      : AppTextStyles.bodySmallLight)
                  .copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab(
    AuctionStateSnapshot snapshot,
    List<dynamic> biddableTeams,
    bool isDark,
  ) {
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final player = snapshot.currentPlayer;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppCard(
          headerTitle: 'Auction room',
          headerSubtitle: snapshot.auction.statusLabel,
          hasGradientHeader: true,
          headerLeading: const Icon(Icons.gavel_rounded, color: Colors.white),
          child: Column(
            children: [
              Row(
                children: [
                  _statTile('Version', '${snapshot.stateVersion}', isDark),
                  _statTile('Players', '${snapshot.counts.totalPlayers}', isDark),
                  _statTile('Sold', '${snapshot.counts.soldPlayers}', isDark),
                  _statTile('Bids', '${snapshot.counts.totalBids}', isDark),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          headerTitle: 'Current player',
          headerSubtitle: player == null ? 'No player on the block' : player.displayName,
          headerLeading: const Icon(Icons.person_outline, color: Colors.white),
          hasGradientHeader: true,
          child: player == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Wait for the auction controller to bring a player forward.',
                    style: (isDark
                            ? AppTextStyles.bodyMediumDark
                            : AppTextStyles.bodyMediumLight)
                        .copyWith(color: secondaryText),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statTile(
                          'Base',
                          formatAuctionMoney(player.basePrice),
                          isDark,
                        ),
                        _statTile(
                          'Current bid',
                          formatAuctionMoney(player.currentBid),
                          isDark,
                        ),
                        _statTile('Bids', '${player.bidCount}', isDark),
                      ],
                    ),
                    if (player.highestBidderName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Highest bidder: ${player.highestBidderName}',
                        style: (isDark
                                ? AppTextStyles.bodySmallDark
                                : AppTextStyles.bodySmallLight)
                            .copyWith(color: secondaryText),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Minimum increment ${formatAuctionMoney(snapshot.auction.minBidIncrement.toDouble())}',
                      style: (isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmallLight)
                          .copyWith(color: secondaryText),
                    ),
                  ],
                ),
        ),
        if (snapshot.permissions.canManage) ...[
          const SizedBox(height: 14),
          _buildControllerActions(snapshot, isDark),
        ],
        if (snapshot.permissions.canBid) ...[
          const SizedBox(height: 14),
          _buildBidPanel(snapshot, biddableTeams, isDark),
        ],
        const SizedBox(height: 14),
        AppCard(
          headerTitle: 'Team purses',
          headerSubtitle: '${snapshot.teams.length} teams',
          headerLeading: const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.white),
          hasGradientHeader: true,
          child: snapshot.teams.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No teams registered.'),
                )
              : Column(
                  children: snapshot.teams
                      .map(
                        (team) => ListTile(
                          dense: true,
                          title: Text(team.displayName),
                          subtitle: Text(
                            'Spent ${formatAuctionMoney(team.spent)} · '
                            'Pending ${formatAuctionMoney(team.pendingCommitment)} · '
                            '${team.playersPurchased} players',
                          ),
                          trailing: Text(
                            formatAuctionMoney(team.availableBudget),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.cardDark
              : AppColors.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: (isDark
                      ? AppTextStyles.labelSmallDark
                      : AppTextStyles.labelSmallLight)
                  .copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControllerActions(AuctionStateSnapshot snapshot, bool isDark) {
    final status = snapshot.auction.status;
    final hasPlayer = snapshot.currentPlayer != null;
    final canSettle = hasPlayer && (status == 'LIVE' || status == 'PAUSED');

    return AppCard(
      headerTitle: 'Auction controls',
      headerSubtitle: 'Authoritative server actions',
      headerLeading: const Icon(Icons.admin_panel_settings, color: Colors.white),
      hasGradientHeader: true,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (status == 'DRAFT' || status == 'UPCOMING')
            AppButton(
              text: 'Start auction',
              icon: Icons.play_arrow_rounded,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.start(),
            ),
          if (status == 'LIVE')
            AppButton.secondary(
              text: 'Pause',
              icon: Icons.pause_rounded,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.pause(),
            ),
          if (status == 'PAUSED')
            AppButton(
              text: 'Resume',
              icon: Icons.play_arrow_rounded,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.resume(),
            ),
          if (canSettle)
            AppButton(
              text: 'Sold',
              icon: Icons.gavel_rounded,
              isLoading: widget.state.isSaving,
              onPressed: snapshot.currentPlayer?.currentBid == null ||
                      snapshot.currentPlayer!.currentBid <= 0
                  ? null
                  : () => widget.controller.markSold(),
            ),
          if (canSettle)
            AppButton.outlined(
              text: 'Unsold',
              icon: Icons.close_rounded,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.markUnsold(),
            ),
          if (status == 'LIVE' || status == 'PAUSED')
            AppButton.outlined(
              text: 'Next player',
              icon: Icons.skip_next_rounded,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.next(),
            ),
          if (status == 'LIVE' || status == 'PAUSED')
            AppButton.secondary(
              text: 'Complete',
              icon: Icons.check_circle_outline,
              isLoading: widget.state.isSaving,
              onPressed: () => widget.controller.complete(),
            ),
        ],
      ),
    );
  }

  Widget _buildBidPanel(
    AuctionStateSnapshot snapshot,
    List<dynamic> biddableTeams,
    bool isDark,
  ) {
    final canAct = snapshot.auction.isLive &&
        snapshot.currentPlayer != null &&
        biddableTeams.isNotEmpty &&
        !widget.state.isSaving;

    return AppCard(
      headerTitle: 'Place bid',
      headerSubtitle: snapshot.auction.isLive
          ? 'Server validates purse and minimum bid'
          : 'Bidding is not open',
      headerLeading: const Icon(Icons.pan_tool_alt_rounded, color: Colors.white),
      hasGradientHeader: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (biddableTeams.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No team is assigned to your account for this auction.'),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedTeamId,
              decoration: const InputDecoration(
                labelText: 'Your team',
                border: OutlineInputBorder(),
              ),
              items: biddableTeams
                  .map(
                    (team) => DropdownMenuItem<String>(
                      value: team.teamId,
                      child: Text(team.displayName),
                    ),
                  )
                  .toList(growable: false),
              onChanged: canAct
                  ? (value) => setState(() => _selectedTeamId = value)
                  : null,
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            enabled: canAct,
            decoration: const InputDecoration(
              labelText: 'Amount (optional)',
              hintText: 'Leave empty for server minimum bid',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Place bid',
            icon: Icons.gavel_rounded,
            isLoading: widget.state.isSaving,
            isDisabled: !canAct || _selectedTeamId == null,
            onPressed: !canAct || _selectedTeamId == null
                ? null
                : () async {
                    final amount = _amountController.text.trim().isEmpty
                        ? null
                        : double.tryParse(_amountController.text.trim());
                    final success = await widget.controller.placeBid(
                      teamId: _selectedTeamId!,
                      amount: amount,
                    );
                    if (success && context.mounted) {
                      _amountController.clear();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsTab(AuctionStateSnapshot snapshot, bool isDark) {
    if (snapshot.teams.isEmpty) {
      return const Center(child: Text('No teams registered.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: snapshot.teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final team = snapshot.teams[index];
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              _statTile('Initial', formatAuctionMoney(team.initialBudget), isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statTile('Spent', formatAuctionMoney(team.spent), isDark),
                  _statTile(
                    'Pending',
                    formatAuctionMoney(team.pendingCommitment),
                    isDark,
                  ),
                  _statTile(
                    'Available',
                    formatAuctionMoney(team.availableBudget),
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Players purchased: ${team.playersPurchased}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab(AuctionStateSnapshot snapshot, bool isDark) {
    if (snapshot.players.isEmpty) {
      return const Center(child: Text('No players registered.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: snapshot.players.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final player = snapshot.players[index];
        return AuctionPlayerTile(
          player: player,
          onBringForward: snapshot.permissions.canManage && player.isAvailable
              ? () => widget.controller.bringForward(player.id)
              : null,
        );
      },
    );
  }

  Widget _buildBidsTab(AuctionStateSnapshot snapshot, bool isDark) {
    if (snapshot.bids.isEmpty) {
      return const Center(child: Text('No bids placed yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: snapshot.bids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => AuctionBidTile(bid: snapshot.bids[index]),
    );
  }

  Widget _buildResultsTab(AuctionStateSnapshot snapshot, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        AppCard(
          headerTitle: 'Sold players',
          headerSubtitle: '${snapshot.results.sold.length}',
          hasGradientHeader: true,
          headerLeading: const Icon(Icons.check_circle_outline,
              color: Colors.white),
          child: snapshot.results.sold.isEmpty
              ? const Text('No sold players yet.')
              : Column(
                  children: snapshot.results.sold
                      .map(
                        (player) => AuctionPlayerTile(player: player),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 14),
        AppCard(
          headerTitle: 'Unsold players',
          headerSubtitle: '${snapshot.results.unsold.length}',
          hasGradientHeader: true,
          headerLeading: const Icon(Icons.remove_circle_outline,
              color: Colors.white),
          child: snapshot.results.unsold.isEmpty
              ? const Text('No unsold players yet.')
              : Column(
                  children: snapshot.results.unsold
                      .map(
                        (player) => AuctionPlayerTile(player: player),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}
