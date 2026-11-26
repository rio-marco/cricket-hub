import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/auction_player.dart';
import 'auction_card.dart';

class AuctionPlayerTile extends StatelessWidget {
  final AuctionPlayer player;
  final VoidCallback? onBringForward;

  const AuctionPlayerTile({
    super.key,
    required this.player,
    this.onBringForward,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final statusColor = player.isSold
        ? AppColors.success
        : player.isUnsold
            ? AppColors.error
            : player.available
                ? AppColors.info
                : AppColors.warning;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.12),
        child: Icon(Icons.person_outline, color: statusColor, size: 18),
      ),
      title: Text(
        player.displayName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: primaryText,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        [
          player.status.toLowerCase(),
          if (player.category != null && player.category!.isNotEmpty)
            player.category!,
          if (player.setNumber != null) 'Set ${player.setNumber}',
          'Base ${formatAuctionMoney(player.basePrice)}',
        ].join(' · '),
        style: (isDark
                ? AppTextStyles.bodySmallDark
                : AppTextStyles.bodySmallLight)
            .copyWith(color: secondaryText),
      ),
      trailing: onBringForward == null
          ? player.currentBid > 0
              ? Text(
                  formatAuctionMoney(player.currentBid),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                )
              : null
          : IconButton(
              tooltip: 'Bring forward',
              icon: const Icon(Icons.skip_next_rounded),
              color: AppColors.primary,
              onPressed: onBringForward,
            ),
    );
  }
}
