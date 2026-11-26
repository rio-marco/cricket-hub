import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/admin_auction.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';
import '../widgets/audit_log_tile.dart';

class AdminAuctionsScreen extends ConsumerWidget {
  const AdminAuctionsScreen({super.key});

  static const List<String> _statuses = <String>[
    'DRAFT',
    'UPCOMING',
    'LIVE',
    'PAUSED',
    'COMPLETED',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAuctionsProvider);

    return AppScaffold(
      title: 'Admin Auctions',
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminAuctionsProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminFilterBar(
                search: state.search,
                status: state.status,
                statuses: _statuses,
                onSearchChanged: (value) =>
                    ref.read(adminAuctionsProvider.notifier).setSearch(value),
                onStatusChanged: (value) =>
                    ref.read(adminAuctionsProvider.notifier).setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading auctions...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminAuctionsProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No auctions found',
                  icon: Icons.gavel_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Auctions',
                  subtitle: '${state.total} total',
                  onRefresh: () => ref
                      .read(adminAuctionsProvider.notifier)
                      .load(refresh: true),
                  children: [
                    for (final auction in state.items) ...[
                      _AuctionCard(auction: auction),
                      const SizedBox(height: 8),
                    ],
                    if (state.hasNextPage)
                      AppButton.outlined(
                        text: state.isLoadingMore ? 'Loading...' : 'Load More',
                        isLoading: state.isLoadingMore,
                        height: 40,
                        onPressed: () =>
                            ref.read(adminAuctionsProvider.notifier).loadMore(),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuctionCard extends ConsumerStatefulWidget {
  final AdminAuction auction;

  const _AuctionCard({required this.auction});

  @override
  ConsumerState<_AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends ConsumerState<_AuctionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = _expanded
        ? ref.watch(adminAuctionDetailProvider(widget.auction.id))
        : null;
    final bids = _expanded
        ? ref.watch(adminAuctionBidsProvider(widget.auction.id))
        : null;
    final audit = _expanded
        ? ref.watch(adminAuctionAuditProvider(widget.auction.id))
        : null;
    final suspicious = _expanded
        ? ref.watch(adminAuctionSuspiciousProvider(widget.auction.id))
        : null;

    return AppCard(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(
            widget.auction.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            [
              widget.auction.status,
              widget.auction.tournamentName,
              '${widget.auction.playerCount} players',
              'v${widget.auction.stateVersion}',
            ].where((value) => value.isNotEmpty).join(' • '),
          ),
          onExpansionChanged: (value) => setState(() => _expanded = value),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Purse: ${widget.auction.purseAmount.toStringAsFixed(0)}',
                  ),
                  Text('Teams: ${widget.auction.teamCount}'),
                  if (detail != null)
                    _async(
                      detail.when(
                        data: (auction) => Text('Details: ${auction.raw}'),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            Text('Details unavailable: $error'),
                      ),
                    ),
                  if (bids != null)
                    _async(
                      bids.when(
                        data: (items) => items.isEmpty
                            ? const Text('No bids recorded.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final bid in items)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(bid.toString()),
                                    ),
                                ],
                              ),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) => Text('Bids unavailable: $error'),
                      ),
                      title: 'Bids',
                    ),
                  if (audit != null)
                    _async(
                      audit.when(
                        data: (items) => items.isEmpty
                            ? const Text('No audit entries recorded.')
                            : Column(
                                children: [
                                  for (final entry in items)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: AuditLogTile(entry: entry),
                                    ),
                                ],
                              ),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) => Text('Audit unavailable: $error'),
                      ),
                      title: 'Auction audit',
                    ),
                  if (suspicious != null)
                    _async(
                      suspicious.when(
                        data: (items) => items.isEmpty
                            ? const Text('No suspicious activity recorded.')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final entry in items)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(entry.toString()),
                                    ),
                                ],
                              ),
                        loading: () =>
                            const LinearProgressIndicator(minHeight: 2),
                        error: (error, _) =>
                            Text('Suspicious activity unavailable: $error'),
                      ),
                      title: 'Suspicious activity',
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _async(Widget child, {String? title}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
