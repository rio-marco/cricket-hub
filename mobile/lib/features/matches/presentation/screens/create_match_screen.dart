import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import '../../../tournaments/presentation/providers/tournament_provider.dart';
import '../providers/match_provider.dart';

/// Screen form to create a new match fixture with opposing teams, overs, ball type, and schedule.
class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  // Tournament selector (optional)
  String? _selectedTournamentId;
  String? _selectedTournamentName;

  // Teams
  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();

  // Match Format & Overs
  String _matchFormat = 'T20'; // T10, T20, ODI, CUSTOM
  final _oversController = TextEditingController(text: '20');
  String _ballType = 'WHITE'; // TENNIS, WHITE, RED

  // Location & Schedule
  final _venueController = TextEditingController();
  final _cityController = TextEditingController();
  DateTime _matchDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _matchTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    _oversController.dispose();
    _venueController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onFormatChanged(String format) {
    setState(() {
      _matchFormat = format;
      switch (format) {
        case 'T10':
          _oversController.text = '10';
          break;
        case 'T20':
          _oversController.text = '20';
          break;
        case 'ODI':
          _oversController.text = '50';
          break;
        case 'CUSTOM':
          _oversController.text = '15';
          break;
      }
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _matchTime,
      );

      if (pickedTime != null) {
        setState(() {
          _matchDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _matchTime = pickedTime;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final teamA = _teamAController.text.trim();
    final teamB = _teamBController.text.trim();

    if (teamA.toLowerCase() == teamB.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team A and Team B must be different opposing teams')),
      );
      return;
    }

    final overs = int.tryParse(_oversController.text.trim()) ?? 20;

    final data = <String, dynamic>{
      'teamA': {
        'id': 'team_a_${DateTime.now().millisecondsSinceEpoch}',
        'name': teamA,
      },
      'teamB': {
        'id': 'team_b_${DateTime.now().millisecondsSinceEpoch}',
        'name': teamB,
      },
      'format': _matchFormat,
      'totalOvers': overs,
      'ballType': _ballType,
      'venue': _venueController.text.trim().isNotEmpty
          ? _venueController.text.trim()
          : 'Local Ground',
      'city': _cityController.text.trim().isNotEmpty
          ? _cityController.text.trim()
          : 'Mumbai',
      'matchDate': _matchDate.toIso8601String(),
      'status': 'UPCOMING',
      'currentInnings': 1,
      if (_selectedTournamentId != null)
        'tournament': {
          'id': _selectedTournamentId,
          'name': _selectedTournamentName,
        },
    };

    final newMatch = await ref.read(matchActionProvider.notifier).createMatch(data);

    if (newMatch != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newMatch.teamAName} vs ${newMatch.teamBName} created!'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.read(matchesListProvider.notifier).loadMatches(refresh: true);
      // Navigate to toss screen for this match
      context.pushReplacement('/matches/${newMatch.id}/toss');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionState = ref.watch(matchActionProvider);
    final tournamentsState = ref.watch(tournamentsListProvider);

    final dateTimeFormatted = DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_matchDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Create Match Fixture',
          style: (isDark ? AppTextStyles.titleLargeDark : AppTextStyles.titleLargeLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament Selector (Optional)
              _buildSectionLabel('Tournament Association (Optional)', isDark),
              const SizedBox(height: 8),
              _buildTournamentDropdown(tournamentsState.tournaments, isDark),

              const SizedBox(height: 20),

              // Opposing Teams Section
              _buildSectionLabel('Opposing Teams *', isDark),
              const SizedBox(height: 10),

              AppTextField(
                controller: _teamAController,
                labelText: 'Team A Name *',
                hintText: 'e.g. Mumbai Warriors',
                prefixIcon: const Icon(Icons.shield_outlined, color: AppColors.primary),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Please enter Team A name' : null,
              ),

              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'VERSUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _teamBController,
                labelText: 'Team B Name *',
                hintText: 'e.g. Marine Drive Strikers',
                prefixIcon: const Icon(Icons.shield_rounded, color: AppColors.secondaryLight),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Please enter Team B name' : null,
              ),

              const SizedBox(height: 24),

              // Match Format & Overs
              _buildSectionLabel('Match Format *', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFormatChip('T10 (10 Ov)', 'T10'),
                  _buildFormatChip('T20 (20 Ov)', 'T20'),
                  _buildFormatChip('ODI (50 Ov)', 'ODI'),
                  _buildFormatChip('Custom Overs', 'CUSTOM'),
                ],
              ),

              if (_matchFormat == 'CUSTOM') ...[
                const SizedBox(height: 14),
                AppTextField(
                  controller: _oversController,
                  labelText: 'Overs Per Innings *',
                  hintText: 'e.g. 15',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.timer_outlined),
                  validator: (v) {
                    final num = int.tryParse(v ?? '');
                    if (num == null || num < 1 || num > 50) {
                      return 'Enter overs between 1 and 50';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 20),

              // Ball Type
              _buildSectionLabel('Ball Type *', isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildBallChip('Tennis Ball', 'TENNIS', Icons.sports_tennis_rounded, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBallChip('White Leather', 'WHITE', Icons.circle_outlined, isDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBallChip('Red Leather', 'RED', Icons.circle, isDark),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Ground Venue and City
              _buildSectionLabel('Venue & City *', isDark),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _venueController,
                      labelText: 'Ground Venue *',
                      hintText: 'e.g. Wankhede Stadium',
                      prefixIcon: const Icon(Icons.stadium_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter venue' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'e.g. Mumbai',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Match Date & Time
              _buildSectionLabel('Schedule Match Time *', isDark),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            dateTimeFormatted,
                            style: (isDark ? AppTextStyles.bodyMediumDark : AppTextStyles.bodyMediumLight)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              AppButton(
                text: 'Create Fixture & Proceed to Toss',
                icon: Icons.sports_cricket,
                isLoading: actionState.isLoading,
                onPressed: _submitForm,
                height: 52,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildTournamentDropdown(List<dynamic> tournaments, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedTournamentId,
          isExpanded: true,
          hint: Text(
            'Standalone Match (No Tournament)',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Standalone Match (No Tournament)'),
            ),
            ...tournaments.map((t) {
              return DropdownMenuItem<String?>(
                value: t.id.toString(),
                child: Text(
                  t.name.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              _selectedTournamentId = val;
              if (val != null) {
                final found = tournaments.firstWhere((t) => t.id == val, orElse: () => null);
                _selectedTournamentName = found?.name;
              } else {
                _selectedTournamentName = null;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildFormatChip(String label, String value) {
    final isSelected = _matchFormat == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onFormatChanged(value),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: const BorderSide(color: AppColors.primary, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildBallChip(String label, String value, IconData icon, bool isDark) {
    final isSelected = _ballType == value;
    return InkWell(
      onTap: () => setState(() => _ballType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
