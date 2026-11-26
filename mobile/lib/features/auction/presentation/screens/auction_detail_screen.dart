import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../providers/auction_provider.dart';
import '../widgets/auction_live_view.dart';

class AuctionDetailScreen extends ConsumerWidget {
  final String auctionId;

  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auctionLiveControllerProvider(auctionId));
    final controller = ref.read(auctionLiveControllerProvider(auctionId).notifier);
    ref.watch(auctionRoomProvider(auctionId));

    return AppScaffold(
      title: state.snapshot?.auction.name ?? 'Auction Room',
      actions: [
        IconButton(
          tooltip: 'Open live bidding',
          icon: const Icon(Icons.pan_tool_alt_rounded),
          onPressed: () => context.push('/auctions/$auctionId/bidding'),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.load(),
        ),
      ],
      body: AuctionLiveView(
        controller: controller,
        state: state,
        showAllTabs: true,
      ),
    );
  }
}
