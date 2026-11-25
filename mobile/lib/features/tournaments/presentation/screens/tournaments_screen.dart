import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/empty_state_widget.dart';
import 'package:mobile/core/widgets/error_widget.dart';
import 'package:mobile/core/widgets/loading_widget.dart';
import '../providers/tournament_provider.dart';
import '../widgets/tournament_card.dart';

/// Tournament listing screen featuring status tabs (All, Live, Upcoming, Completed),
/// real-time search filtering, pull-to-refresh, and FAB for creating new tournaments.
class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchActive = false;

  final List<_TournamentTab> _tabs = const [
    _TournamentTab(label: 'All', status: 'ALL'),
    _TournamentTab(label: 'Live', status: 'IN_PROGRESS'),
    _TournamentTab(label: 'Upcoming', status: 'REGISTRATION_OPEN'),
    _TournamentTab(label: 'Completed', status: 'COMPLETED'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final selectedTab = _tabs[_tabController.index];
    ref.read(tournamentsListProvider.notifier).setStatusFilter(selectedTab.status);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(tournamentsListProvider.notifier).setSearchQuery(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listState = ref.watch(tournamentsListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: _isSearchActive
            ? _buildSearchTextField(isDark)
            : Text(
                'Tournaments',
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
            tooltip: _isSearchActive ? 'Close Search' : 'Search Tournaments',
            onPressed: () {
              setState(() {
                if (_isSearchActive) {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  ref.read(tournamentsListProvider.notifier).clearSearch();
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
              tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(tournamentsListProvider.notifier).loadTournaments(refresh: true);
        },
        child: _buildBody(context, listState, isDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTournament),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Host Tournament',
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
        hintText: 'Search tournament name or city...',
        hintStyle: TextStyle(
          color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
          fontSize: 14,
        ),
        border: InputBorder.none,
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchDebounce?.cancel();
                  _searchController.clear();
                  ref.read(tournamentsListProvider.notifier).clearSearch();
                },
              )
            : null,
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildBody(
    BuildContext context,
    TournamentListState state,
    bool isDark,
  ) {
    if (state.isLoading && state.tournaments.isEmpty) {
      return const LoadingWidget(message: 'Loading cricket tournaments...');
    }

    if (state.errorMessage != null && state.tournaments.isEmpty) {
      return AppErrorWidget(
        title: 'Unable to Load Tournaments',
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(tournamentsListProvider.notifier).loadTournaments(refresh: true),
      );
    }

    if (state.tournaments.isEmpty) {
      final tabName = _tabs[_tabController.index].label;
      return EmptyStateWidget(
        icon: Icons.emoji_events_outlined,
        title: state.searchQuery.isNotEmpty
            ? 'No matches found'
            : 'No $tabName Tournaments',
        subtitle: state.searchQuery.isNotEmpty
            ? 'We couldn\'t find any tournament matching "${state.searchQuery}". Try different keywords.'
            : 'There are currently no tournaments under the $tabName category. Create one and invite cricket teams!',
        actionText: 'Host Tournament',
        actionIcon: Icons.add_circle_outline_rounded,
        onActionPressed: () => context.push(AppRoutes.createTournament),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
      itemCount: state.tournaments.length + (state.hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.tournaments.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(tournamentsListProvider.notifier).loadMore();
            }
          });
          return const SizedBox(height: 24);
        }

        final tournament = state.tournaments[index];
        return TournamentCard(
          tournament: tournament,
          onTap: () {
            context.push('/tournaments/${tournament.id}');
          },
        );
      },
    );
  }
}

class _TournamentTab {
  final String label;
  final String status;
  const _TournamentTab({required this.label, required this.status});
}
