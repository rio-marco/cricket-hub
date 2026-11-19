import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/team_member.dart';

/// Presentation tile for a team squad member with role pill and administrative options.
class MemberListItem extends StatelessWidget {
  final TeamMember member;
  final bool isOwnerOrCaptain;
  final ValueChanged<String>? onRoleSelected;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  const MemberListItem({
    super.key,
    required this.member,
    this.isOwnerOrCaptain = false,
    this.onRoleSelected,
    this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Player Avatar / Jersey
          _buildAvatar(isDark),
          const SizedBox(width: 14),

          // Player Name & Playing Style
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.playerName ?? 'Player',
                          style: (isDark
                                  ? AppTextStyles.titleSmallDark
                                  : AppTextStyles.titleSmallLight)
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.jerseyNumber != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF333333)
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${member.jerseyNumber}',
                            style: (isDark
                                    ? AppTextStyles.labelSmallDark
                                    : AppTextStyles.labelSmallLight)
                                .copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatPlayingStyle(),
                    style: (isDark
                            ? AppTextStyles.bodySmallDark
                            : AppTextStyles.bodySmallLight)
                        .copyWith(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Role Badge Pill
          _buildRoleBadge(member.role),

          // Action Menu (Owner / Captain only)
          if (isOwnerOrCaptain) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (action) {
                if (action == 'REMOVE') {
                  onRemove?.call();
                } else {
                  onRoleSelected?.call(action);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'CAPTAIN',
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded, size: 18, color: AppColors.warning),
                      SizedBox(width: 10),
                      Text('Make Captain'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'VICE_CAPTAIN',
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 18, color: AppColors.info),
                      SizedBox(width: 10),
                      Text('Make Vice Captain'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'WICKETKEEPER',
                  child: Row(
                    children: [
                      Icon(Icons.sports_baseball_outlined,
                          size: 18, color: AppColors.pitchGreen),
                      SizedBox(width: 10),
                      Text('Make Wicketkeeper'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'PLAYER',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18),
                      SizedBox(width: 10),
                      Text('Set as Player'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'REMOVE',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 10),
                      Text('Remove from Team',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    if (member.playerAvatar != null && member.playerAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(member.playerAvatar!),
        backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade200,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    String label;
    IconData? icon;

    switch (role.toUpperCase()) {
      case 'CAPTAIN':
        bg = AppColors.warning.withOpacity(0.14);
        text = AppColors.warning;
        label = 'C';
        icon = Icons.star_rounded;
        break;
      case 'VICE_CAPTAIN':
        bg = AppColors.info.withOpacity(0.14);
        text = AppColors.info;
        label = 'VC';
        break;
      case 'WICKETKEEPER':
        bg = AppColors.pitchGreen.withOpacity(0.14);
        text = AppColors.pitchGreen;
        label = 'WK';
        break;
      default:
        bg = AppColors.primary.withOpacity(0.08);
        text = AppColors.primary;
        label = member.playingRole?.replaceAll('_', ' ') ?? 'Player';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlayingStyle() {
    final List<String> parts = [];
    if (member.playingRole != null && member.playingRole!.isNotEmpty) {
      parts.add(member.playingRole!.replaceAll('_', ' ').toLowerCase());
    }
    if (member.battingStyle != null && member.battingStyle!.isNotEmpty) {
      parts.add(member.battingStyle!.replaceAll('_', ' ').toLowerCase());
    }
    if (parts.isEmpty) return 'Cricket Player';
    return parts.join(' • ');
  }
}
