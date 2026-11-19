import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/team_provider.dart';

/// Screen allowing team leaders and owners to register a new cricket team.
class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  File? _logoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _logoFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.bottomSheetRadius),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Team Logo',
                  style: (isDark
                          ? AppTextStyles.titleMediumDark
                          : AppTextStyles.titleMediumLight)
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: AppColors.primary),
                  title: const Text('Choose from Gallery'),
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary),
                  title: const Text('Take a Photo'),
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                if (_logoFile != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    title: const Text('Remove Photo',
                        style: TextStyle(color: AppColors.error)),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _logoFile = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final teamNotifier = ref.read(createTeamProvider.notifier);
    final result = await teamNotifier.createTeam(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      logoFile: _logoFile,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      // Refresh teams listings
      ref.read(teamsListProvider.notifier).fetchTeams(refresh: true);
      ref.read(myTeamsProvider.notifier).fetchMyTeams();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${result.name}" created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to newly created team detail
      context.pushReplacement('/teams/${result.id}');
    } else if (mounted) {
      final createError = ref.read(createTeamProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(createError?.toString() ??
              'Failed to create team. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Create New Team'),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Picker
              Center(
                child: GestureDetector(
                  onTap: _showImageSourcePicker,
                  child: Stack(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _logoFile != null
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _logoFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Image.file(
                                  _logoFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 40,
                                    color: AppColors.primary.withOpacity(0.8),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Upload Logo',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Tap to choose or take a team badge',
                  style: (isDark
                          ? AppTextStyles.bodySmallDark
                          : AppTextStyles.bodySmallLight)
                      .copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 28),

              // Team Name Field
              AppTextField(
                controller: _nameController,
                labelText: 'Team Name *',
                hintText: 'e.g. Mumbai Strikers CC',
                prefixIcon: const Icon(Icons.shield_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Team name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Team name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // City / Location Field
              AppTextField(
                controller: _locationController,
                labelText: 'City / Location',
                hintText: 'e.g. Mumbai, Maharashtra',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (val) {
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Description Field
              AppTextField(
                controller: _descriptionController,
                labelText: 'Team Description & Bio',
                hintText: 'Share your club history, home ground, or motto...',
                prefixIcon: const Icon(Icons.info_outline),
                maxLines: 4,
                minLines: 3,
                validator: (val) {
                  if (val != null && val.length > 500) {
                    return 'Description cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 36),

              // Submit Button
              AppButton(
                text: 'Register Team',
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
}
