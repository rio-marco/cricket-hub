import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/auction_provider.dart';

class CreateAuctionScreen extends ConsumerStatefulWidget {
  const CreateAuctionScreen({super.key});

  @override
  ConsumerState<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends ConsumerState<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purseController = TextEditingController(text: '10000000');
  final _basePriceController = TextEditingController(text: '100000');
  final _incrementController = TextEditingController(text: '100000');
  final _minSquadController = TextEditingController(text: '11');
  final _maxSquadController = TextEditingController(text: '25');
  final Set<String> _selectedTeamIds = <String>{};
  String _status = 'DRAFT';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _purseController.dispose();
    _basePriceController.dispose();
    _incrementController.dispose();
    _minSquadController.dispose();
    _maxSquadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamsState = ref.watch(myTeamsProvider);

    return AppScaffold(
      title: 'Create Auction',
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Auction name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return 'Enter at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Purse per team',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _numberValidator(value, minimum: 0),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _basePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Base price',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _numberValidator(value, minimum: 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _incrementController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Bid increment',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _numberValidator(value, minimum: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSquadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min squad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _numberValidator(value, minimum: 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSquadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max squad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _numberValidator(value, minimum: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Initial status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                  DropdownMenuItem(value: 'UPCOMING', child: Text('Upcoming')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Participating teams',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              switch (teamsState) {
                TeamListLoading() => const LoadingWidget(
                    message: 'Loading your teams...',
                  ),
                TeamListError(message: final message) => AppErrorWidget(
                    message: message,
                    onRetry: () => ref.read(myTeamsProvider.notifier).fetchMyTeams(),
                  ),
                TeamListEmpty() => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Create and own at least two teams before starting an auction.',
                    ),
                  ),
                TeamListLoaded(teams: final teams) => Column(
                    children: teams.map((team) {
                      return CheckboxListTile(
                        value: _selectedTeamIds.contains(team.id),
                        title: Text(team.name),
                        subtitle: Text('${team.memberCount} members'),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedTeamIds.add(team.id);
                            } else {
                              _selectedTeamIds.remove(team.id);
                            }
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
              },
              const SizedBox(height: 12),
              Text(
                '${_selectedTeamIds.length} teams selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Create auction',
                icon: Icons.gavel_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _numberValidator(String? value, {required double minimum}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < minimum) return 'Enter a valid number';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least two teams.')),
      );
      return;
    }

    final minSquad = int.tryParse(_minSquadController.text.trim()) ?? 11;
    final maxSquad = int.tryParse(_maxSquadController.text.trim()) ?? 25;
    if (minSquad > maxSquad) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum squad cannot exceed maximum squad.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final snapshot = await ref.read(auctionRepositoryProvider).createAuction(
            name: _nameController.text.trim(),
            teams: _selectedTeamIds.toList(growable: false),
            purseAmount: double.parse(_purseController.text.trim()),
            basePrice: double.parse(_basePriceController.text.trim()),
            minBidIncrement: double.parse(_incrementController.text.trim()).round(),
            minSquadSize: minSquad,
            maxSquadSize: maxSquad,
            status: _status,
          );
      if (!mounted) return;
      ref.invalidate(auctionsListProvider);
      context.go('/auctions/${snapshot.auction.id}');
    } on Failure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
