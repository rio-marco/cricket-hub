import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/team_provider.dart';
import '../widgets/team_card.dart';

/// Teams Directory and Squad Management Screen with My Teams and All Teams tabs.
class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allTeamsState = ref.watch(teamsListProvider);
    final myTeamsState = ref.watch(myTeamsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Cricket Teams'),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(teamsListProvider.notifier).search(val);
                    },
                    style: isDark
                        ? AppTextStyles.bodyMediumDark
                        : AppTextStyles.bodyMediumLight,
                    decoration: InputDecoration(
                      hintText: 'Search teams by name or city...',
                      hintStyle: (isDark
                              ? AppTextStyles.bodyMediumDark
                              : AppTextStyles.bodyMediumLight)
                          .copyWith(
                        color: isDark
                            ? AppColors.textDisabledDark
                            : AppColors.textDisabledLight,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(teamsListProvider.notifier)
                                    .search('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // Tab Bar (All Teams / My Teams)
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
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'All Teams'),
                  Tab(text: 'My Teams'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: ALL TEAMS
          _buildTeamListTab(
            allTeamsState,
            onRefresh: () async {
              await ref
                  .read(teamsListProvider.notifier)
                  .fetchTeams(refresh: true);
            },
            emptyMessage: 'No teams found matching your query.',
            emptyActionText: 'Create New Team',
            onEmptyAction: () => context.push(AppRoutes.createTeam),
            hasNextPage: allTeamsState is TeamListLoaded
                ? allTeamsState.hasNextPage
                : false,
            onLoadMore: _isLoadingMore
                ? null
                : () async {
                    setState(() => _isLoadingMore = true);
                    await ref.read(teamsListProvider.notifier).loadMore();
                    if (mounted) setState(() => _isLoadingMore = false);
                  },
          ),

          // TAB 2: MY TEAMS
          _buildTeamListTab(
            myTeamsState,
            onRefresh: () async {
              await ref.read(myTeamsProvider.notifier).fetchMyTeams();
            },
            emptyMessage: "You haven't created or joined any teams yet.",
            emptyActionText: 'Create Your Team',
            onEmptyAction: () => context.push(AppRoutes.createTeam),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTeam),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create Team',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamListTab(
    TeamListState state, {
    required Future<void> Function() onRefresh,
    required String emptyMessage,
    required String emptyActionText,
    required VoidCallback onEmptyAction,
    bool hasNextPage = false,
    Future<void> Function()? onLoadMore,
  }) {
    if (state is TeamListLoading) {
      return _buildShimmerLoading();
    } else if (state is TeamListError) {
      return AppErrorWidget(
        message: state.message,
        onRetry: onRefresh,
      );
    } else if (state is TeamListEmpty) {
      return EmptyStateWidget(
        title: 'No Teams Found',
        subtitle: emptyMessage,
        icon: Icons.groups_outlined,
        actionText: emptyActionText,
        onActionPressed: onEmptyAction,
      );
    } else if (state is TeamListLoaded) {
      if (state.teams.isEmpty) {
        return EmptyStateWidget(
          title: 'No Teams Available',
          subtitle: emptyMessage,
          icon: Icons.groups_outlined,
          actionText: emptyActionText,
          onActionPressed: onEmptyAction,
        );
      }

      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: 88, // Space for FAB
          ),
          itemCount: state.teams.length + (hasNextPage ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasNextPage && index == state.teams.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (hasNextPage && index == state.teams.length - 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onLoadMore?.call();
              });
            }

            final team = state.teams[index];
            return TeamCard(
              team: team,
              onTap: () {
                context.push('/teams/${team.id}');
              },
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
