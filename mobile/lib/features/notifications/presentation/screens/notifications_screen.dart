import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationListProvider);

    return AppScaffold(
      title: 'Notifications',
      centerTitle: false,
      actions: <Widget>[
        IconButton(
          tooltip: 'Notification preferences',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const NotificationPreferencesSheet(),
          ),
        ),
        IconButton(
          tooltip: 'Mark all as read',
          icon: const Icon(Icons.done_all_rounded),
          onPressed: () =>
              ref.read(notificationListProvider.notifier).markAllAsRead(),
        ),
      ],
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationListState state,
  ) {
    if (state.errorMessage != null && state.items.isEmpty) {
      return AppErrorWidget(
        message: state.errorMessage!,
        onRetry: () => ref.read(notificationListProvider.notifier).load(refresh: true),
      );
    }
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingWidget(message: 'Loading notifications...');
    }
    if (state.items.isEmpty) {
      return EmptyStateWidget(
        title: 'No notifications yet',
        subtitle: 'Match reminders, invitations, auction updates, and scores will appear here.',
        icon: Icons.notifications_none_rounded,
        actionText: 'Refresh',
        onActionPressed: () =>
            ref.read(notificationListProvider.notifier).load(refresh: true),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationListProvider.notifier).load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              state.hasMore &&
              !state.isLoadingMore) {
            unawaited(ref.read(notificationListProvider.notifier).load());
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: LoadingWidget(),
              );
            }
            return _NotificationTile(notification: state.items[index]);
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Card(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(notification.isRead ? 0.08 : 0.18),
          child: Icon(
            _categoryIcon(notification.category),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          notification.title,
          style: (isDark ? AppTextStyles.titleMediumDark : AppTextStyles.titleMediumLight)
              .copyWith(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
            color: primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                notification.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: (isDark
                        ? AppTextStyles.bodySmallDark
                        : AppTextStyles.bodySmallLight)
                    .copyWith(color: secondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    _relativeTime(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: secondary,
                        ),
                  ),
                  if (!notification.isRead) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete notification',
          icon: const Icon(Icons.delete_outline_rounded),
          color: secondary,
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete notification?'),
                content: const Text('This notification will be removed from your list.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              ref
                  .read(notificationListProvider.notifier)
                  .delete(notification.id);
            }
          },
        ),
        onTap: () => ref
            .read(notificationListProvider.notifier)
            .markAsRead(notification.id),
      ),
    );
  }
}

class NotificationPreferencesSheet extends ConsumerStatefulWidget {
  const NotificationPreferencesSheet({super.key});

  @override
  ConsumerState<NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends ConsumerState<NotificationPreferencesSheet> {
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preferences = await ref.read(notificationsRepositoryProvider).getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(notificationsRepositoryProvider)
          .updatePreferences(_preferences);
      if (!mounted) return;
      ref.invalidate(notificationPreferencesProvider);
      setState(() {
        _preferences = updated;
        _saving = false;
      });
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _saving = false;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _preferences.quietHoursStart : _preferences.quietHoursEnd;
    final time = _parseTime(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _preferences = _preferences.copyWith(
        quietHoursStart: isStart ? _formatTime(picked) : null,
        quietHoursEnd: isStart ? null : _formatTime(picked),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.bottomSheetRadius),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Notification preferences',
                style: isDark
                    ? AppTextStyles.titleLargeDark
                    : AppTextStyles.titleLargeLight,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingWidget(message: 'Loading preferences...'),
                )
              else if (_error != null)
                AppErrorWidget(message: _error!, onRetry: _load)
              else
                Column(
                  children: <Widget>[
                    _switch('Push notifications', _preferences.pushEnabled, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(pushEnabled: value));
                    }),
                    _switch('Team invitations', _preferences.teamInvitations, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(teamInvitations: value));
                    }),
                    _switch('Join requests', _preferences.joinRequests, (value) {
                      setState(() =>
                          _preferences = _preferences.copyWith(joinRequests: value));
                    }),
                    _switch('Tournament updates', _preferences.tournamentUpdates,
                        (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(tournamentUpdates: value));
                    }),
                    _switch('Match reminders', _preferences.matchReminders, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(matchReminders: value));
                    }),
                    _switch('Match results', _preferences.matchResults, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(matchResults: value));
                    }),
                    _switch('Live score updates', _preferences.liveScoreUpdates,
                        (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(liveScoreUpdates: value));
                    }),
                    _switch('Wicket alerts', _preferences.wicketAlerts, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(wicketAlerts: value));
                    }),
                    _switch('Over alerts', _preferences.overAlerts, (value) {
                      setState(() =>
                          _preferences = _preferences.copyWith(overAlerts: value));
                    }),
                    _switch('Innings alerts', _preferences.inningsAlerts, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(inningsAlerts: value));
                    }),
                    _switch('Auction updates', _preferences.auctionUpdates, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(auctionUpdates: value));
                    }),
                    _switch('Quiet hours', _preferences.quietHoursEnabled, (value) {
                      setState(() => _preferences =
                          _preferences.copyWith(quietHoursEnabled: value));
                    }),
                    ListTile(
                      enabled: _preferences.quietHoursEnabled,
                      title: const Text('Quiet hours start'),
                      trailing: Text(_preferences.quietHoursStart),
                      onTap: () => _pickTime(isStart: true),
                    ),
                    ListTile(
                      enabled: _preferences.quietHoursEnabled,
                      title: const Text('Quiet hours end'),
                      trailing: Text(_preferences.quietHoursEnd),
                      onTap: () => _pickTime(isStart: false),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save preferences'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

IconData _categoryIcon(AppNotificationCategory category) {
  switch (category) {
    case AppNotificationCategory.team:
      return Icons.groups_rounded;
    case AppNotificationCategory.tournament:
      return Icons.emoji_events_rounded;
    case AppNotificationCategory.match:
      return Icons.sports_cricket_rounded;
    case AppNotificationCategory.auction:
      return Icons.gavel_rounded;
    case AppNotificationCategory.system:
    case AppNotificationCategory.unknown:
      return Icons.notifications_rounded;
  }
}

String _relativeTime(DateTime? createdAt) {
  if (createdAt == null) return 'Just now';
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return DateFormat.yMMMd().format(createdAt.toLocal());
}

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return const TimeOfDay(hour: 22, minute: 0);
  return TimeOfDay(
    hour: int.tryParse(parts.first) ?? 22,
    minute: int.tryParse(parts.last) ?? 0,
  );
}

String _formatTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
