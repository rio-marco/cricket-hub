import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_card.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import '../providers/tournament_provider.dart';

/// Multi-step form screen for creating and hosting a new cricket tournament.
class CreateTournamentScreen extends ConsumerStatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  ConsumerState<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends ConsumerState<CreateTournamentScreen> {
  int _currentStep = 0;
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();

  // Step 1: Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bannerUrlController = TextEditingController();

  // Step 2: Format & Ball
  String _tournamentFormat = 'LEAGUE_KNOCKOUT'; // LEAGUE, KNOCKOUT, LEAGUE_KNOCKOUT
  String _ballType = 'WHITE'; // TENNIS, RED, WHITE
  String _matchFormat = 'T20'; // T10, T20, ODI, CUSTOM
  final _customOversController = TextEditingController(text: '20');

  // Step 3: Schedule & Venues
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 21));
  DateTime? _registrationStartDate = DateTime.now();
  DateTime? _registrationEndDate = DateTime.now().add(const Duration(days: 5));
  final _cityController = TextEditingController();
  final _venueController = TextEditingController();
  final List<String> _venues = [];

  // Step 4: Rules & Limits
  final _maxTeamsController = TextEditingController(text: '8');
  final _maxPlayersController = TextEditingController(text: '15');
  final _registrationFeeController = TextEditingController(text: '1000');
  final _rulesController = TextEditingController(
    text: 'Standard ICC T20 Playing conditions apply. Max 4 overs per bowler. Super over in case of tie.',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _bannerUrlController.dispose();
    _customOversController.dispose();
    _cityController.dispose();
    _venueController.dispose();
    _maxTeamsController.dispose();
    _maxPlayersController.dispose();
    _registrationFeeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  void _addVenue() {
    final text = _venueController.text.trim();
    if (text.isNotEmpty && !_venues.contains(text)) {
      setState(() {
        _venues.add(text);
        _venueController.clear();
      });
    }
  }

  void _removeVenue(String venue) {
    setState(() {
      _venues.remove(venue);
    });
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    required void Function(DateTime picked) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  void _onNext() {
    if (_currentStep == 0) {
      if (!_formKeyStep1.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_formKeyStep2.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_formKeyStep3.currentState!.validate()) return;
      if (_venues.isEmpty && _venueController.text.trim().isNotEmpty) {
        _addVenue();
      }
      if (_venues.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one match venue')),
        );
        return;
      }
    } else if (_currentStep == 3) {
      if (!_formKeyStep4.currentState!.validate()) return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _submitTournament();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submitTournament() async {
    final fee = double.tryParse(_registrationFeeController.text.trim()) ?? 0.0;
    final maxTeams = int.tryParse(_maxTeamsController.text.trim()) ?? 8;
    final maxPlayers = int.tryParse(_maxPlayersController.text.trim()) ?? 15;
    final customOvers = int.tryParse(_customOversController.text.trim());

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      if (_bannerUrlController.text.trim().isNotEmpty)
        'banner': _bannerUrlController.text.trim(),
      'format': _tournamentFormat,
      'ballType': _ballType,
      'matchFormat': _matchFormat,
      if (_matchFormat == 'CUSTOM' && customOvers != null)
        'customOvers': customOvers,
      'city': _cityController.text.trim(),
      'venues': _venues,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      if (_registrationStartDate != null)
        'registrationStartDate': _registrationStartDate!.toIso8601String(),
      if (_registrationEndDate != null)
        'registrationEndDate': _registrationEndDate!.toIso8601String(),
      'maxTeams': maxTeams,
      'maxPlayersPerTeam': maxPlayers,
      'registrationFee': fee,
      'rules': _rulesController.text.trim(),
      'status': 'REGISTRATION_OPEN',
    };

    final result = await ref
        .read(tournamentActionProvider.notifier)
        .createTournament(data);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.name} created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Invalidate tournaments list so it refetches
      ref.read(tournamentsListProvider.notifier).loadTournaments(refresh: true);
      context.pop();
    } else if (mounted) {
      final error = ref.read(tournamentActionProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to create tournament.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final actionState = ref.watch(tournamentActionProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Host New Tournament',
          style: (isDark ? AppTextStyles.titleLargeDark : AppTextStyles.titleLargeLight)
              .copyWith(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _onBack,
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Step Progress Indicator Bar
          _buildStepProgressBar(isDark),

          // Main Step Form Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(isDark),
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(isDark, actionState.isLoading),
        ],
      ),
    );
  }

  Widget _buildStepProgressBar(bool isDark) {
    final stepTitles = ['Basic Info', 'Format', 'Schedule', 'Rules', 'Review'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of 5: ${stepTitles[_currentStep]}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                '${((_currentStep + 1) / 5 * 100).toInt()}% Completed',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo(isDark);
      case 1:
        return _buildStep2Format(isDark);
      case 2:
        return _buildStep3Schedule(isDark);
      case 3:
        return _buildStep4Rules(isDark);
      case 4:
      default:
        return _buildStep5Review(isDark);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Basic Info
  // ---------------------------------------------------------------------------
  Widget _buildStep1BasicInfo(bool isDark) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.sports_cricket_rounded,
            title: 'Tournament Details',
            subtitle: 'Provide the tournament title, background details, and cover banner.',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: _nameController,
            labelText: 'Tournament Name *',
            hintText: 'e.g. Mumbai Premier T20 Cup 2026',
            prefixIcon: const Icon(Icons.emoji_events_outlined),
            validator: (v) {
              if (v == null || v.trim().length < 3) {
                return 'Please enter at least 3 characters for the tournament name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _descriptionController,
            labelText: 'Tournament Description',
            hintText: 'Describe the tournament format, sponsor highlights, or prizes...',
            maxLines: 4,
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          const SizedBox(height: 16),

          AppTextField(
            controller: _bannerUrlController,
            labelText: 'Banner Image URL (Optional)',
            hintText: 'https://images.unsplash.com/...',
            prefixIcon: const Icon(Icons.image_outlined),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Format & Ball
  // ---------------------------------------------------------------------------
  Widget _buildStep2Format(bool isDark) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.format_list_bulleted_rounded,
            title: 'Competition Structure',
            subtitle: 'Select tournament structure, cricket ball type, and match overs.',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildSectionLabel('Tournament Format *', isDark),
          const SizedBox(height: 8),
          _buildRadioGroup<String>(
            options: const [
              MapEntry('LEAGUE_KNOCKOUT', 'League + Knockout (Group stages followed by playoffs)'),
              MapEntry('LEAGUE', 'Round Robin League (All teams play each other)'),
              MapEntry('KNOCKOUT', 'Single Knockout (Lose and you are out)'),
            ],
            selected: _tournamentFormat,
            onChanged: (val) => setState(() => _tournamentFormat = val),
            isDark: isDark,
          ),

          const SizedBox(height: 20),
          _buildSectionLabel('Ball Type *', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSelectCard(
                  title: 'Tennis',
                  subtitle: 'Heavy / Light',
                  icon: Icons.sports_tennis_rounded,
                  isSelected: _ballType == 'TENNIS',
                  onTap: () => setState(() => _ballType = 'TENNIS'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectCard(
                  title: 'White Leather',
                  subtitle: 'Colored Kits',
                  icon: Icons.circle_outlined,
                  isSelected: _ballType == 'WHITE',
                  onTap: () => setState(() => _ballType = 'WHITE'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSelectCard(
                  title: 'Red Leather',
                  subtitle: 'Traditional',
                  icon: Icons.circle,
                  isSelected: _ballType == 'RED',
                  onTap: () => setState(() => _ballType = 'RED'),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionLabel('Match Format *', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip('T10 (10 Overs)', 'T10', _matchFormat, (v) => setState(() => _matchFormat = v)),
              const SizedBox(width: 8),
              _buildChoiceChip('T20 (20 Overs)', 'T20', _matchFormat, (v) => setState(() => _matchFormat = v)),
              const SizedBox(width: 8),
              _buildChoiceChip('ODI (50 Overs)', 'ODI', _matchFormat, (v) => setState(() => _matchFormat = v)),
              const SizedBox(width: 8),
              _buildChoiceChip('Custom', 'CUSTOM', _matchFormat, (v) => setState(() => _matchFormat = v)),
            ],
          ),

          if (_matchFormat == 'CUSTOM') ...[
            const SizedBox(height: 16),
            AppTextField(
              controller: _customOversController,
              labelText: 'Overs Per Innings',
              hintText: 'e.g. 15',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.timer_outlined),
              validator: (v) {
                final num = int.tryParse(v ?? '');
                if (num == null || num < 1 || num > 100) {
                  return 'Please enter valid overs (1 to 100)';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Schedule & Venues
  // ---------------------------------------------------------------------------
  Widget _buildStep3Schedule(bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Schedule & Locations',
            subtitle: 'Set tournament timeline, registration dates, and ground venues.',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Tournament Start & End Dates
          _buildSectionLabel('Tournament Dates *', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerTile(
                  label: 'Start Date',
                  value: dateFormat.format(_startDate),
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onPicked: (d) => _startDate = d,
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerTile(
                  label: 'End Date',
                  value: dateFormat.format(_endDate),
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _endDate.isAfter(_startDate) ? _endDate : _startDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    onPicked: (d) => _endDate = d,
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Registration Deadline
          _buildSectionLabel('Registration Period', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerTile(
                  label: 'Registration Opens',
                  value: _registrationStartDate != null
                      ? dateFormat.format(_registrationStartDate!)
                      : 'Today',
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _registrationStartDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: _startDate,
                    onPicked: (d) => _registrationStartDate = d,
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDatePickerTile(
                  label: 'Registration Closes',
                  value: _registrationEndDate != null
                      ? dateFormat.format(_registrationEndDate!)
                      : 'Before Start',
                  onTap: () => _pickDate(
                    context: context,
                    initialDate: _registrationEndDate ?? _startDate.subtract(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: _startDate,
                    onPicked: (d) => _registrationEndDate = d,
                  ),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // City
          AppTextField(
            controller: _cityController,
            labelText: 'Host City / Region *',
            hintText: 'e.g. Mumbai, Bengaluru, Pune',
            prefixIcon: const Icon(Icons.location_city_outlined),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please specify city' : null,
          ),

          const SizedBox(height: 16),

          // Venues list input
          _buildSectionLabel('Grounds & Venues *', isDark),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _venueController,
                  labelText: 'Add Venue',
                  hintText: 'e.g. Wankhede Stadium',
                  prefixIcon: const Icon(Icons.stadium_outlined),
                  onFieldSubmitted: (_) => _addVenue(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _addVenue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),

          if (_venues.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _venues.map((v) {
                return Chip(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  label: Text(
                    v,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
                  onDeleted: () => _removeVenue(v),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Rules & Limits
  // ---------------------------------------------------------------------------
  Widget _buildStep4Rules(bool isDark) {
    return Form(
      key: _formKeyStep4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            icon: Icons.gavel_rounded,
            title: 'Rules & Team Capacity',
            subtitle: 'Define squad caps, registration fees, and tournament regulations.',
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _maxTeamsController,
                  labelText: 'Max Teams *',
                  hintText: '8',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.groups_outlined),
                  validator: (v) {
                    final num = int.tryParse(v ?? '');
                    if (num == null || num < 2 || num > 128) {
                      return 'Between 2 - 128';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: _maxPlayersController,
                  labelText: 'Players / Team *',
                  hintText: '15',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (v) {
                    final num = int.tryParse(v ?? '');
                    if (num == null || num < 7 || num > 30) {
                      return 'Between 7 - 30';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _registrationFeeController,
            labelText: 'Registration Fee (₹) *',
            hintText: '0 for Free Tournament',
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            helperText: 'Enter 0 if tournament participation is free.',
            validator: (v) {
              if (v == null || double.tryParse(v) == null) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          AppTextField(
            controller: _rulesController,
            labelText: 'Tournament Rules & Guidelines',
            hintText: 'Powerplay rules, reporting time, tie breaker, umpire decisions...',
            maxLines: 5,
            prefixIcon: const Icon(Icons.rule_folder_outlined),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: Review Summary
  // ---------------------------------------------------------------------------
  Widget _buildStep5Review(bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          icon: Icons.checklist_rounded,
          title: 'Review Tournament Details',
          subtitle: 'Please check your tournament parameters before publishing.',
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        AppCard(
          hasGradientHeader: true,
          headerTitle: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : 'New Tournament',
          headerSubtitle: '$_tournamentFormat • $_ballType BALL',
          headerLeading: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Format', _tournamentFormat, isDark),
              _buildReviewRow('Match Overs', _matchFormat == 'CUSTOM' ? '${_customOversController.text} Overs' : _matchFormat, isDark),
              _buildReviewRow('Ball Type', '$_ballType Ball', isDark),
              _buildReviewRow('Timeline', '${dateFormat.format(_startDate)} to ${dateFormat.format(_endDate)}', isDark),
              _buildReviewRow('City', _cityController.text.trim(), isDark),
              _buildReviewRow('Venues', _venues.join(', '), isDark),
              _buildReviewRow('Capacity', '${_maxTeamsController.text} Teams (${_maxPlayersController.text} players/team)', isDark),
              _buildReviewRow(
                'Registration Fee',
                _registrationFeeController.text == '0' || _registrationFeeController.text.isEmpty
                    ? 'Free Entry'
                    : '₹${_registrationFeeController.text} per team',
                isDark,
                highlight: true,
              ),
              if (_rulesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Rules & Regulations:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _rulesController.text.trim(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, bool isDark, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                color: highlight
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: (isDark ? AppTextStyles.titleMediumDark : AppTextStyles.titleMediumLight)
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: (isDark ? AppTextStyles.bodySmallDark : AppTextStyles.bodySmallLight)
                    .copyWith(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildSelectCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup<T>({
    required List<MapEntry<T, String>> options,
    required T selected,
    required void Function(T val) onChanged,
    required bool isDark,
  }) {
    return Column(
      children: options.map((opt) {
        final isSelected = opt.key == selected;
        return InkWell(
          onTap: () => onChanged(opt.key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.08)
                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    opt.value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String groupValue,
    void Function(String) onSelect,
  ) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
      side: const BorderSide(color: AppColors.primary, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: AppButton.outlined(
                text: 'Back',
                icon: Icons.arrow_back_rounded,
                onPressed: isLoading ? null : _onBack,
                height: 48,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: AppButton(
              text: _currentStep == 4 ? 'Publish Tournament' : 'Continue',
              icon: _currentStep == 4 ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
              isLoading: isLoading,
              onPressed: _onNext,
              height: 48,
            ),
          ),
        ],
      ),
    );
  }
}
