import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/auction_bid.dart';
import 'auction_card.dart';

class AuctionBidTile extends StatelessWidget {
  final AuctionBid bid;

  const AuctionBidTile({super.key, required this.bid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final decisionColor = bid.isAccepted
        ? AppColors.success
        : bid.isRejected
            ? AppColors.error
            : AppColors.warning;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.12),
        child: Text(
          '#${bid.sequenceNumber}',
          style: (isDark
                  ? AppTextStyles.labelSmallDark
                  : AppTextStyles.labelSmallLight)
              .copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(
        bid.teamName ?? 'Team',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        bid.bidderName ?? bid.decision.toLowerCase(),
        style: (isDark
                ? AppTextStyles.bodySmallDark
                : AppTextStyles.bodySmallLight)
            .copyWith(color: secondaryText),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatAuctionMoney(bid.amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            bid.decision.toLowerCase(),
            style: (isDark
                    ? AppTextStyles.labelSmallDark
                    : AppTextStyles.labelSmallLight)
                .copyWith(color: decisionColor),
          ),
        ],
      ),
    );
  }
}
