import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/auction.dart';

String formatAuctionMoney(double value) {
  final amount = value.round();
  if (amount >= 10000000) {
    return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
  }
  if (amount >= 100000) {
    return '₹${(amount / 100000).toStringAsFixed(2)} L';
  }
  return '₹$amount';
}

Color auctionStatusColor(String status, bool isDark) {
  switch (status) {
    case 'LIVE':
      return AppColors.liveRed;
    case 'PAUSED':
      return AppColors.warning;
    case 'COMPLETED':
      return AppColors.success;
    case 'UPCOMING':
      return AppColors.info;
    default:
      return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  }
}

class AuctionStatusChip extends StatelessWidget {
  final String status;

  const AuctionStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = auctionStatusColor(status, isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: (isDark
                ? AppTextStyles.labelSmallDark
                : AppTextStyles.labelSmallLight)
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class AuctionCard extends StatelessWidget {
  final Auction auction;
  final VoidCallback onTap;

  const AuctionCard({
    super.key,
    required this.auction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teamNames = auction.teamNames.isEmpty
        ? '${auction.teams.length} participating teams'
        : auction.teamNames.join(' vs ');

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  auction.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              AuctionStatusChip(status: auction.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            teamNames,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (isDark
                    ? AppTextStyles.bodySmallDark
                    : AppTextStyles.bodySmallLight)
                .copyWith(color: secondaryText),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 16, color: primaryText),
              const SizedBox(width: 6),
              Text(
                formatAuctionMoney(auction.purseAmount),
                style: (isDark
                        ? AppTextStyles.labelMediumDark
                        : AppTextStyles.labelMediumLight)
                    .copyWith(color: primaryText),
              ),
              const Spacer(),
              Icon(Icons.people_outline, size: 16, color: secondaryText),
              const SizedBox(width: 4),
              Text('${auction.playerCount}', style: AppTextStyles.bodySmallLight),
              const SizedBox(width: 10),
              Icon(Icons.gavel_outlined, size: 16, color: secondaryText),
              const SizedBox(width: 4),
              Text('${auction.soldCount}', style: AppTextStyles.bodySmallLight),
            ],
          ),
        ],
      ),
    );
  }
}
