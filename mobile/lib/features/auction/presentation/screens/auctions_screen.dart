import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/auction_provider.dart';
import '../widgets/auction_card.dart';

class AuctionsScreen extends ConsumerStatefulWidget {
  const AuctionsScreen({super.key});

  @override
  ConsumerState<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends ConsumerState<AuctionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _status = 'ALL';

  static const _filters = <String>['ALL', 'LIVE', 'UPCOMING', 'COMPLETED'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionsListProvider);

    return AppScaffold(
      title: 'Player Auctions',
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push(AppRoutes.createAuction),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(auctionsListProvider.notifier).load(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => ref
                          .read(auctionsListProvider.notifier)
                          .searchAuctions(value),
                      decoration: InputDecoration(
                        labelText: 'Search auctions',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => ref
                              .read(auctionsListProvider.notifier)
                              .searchAuctions(_searchController.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final selected = filter == _status;
                          return ChoiceChip(
                            label: Text(filter),
                            selected: selected,
                            selectedColor: AppColors.primary.withOpacity(0.18),
                            onSelected: (_) {
                              setState(() => _status = filter);
                              ref
                                  .read(auctionsListProvider.notifier)
                                  .setStatus(filter);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            switch (state) {
              AuctionListLoading() => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingWidget(message: 'Loading auctions...'),
                ),
              AuctionListError(message: final message) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppErrorWidget(
                    message: message,
                    onRetry: () => ref
                        .read(auctionsListProvider.notifier)
                        .load(refresh: true),
                  ),
                ),
              AuctionListEmpty() => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gavel_outlined, size: 56),
                        const SizedBox(height: 12),
                        const Text('No auctions found.'),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Create auction',
                          onPressed: () => context.push(AppRoutes.createAuction),
                        ),
                      ],
                    ),
                  ),
                ),
              AuctionListLoaded(auctions: final auctions, hasNextPage: final hasNextPage) =>
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == auctions.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: AppButton.outlined(
                            text: hasNextPage ? 'Load more' : 'All auctions loaded',
                            isDisabled: !hasNextPage,
                            onPressed: hasNextPage
                                ? () => ref
                                    .read(auctionsListProvider.notifier)
                                    .loadMore()
                                : null,
                          ),
                        );
                      }
                      final auction = auctions[index];
                      return AuctionCard(
                        auction: auction,
                        onTap: () => context.push('/auctions/${auction.id}'),
                      );
                    },
                    childCount: auctions.length + 1,
                  ),
                ),
            },
          ],
        ),
      ),
    );
  }
}
