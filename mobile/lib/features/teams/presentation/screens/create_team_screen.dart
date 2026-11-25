import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/team_provider.dart';

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
  final _logoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(createTeamProvider.notifier).createTeam(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          logo: _logoController.text.trim().isEmpty
              ? null
              : _logoController.text.trim(),
        );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null) {
      ref.read(teamsListProvider.notifier).fetchTeams(refresh: true);
      ref.read(myTeamsProvider.notifier).fetchMyTeams();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${result.name}" created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pushReplacement('/teams/${result.id}');
      return;
    }

    final createError = ref.read(createTeamProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          createError?.toString() ?? 'Failed to create team. Please try again.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                labelText: 'Team Name *',
                hintText: 'e.g. Mumbai Strikers CC',
                prefixIcon: const Icon(Icons.shield_outlined),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Team name must be at least 2 characters';
                  }
                  if (value.trim().length > 50) {
                    return 'Team name cannot exceed 50 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _locationController,
                labelText: 'City / Location',
                hintText: 'e.g. Mumbai, Maharashtra',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _logoController,
                labelText: 'Logo URL',
                hintText: 'https://example.com/team-logo.png',
                prefixIcon: const Icon(Icons.link_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasAbsolutePath) {
                    return 'Enter a valid logo URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _descriptionController,
                labelText: 'Team Description & Bio',
                hintText: 'Share your club history, home ground, or motto...',
                prefixIcon: const Icon(Icons.info_outline),
                maxLines: 4,
                minLines: 3,
                validator: (value) {
                  if (value != null && value.length > 1000) {
                    return 'Description cannot exceed 1000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 36),
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
