import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/statistics_filter.dart';

class StatisticsFilterBar extends StatelessWidget {
  final StatisticsFilter filter;
  final ValueChanged<StatisticsFilter> onChanged;

  const StatisticsFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    final seasons = <int?>[
      null,
      currentYear,
      currentYear - 1,
      currentYear - 2,
      currentYear - 3,
      currentYear - 4,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: <Widget>[
            FilterChip(
              label: const Text('All formats'),
              selected: filter.format == null,
              onSelected: (_) => onChanged(filter.copyWith(clearFormat: true)),
            ),
            for (final format in <String>['T10', 'T20', 'ODI', 'CUSTOM'])
              FilterChip(
                label: Text(format),
                selected: filter.format == format,
                onSelected: (_) => onChanged(filter.copyWith(format: format)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: DropdownButton<int?>(
                  value: filter.season,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: Text(
                    'All seasons',
                    style: isDark
                        ? AppTextStyles.bodyMediumDark
                        : AppTextStyles.bodyMediumLight,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('All seasons'),
                    ),
                    for (final season in seasons.skip(1))
                      DropdownMenuItem<int?>(
                        value: season,
                        child: Text('$season season'),
                      ),
                  ],
                  onChanged: (season) =>
                      onChanged(season == null ? filter.copyWith(clearSeason: true) : filter.copyWith(season: season)),
                ),
              ),
            ),
            if (filter != const StatisticsFilter())
              TextButton.icon(
                onPressed: () => onChanged(const StatisticsFilter()),
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Clear'),
              ),
          ],
        ),
      ],
    );
  }
}
