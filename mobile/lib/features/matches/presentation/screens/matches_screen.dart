import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';
import '../providers/match_provider.dart';
import '../widgets/match_card.dart';

/// Main matches screen featuring tab navigation for Live, Upcoming, and Completed
/// cricket fixtures, keyword search filtering, pull-to-refresh, and FAB for creating matches.
class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

  final List<_MatchTabInfo> _tabs = const [
    _MatchTabInfo(label: 'Live', tabKey: 'LIVE', icon: Icons.sensors_rounded),
    _MatchTabInfo(label: 'Upcoming', tabKey: 'UPCOMING', icon: Icons.schedule_rounded),
    _MatchTabInfo(label: 'Completed', tabKey: 'COMPLETED', icon: Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index];
    ref.read(matchesListProvider.notifier).setSelectedTab(tab.tabKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matchState = ref.watch(matchesListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: _isSearchActive
            ? _buildSearchTextField(isDark)
            : Text(
                'Matches',
                style: (isDark ? AppTextStyles.titleLargeDark : AppTextStyles.titleLargeLight)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
        centerTitle: false,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            tooltip: _isSearchActive ? 'Close Search' : 'Search Matches',
            onPressed: () {
              setState(() {
                if (_isSearchActive) {
                  _searchController.clear();
                  ref.read(matchesListProvider.notifier).clearSearch();
                  _isSearchActive = false;
                } else {
                  _isSearchActive = true;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: _tabs.map((t) {
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(t.label),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(matchesListProvider.notifier).loadMatches(refresh: true);
        },
        child: _buildBody(context, matchState, isDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createMatch),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Start Match',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildSearchTextField(bool isDark) {
    return TextField(
      controller: _searchController,
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: (isDark ? AppTextStyles.bodyMediumDark : AppTextStyles.bodyMediumLight)
          .copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Search by team, ground, tournament...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
          fontSize: 14,
        ),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  ref.read(matchesListProvider.notifier).clearSearch();
                },
              )
            : null,
      ),
      onChanged: (val) {
        ref.read(matchesListProvider.notifier).setSearchQuery(val);
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MatchListState state,
    bool isDark,
  ) {
    if (state.isLoading && state.matches.isEmpty) {
      return const LoadingWidget(message: 'Loading cricket matches...');
    }

    if (state.errorMessage != null && state.matches.isEmpty) {
      return AppErrorWidget(
        title: 'Unable to Load Matches',
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(matchesListProvider.notifier).loadMatches(refresh: true),
      );
    }

    if (state.matches.isEmpty) {
      final tabTitle = _tabs[_tabController.index].label;
      return EmptyStateWidget(
        icon: Icons.sports_cricket_outlined,
        title: state.searchQuery.isNotEmpty
            ? 'No matches found'
            : 'No $tabTitle Matches',
        subtitle: state.searchQuery.isNotEmpty
            ? 'No matches found for "${state.searchQuery}". Try adjusting your search term.'
            : 'There are currently no matches in $tabTitle state. Start a new match to score live on Cricket Hub!',
        actionText: 'Start Match',
        actionIcon: Icons.add_circle_outline_rounded,
        onActionPressed: () => context.push(AppRoutes.createMatch),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
      itemCount: state.matches.length,
      itemBuilder: (context, index) {
        final match = state.matches[index];
        return MatchCard(
          match: match,
          onTap: () {
            context.push('/matches/${match.id}');
          },
        );
      },
    );
  }
}

class _MatchTabInfo {
  final String label;
  final String tabKey;
  final IconData icon;

  const _MatchTabInfo({
    required this.label,
    required this.tabKey,
    required this.icon,
  });
}
