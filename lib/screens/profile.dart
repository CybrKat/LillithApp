/// LillithApp - the reproductive-health profile.
///
/// Cycles are shaped by conditions like endometriosis or PCOS and by fertility
/// treatments such as IVF. Recording them here lets the app frame its notes
/// appropriately and reminds the user when a symptom warrants professional
/// advice. It also hosts the one-tap "load a month of sample data" action so
/// the whole app can be explored (and demoed) instantly.
///
/// Everything is stored encrypted on the user's POD via [HealthRepository].

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/health_profile.dart';
import 'package:lillith_app/services/health_repository.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _repo = HealthRepository.instance;
  final _notesController = TextEditingController();

  final Set<ReproductiveCondition> _conditions = {};
  final Set<FertilityTreatment> _treatments = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _repo.load().then((_) {
      if (mounted) _syncFromRepo();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _syncFromRepo() {
    final p = _repo.profile;
    setState(() {
      _conditions
        ..clear()
        ..addAll(p.conditions);
      _treatments
        ..clear()
        ..addAll(p.treatments);
      _notesController.text = p.notes;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    await _repo.setProfile(
      HealthProfile(
        conditions: _conditions,
        treatments: _treatments,
        notes: _notesController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('Your profile is saved and encrypted on your POD.');
  }

  Future<void> _loadSample() async {
    setState(() => _busy = true);
    await _repo.seedSampleMonth();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack('Loaded a month of sample data. Explore the whole app!');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'My profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Optional, private, and only ever on your own POD. It helps '
              'LillithApp understand what is normal for you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _SampleDataCard(
              hasData: _repo.hasData,
              busy: _busy,
              onLoad: _loadSample,
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              icon: Icons.local_hospital_rounded,
              title: 'Conditions',
              subtitle:
                  'Anything diagnosed that affects your cycle. Tap to select.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ReproductiveCondition.values)
                    FilterChip(
                      label: Text(c.label),
                      selected: _conditions.contains(c),
                      onSelected: _busy
                          ? null
                          : (on) => setState(() {
                                on ? _conditions.add(c) : _conditions.remove(c);
                              }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              icon: Icons.spa_rounded,
              title: 'Fertility',
              subtitle:
                  'Any treatment or goal you want the app to be aware of.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in FertilityTreatment.values)
                    FilterChip(
                      label: Text(t.label),
                      selected: _treatments.contains(t),
                      onSelected: _busy
                          ? null
                          : (on) => setState(() {
                                on ? _treatments.add(t) : _treatments.remove(t);
                              }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              icon: Icons.edit_note_rounded,
              title: 'Notes',
              subtitle: 'Anything else you would like to keep with your data.',
              child: TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'e.g. medications, what your doctor has said…',
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save profile'),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _SampleDataCard extends StatelessWidget {
  const _SampleDataCard({
    required this.hasData,
    required this.busy,
    required this.onLoad,
  });

  final bool hasData;
  final bool busy;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Try it with sample data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasData
                  ? 'You already have data. Loading samples will add a month '
                      'of readings, period starts and symptom logs alongside '
                      'it.'
                  : 'New here? Load a realistic month of readings, period '
                      'starts and symptom logs so you can explore every '
                      'feature straight away.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: busy ? null : onLoad,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Load a month of sample data'),
            ),
          ],
        ),
      ),
    );
  }
}
