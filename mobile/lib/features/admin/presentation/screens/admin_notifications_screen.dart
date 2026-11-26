import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_filter_bar.dart';
import '../widgets/admin_section_card.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _broadcastKey = GlobalKey<FormState>();
  final _targetedKey = GlobalKey<FormState>();
  final _broadcastTitle = TextEditingController();
  final _broadcastBody = TextEditingController();
  final _audience = TextEditingController();
  final _targetedTitle = TextEditingController();
  final _targetedBody = TextEditingController();
  final _userIds = TextEditingController();

  static const List<String> _statuses = <String>[
    'PENDING',
    'SENT',
    'DELIVERED',
    'FAILED',
  ];

  @override
  void dispose() {
    _broadcastTitle.dispose();
    _broadcastBody.dispose();
    _audience.dispose();
    _targetedTitle.dispose();
    _targetedBody.dispose();
    _userIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationDeliveriesProvider);
    final action = ref.watch(adminActionProvider);
    _listenToActions(context);

    return AppScaffold(
      title: 'Admin Notifications',
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(adminNotificationDeliveriesProvider.notifier)
            .load(refresh: true),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionCard(
                title: 'Broadcast notification',
                subtitle: 'Send an announcement to an audience',
                children: [
                  Form(
                    key: _broadcastKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _broadcastTitle,
                          labelText: 'Title',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Title is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _broadcastBody,
                          labelText: 'Message',
                          maxLines: 3,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Message is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _audience,
                          labelText: 'Audience',
                          hintText: 'Optional, for example: all_users',
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          text: 'Broadcast',
                          icon: Icons.campaign_outlined,
                          isLoading: action.isSaving,
                          onPressed: () async {
                            if (!_broadcastKey.currentState!.validate()) return;
                            await ref
                                .read(adminActionProvider.notifier)
                                .broadcast(
                                  title: _broadcastTitle.text.trim(),
                                  body: _broadcastBody.text.trim(),
                                  audience: _audience.text.trim().isEmpty
                                      ? null
                                      : _audience.text.trim(),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AdminSectionCard(
                title: 'Send to specific users',
                subtitle: 'Comma-separated user IDs',
                children: [
                  Form(
                    key: _targetedKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _targetedTitle,
                          labelText: 'Title',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Title is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _targetedBody,
                          labelText: 'Message',
                          maxLines: 3,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Message is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _userIds,
                          labelText: 'User IDs',
                          hintText: 'id-1, id-2',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'At least one user ID is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppButton.outlined(
                          text: 'Send to users',
                          icon: Icons.person_search_outlined,
                          isLoading: action.isSaving,
                          onPressed: () async {
                            if (!_targetedKey.currentState!.validate()) return;
                            final ids = _userIds.text
                                .split(',')
                                .map((value) => value.trim())
                                .where((value) => value.isNotEmpty)
                                .toList();
                            await ref
                                .read(adminActionProvider.notifier)
                                .sendToUsers(
                                  userIds: ids,
                                  title: _targetedTitle.text.trim(),
                                  body: _targetedBody.text.trim(),
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AdminFilterBar(
                search: state.search,
                status: state.status,
                statuses: _statuses,
                onSearchChanged: (value) => ref
                    .read(adminNotificationDeliveriesProvider.notifier)
                    .setSearch(value),
                onStatusChanged: (value) => ref
                    .read(adminNotificationDeliveriesProvider.notifier)
                    .setStatus(value),
              ),
              const SizedBox(height: 16),
              if (state.isLoading && state.items.isEmpty)
                const LoadingWidget(message: 'Loading deliveries...')
              else if (state.errorMessage != null && state.items.isEmpty)
                AppErrorWidget(
                  message: state.errorMessage!,
                  onRetry: () => ref
                      .read(adminNotificationDeliveriesProvider.notifier)
                      .load(refresh: true),
                )
              else if (state.items.isEmpty)
                const EmptyStateWidget(
                  title: 'No deliveries found',
                  icon: Icons.send_outlined,
                )
              else
                AdminSectionCard(
                  title: 'Delivery status',
                  subtitle: '${state.total} total',
                  children: [
                    for (final delivery in state.items) ...[
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              delivery.notificationTitle.isEmpty
                                  ? 'Notification'
                                  : delivery.notificationTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                delivery.status.toUpperCase(),
                                delivery.channel.toUpperCase(),
                                delivery.userId,
                              ].where((value) => value.isNotEmpty).join(' • '),
                            ),
                            if (delivery.failureReason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                delivery.failureReason,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (delivery.sentAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat.yMMMd().add_jm().format(
                                    delivery.sentAt!.toLocal(),
                                  ),
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _listenToActions(BuildContext context) {
    ref.listen<AdminActionState>(adminActionProvider, (previous, next) {
      final message = next.successMessage ?? next.errorMessage;
      if (message != null &&
          message != previous?.successMessage &&
          message != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }
}
