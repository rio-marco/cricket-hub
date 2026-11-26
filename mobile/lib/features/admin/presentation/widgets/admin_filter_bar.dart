import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

class AdminFilterBar extends StatelessWidget {
  final String search;
  final String status;
  final List<String> statuses;
  final String statusLabel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  const AdminFilterBar({
    super.key,
    this.search = '',
    this.status = '',
    this.statuses = const <String>[],
    this.statusLabel = 'Status',
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: ValueKey<String>('admin-search-$search'),
          initialValue: search,
          labelText: 'Search',
          hintText: 'Search records',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          onFieldSubmitted: onSearchChanged,
          textInputAction: TextInputAction.search,
        ),
        if (statuses.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: DropdownButton<String>(
              value: status.isEmpty ? null : status,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: Text(statusLabel),
              items: [
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('All $statusLabel'),
                ),
                for (final option in statuses)
                  DropdownMenuItem<String>(value: option, child: Text(option)),
              ],
              onChanged: (value) => onStatusChanged(value ?? ''),
            ),
          ),
        ],
      ],
    );
  }
}
