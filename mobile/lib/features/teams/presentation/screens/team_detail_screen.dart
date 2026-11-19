import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_member.dart';
import '../providers/team_provider.dart';
import '../widgets/member_list_item.dart';

/// Detailed Team Hub featuring squad management, match schedules, and performance statistics.
class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailScreen({
    super.key,
    required this.teamId,
  });

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInvitePlayerDialog(BuildContext context) {
    final playerIdController = TextEditingController();
    final messageController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
        ),
        title: Text(
          'Invite Player',
          style: (isDark
                  ? AppTextStyles.titleMediumDark
                  : AppTextStyles.titleMediumLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: playerIdController,
              decoration: const InputDecoration(
                labelText: 'Player ID or Username',
                hintText: 'Enter player ID...',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Invitation Message (Optional)',
                hintText: 'Join our cricket squad!',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final id = playerIdController.text.trim();
              if (id.isEmpty) return;
              Navigator.of(ctx).pop();

              final success = await ref
                  .read(teamDetailProvider(widget.teamId).notifier)
                  .invitePlayer(id, messageController.text.trim());

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Invitation sent successfully!'
                          : 'Failed to send invitation.',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final teamState = ref.watch(teamDetailProvider(widget.teamId));
    final currentUser = ref.watch(currentUserProvider);

    if (teamState is TeamDetailLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(elevation: 0),
        body: const LoadingWidget(message: 'Loading team details...'),
      );
    } else if (teamState is TeamDetailError) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(elevation: 0),
        body: AppErrorWidget(
          message: teamState.message,
          onRetry: () => ref
              .read(teamDetailProvider(widget.teamId).notifier)
              .loadTeamDetail(),
        ),
      );
    } else if (teamState is TeamDetailLoaded) {
      final team = teamState.team;
      final members = teamState.members;
      final isOwner = currentUser != null && currentUser.id == team.owner;

      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                stretch: true,
                backgroundColor: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Invite Player',
                      onPressed: () => _showInvitePlayerDialog(context),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1B2838),
                              Color(0xFF2C3E50),
                              Color(0xFFFF6B00),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),

                      // Pattern Overlay / Banner Info
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Team Logo
                            _buildBannerLogo(team),
                            const SizedBox(width: 16),

                            // Name & Metadata
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    team.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      if (team.location != null &&
                                          team.location!.isNotEmpty) ...[
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          team.location!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${team.memberCount} Squad',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Members'),
                      Tab(text: 'Matches'),
                      Tab(text: 'Stats'),
                    ],
                  ),
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: MEMBERS
              _buildMembersTab(team, members, isOwner, isDark),

              // TAB 2: MATCHES
              _buildMatchesTab(team, isDark),

              // TAB 3: STATS
              _buildStatsTab(team, isDark),
            ],
          ),
        ),
        bottomNavigationBar: !isOwner
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: AppButton(
                    text: 'Request to Join Squad',
                    icon: Icons.person_add_alt_outlined,
                    onPressed: () async {
                      try {
                        await ref
                            .read(teamRepositoryProvider)
                            .requestToJoin(team.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Join request submitted!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              )
            : null,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBannerLogo(Team team) {
    if (team.logo != null && team.logo!.isNotEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            team.logo!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsLogo(team),
          ),
        ),
      );
    }
    return _buildInitialsLogo(team);
  }

  Widget _buildInitialsLogo(Team team) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        team.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildMembersTab(
    Team team,
    List<TeamMember> members,
    bool isOwner,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Team Info Card
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Team Information',
                    style: (isDark
                            ? AppTextStyles.titleSmallDark
                            : AppTextStyles.titleSmallLight)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (team.createdAt != null)
                    Text(
                      'Est. ${DateFormat('MMM yyyy').format(team.createdAt!)}',
                      style: (isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmallLight)
                          .copyWith(color: AppColors.textSecondaryLight),
                    ),
                ],
              ),
              if (team.description != null && team.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  team.description!,
                  style: isDark
                      ? AppTextStyles.bodyMediumDark
                      : AppTextStyles.bodyMediumLight,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (team.ownerName != null)
                    _buildMetaChip(
                      Icons.person_outline,
                      'Owner',
                      team.ownerName!,
                      isDark,
                    ),
                  if (team.captainName != null)
                    _buildMetaChip(
                      Icons.star_outline,
                      'Captain',
                      team.captainName!,
                      isDark,
                    ),
                  if (team.wicketkeeperName != null)
                    _buildMetaChip(
                      Icons.sports_baseball_outlined,
                      'WK',
                      team.wicketkeeperName!,
                      isDark,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Squad Header & Invite Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Squad Players (${members.length})',
              style: (isDark
                      ? AppTextStyles.titleMediumDark
                      : AppTextStyles.titleMediumLight)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            if (isOwner)
              TextButton.icon(
                onPressed: () => _showInvitePlayerDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Invite Player'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (members.isEmpty)
          const EmptyStateWidget(
            title: 'No Players Yet',
            subtitle:
                'Invite players to build your team roster and start competing in matches.',
            icon: Icons.person_add_outlined,
          )
        else
          ...members.map(
            (member) => MemberListItem(
              member: member,
              isOwnerOrCaptain: isOwner,
              onRoleSelected: (role) async {
                final notifier =
                    ref.read(teamDetailProvider(team.id).notifier);
                await notifier.updateMemberRole(member.id, role);
              },
              onRemove: () async {
                final notifier =
                    ref.read(teamDetailProvider(team.id).notifier);
                await notifier.removeMember(member.player);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMetaChip(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(Team team, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent & Upcoming Fixtures',
                style: (isDark
                        ? AppTextStyles.titleSmallDark
                        : AppTextStyles.titleSmallLight)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Upcoming tournament fixtures and past match outcomes.',
                style: (isDark
                        ? AppTextStyles.bodySmallDark
                        : AppTextStyles.bodySmallLight)
                    .copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const EmptyStateWidget(
          title: 'No Matches Scheduled',
          subtitle:
              'This team has no upcoming fixtures or past matches recorded yet.',
          icon: Icons.sports_cricket_outlined,
        ),
      ],
    );
  }

  Widget _buildStatsTab(Team team, bool isDark) {
    final winPercentage = team.winRate;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Win/Loss Ratio Card
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Performance Summary',
                style: (isDark
                        ? AppTextStyles.titleMediumDark
                        : AppTextStyles.titleMediumLight)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Played', '${team.totalMatches}', isDark),
                  _buildStatItem(
                    'Won',
                    '${team.wonMatches}',
                    isDark,
                    color: AppColors.success,
                  ),
                  _buildStatItem(
                    'Lost',
                    '${team.lostMatches}',
                    isDark,
                    color: AppColors.error,
                  ),
                  _buildStatItem(
                    'Win Rate',
                    '${winPercentage.toStringAsFixed(0)}%',
                    isDark,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Linear Progress Bar for Win Rate
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: team.totalMatches > 0
                      ? team.wonMatches / team.totalMatches
                      : 0.0,
                  backgroundColor: isDark
                      ? const Color(0xFF333333)
                      : Colors.grey.shade200,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${team.wonMatches} Wins',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${team.lostMatches} Losses',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverAppBarDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: _bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
