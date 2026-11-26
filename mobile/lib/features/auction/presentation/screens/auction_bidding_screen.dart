import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../providers/auction_provider.dart';
import '../widgets/auction_live_view.dart';

class AuctionBiddingScreen extends ConsumerWidget {
  final String auctionId;

  const AuctionBiddingScreen({super.key, required this.auctionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auctionLiveControllerProvider(auctionId));
    final controller = ref.read(auctionLiveControllerProvider(auctionId).notifier);
    ref.watch(auctionRoomProvider(auctionId));

    return AppScaffold(
      title: 'Live Auction Bidding',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: () => controller.load(),
        ),
      ],
      body: AuctionLiveView(
        controller: controller,
        state: state,
        showAllTabs: false,
      ),
    );
  }
}
