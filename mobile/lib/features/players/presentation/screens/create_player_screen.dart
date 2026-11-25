import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';

/// Form screen to register or update a cricketer's playing credentials.
class CreatePlayerScreen extends ConsumerStatefulWidget {
  final Player? existingPlayer;

  const CreatePlayerScreen({
    super.key,
    this.existingPlayer,
  });

  @override
  ConsumerState<CreatePlayerScreen> createState() => _CreatePlayerScreenState();
}

class _CreatePlayerScreenState extends ConsumerState<CreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();

  String _playingRole = 'BATSMAN';
  String _battingStyle = 'RIGHT_HAND';
  String _bowlingStyle = 'NONE';
  final _jerseyController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  DateTime? _selectedDob;
  bool _isLoading = false;

  final List<Map<String, String>> _roleOptions = [
    {'label': 'Top-Order / Batsman', 'value': 'BATSMAN'},
    {'label': 'Bowler', 'value': 'BOWLER'},
    {'label': 'All-Rounder', 'value': 'ALL_ROUNDER'},
    {'label': 'Wicketkeeper Batsman', 'value': 'WICKETKEEPER'},
  ];

  final List<Map<String, String>> _battingOptions = [
    {'label': 'Right-Hand Bat', 'value': 'RIGHT_HAND'},
    {'label': 'Left-Hand Bat', 'value': 'LEFT_HAND'},
  ];

  final List<Map<String, String>> _bowlingOptions = [
    {'label': 'None (Does not bowl)', 'value': 'NONE'},
    {'label': 'Right-Arm Fast / Pacer', 'value': 'RIGHT_ARM_FAST'},
    {'label': 'Right-Arm Medium Fast', 'value': 'RIGHT_ARM_MEDIUM'},
    {'label': 'Left-Arm Fast / Pacer', 'value': 'LEFT_ARM_FAST'},
    {'label': 'Left-Arm Medium Fast', 'value': 'LEFT_ARM_MEDIUM'},
    {'label': 'Right-Arm Off Spin', 'value': 'RIGHT_ARM_OFF_SPIN'},
    {'label': 'Right-Arm Leg Spin', 'value': 'RIGHT_ARM_LEG_SPIN'},
    {'label': 'Left-Arm Orthodox Spin', 'value': 'LEFT_ARM_ORTHODOX'},
    {'label': 'Left-Arm Chinaman', 'value': 'LEFT_ARM_CHINAMAN'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPlayer != null) {
      _initFromPlayer(widget.existingPlayer!);
    }
  }

  void _initFromPlayer(Player player) {
    _playingRole = player.playingRole;
    _battingStyle = player.battingStyle;
    _bowlingStyle = player.bowlingStyle;
    if (player.jerseyNumber != null) {
      _jerseyController.text = player.jerseyNumber.toString();
    }
    if (player.city != null) {
      _cityController.text = player.city!;
    }
    if (player.bio != null) {
      _bioController.text = player.bio!;
    }
    _selectedDob = player.dateOfBirth;
  }

  @override
  void dispose() {
    _jerseyController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 6),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to manage your player profile.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'playingRole': _playingRole,
      'battingStyle': _battingStyle,
      'bowlingStyle': _bowlingStyle,
      if (_jerseyController.text.trim().isNotEmpty)
        'jerseyNumber': int.tryParse(_jerseyController.text.trim()),
      if (_cityController.text.trim().isNotEmpty)
        'city': _cityController.text.trim(),
      if (_bioController.text.trim().isNotEmpty)
        'bio': _bioController.text.trim(),
      if (_selectedDob != null)
        'dateOfBirth': _selectedDob!.toIso8601String(),
    };

    final notifier = ref.read(createPlayerProvider.notifier);
    Player? result;

    if (widget.existingPlayer != null) {
      result = await notifier.updatePlayer(widget.existingPlayer!.id, payload);
    } else {
      result = await notifier.createPlayer(payload);
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      // Invalidate queries so lists update
      ref.invalidate(myPlayerProfileProvider);
      ref.read(playerListProvider.notifier).fetchPlayers(refresh: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingPlayer != null
                ? 'Profile updated successfully!'
                : 'Player profile created successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      context.pushReplacement('/players/${result.id}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save profile. Please verify your details.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingPlayer != null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Player Profile' : 'Register as Player'),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryLinearGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sports_cricket,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cricket Identity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Specify your playing role, stance, and jersey preferences.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Playing Role Dropdown
              _buildDropdownSection(
                label: 'Playing Role *',
                value: _playingRole,
                items: _roleOptions,
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) setState(() => _playingRole = val);
                },
              ),
              const SizedBox(height: 18),

              // Batting Style Dropdown
              _buildDropdownSection(
                label: 'Batting Stance *',
                value: _battingStyle,
                items: _battingOptions,
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) setState(() => _battingStyle = val);
                },
              ),
              const SizedBox(height: 18),

              // Bowling Style Dropdown
              _buildDropdownSection(
                label: 'Bowling Skill & Arm *',
                value: _bowlingStyle,
                items: _bowlingOptions,
                isDark: isDark,
                onChanged: (val) {
                  if (val != null) setState(() => _bowlingStyle = val);
                },
              ),
              const SizedBox(height: 18),

              // Jersey Number & City in Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _jerseyController,
                      labelText: 'Jersey Number',
                      hintText: 'e.g. 18',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _cityController,
                      labelText: 'City / Location',
                      hintText: 'e.g. Delhi',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Date of Birth Picker Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 2),
                    child: Text(
                      'Date of Birth',
                      style: (isDark
                              ? AppTextStyles.labelLargeDark
                              : AppTextStyles.labelLargeLight)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: _pickDateOfBirth,
                    borderRadius:
                        BorderRadius.circular(AppConstants.inputBorderRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(
                            AppConstants.inputBorderRadius),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDob != null
                                ? DateFormat('dd MMM yyyy')
                                    .format(_selectedDob!)
                                : 'Select Date of Birth',
                            style: (isDark
                                    ? AppTextStyles.bodyMediumDark
                                    : AppTextStyles.bodyMediumLight)
                                .copyWith(
                              color: _selectedDob != null
                                  ? (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)
                                  : (isDark
                                      ? AppColors.textDisabledDark
                                      : AppColors.textDisabledLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bio Field
              AppTextField(
                controller: _bioController,
                labelText: 'Bio & Cricket Career Summary',
                hintText:
                    'Tell teams about your past tournaments, achievements, and club history...',
                prefixIcon: const Icon(Icons.description_outlined),
                maxLines: 4,
                minLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              AppButton(
                text: isEditing
                    ? 'Save Profile Changes'
                    : 'Create Cricket Profile',
                icon: Icons.check_circle_outline,
                isLoading: _isLoading,
                onPressed: _submitForm,
                height: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSection({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(
            label,
            style: (isDark
                    ? AppTextStyles.labelLargeDark
                    : AppTextStyles.labelLargeLight)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius:
                BorderRadius.circular(AppConstants.inputBorderRadius),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor:
                  isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt['value'],
                  child: Text(
                    opt['label']!,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
