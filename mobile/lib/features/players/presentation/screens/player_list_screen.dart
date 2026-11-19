import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/player_provider.dart';
import '../widgets/player_card.dart';

/// Comprehensive Players Directory featuring search, role filters, and statistics.
class PlayerListScreen extends ConsumerStatefulWidget {
  const PlayerListScreen({super.key});

  @override
  ConsumerState<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends ConsumerState<PlayerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'ALL';

  final List<Map<String, String>> _roleFilters = [
    {'label': 'All Roles', 'value': 'ALL'},
    {'label': 'Batsmen', 'value': 'BATSMAN'},
    {'label': 'Bowlers', 'value': 'BOWLER'},
    {'label': 'All-Rounders', 'value': 'ALL_ROUNDER'},
    {'label': 'Wicketkeepers', 'value': 'WICKETKEEPER'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final playerListState = ref.watch(playerListProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Players Directory'),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Register Player Profile',
            onPressed: () {
              context.push('/players/create');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(114),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      ref.read(playerListProvider.notifier).search(val);
                    },
                    style: isDark
                        ? AppTextStyles.bodyMediumDark
                        : AppTextStyles.bodyMediumLight,
                    decoration: InputDecoration(
                      hintText: 'Search player by name, city...',
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
                                    .read(playerListProvider.notifier)
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

              // Filter Chips Row
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _roleFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _roleFilters[index];
                    final isSelected = _selectedRole == filter['value'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter['label']!),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark
                            ? const Color(0xFF252525)
                            : const Color(0xFFF0F2F5),
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = filter['value']!;
                          });
                          ref
                              .read(playerListProvider.notifier)
                              .filterByRole(filter['value']!);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildContent(playerListState, isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/players/create'),
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.badge_outlined, color: Colors.white),
        label: const Text(
          'Register Player',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(PlayerListState state, bool isDark) {
    if (state is PlayerListLoading) {
      return _buildShimmerLoading();
    } else if (state is PlayerListError) {
      return AppErrorWidget(
        message: state.message,
        onRetry: () => ref
            .read(playerListProvider.notifier)
            .fetchPlayers(refresh: true),
      );
    } else if (state is PlayerListEmpty) {
      return EmptyStateWidget(
        title: 'No Players Found',
        subtitle:
            'No players match your search filter. Create your cricket profile or try another filter.',
        icon: Icons.person_search_outlined,
        actionText: 'Register Player Profile',
        onActionPressed: () => context.push('/players/create'),
      );
    } else if (state is PlayerListLoaded) {
      if (state.players.isEmpty) {
        return EmptyStateWidget(
          title: 'No Players Available',
          subtitle: 'No cricket players enrolled under this category yet.',
          icon: Icons.sports_cricket_outlined,
          actionText: 'Register Player Profile',
          onActionPressed: () => context.push('/players/create'),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(playerListProvider.notifier)
              .fetchPlayers(refresh: true);
        },
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: 88,
          ),
          itemCount: state.players.length,
          itemBuilder: (context, index) {
            final player = state.players[index];
            return PlayerCard(
              player: player,
              onTap: () {
                context.push('/players/${player.id}');
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
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
              const SizedBox(height: 12),
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
