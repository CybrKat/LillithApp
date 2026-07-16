/// LillithApp - log temperature, period flow, pain and symptoms.
///
/// This is where data enters the app. For the selected day the user can record:
///  * a skin temperature (hand-entered or, in future, imported from a device);
///  * how heavy their period flow is (interactive drop selector);
///  * their pain on the 0–10 scale used in emergency departments;
///  * any symptoms they are feeling (tappable chips).
///
/// Temperature is saved on its own (it feeds the prediction immediately); the
/// flow / pain / symptom log for the day is saved together with one tap. All of
/// it is written encrypted to the user's Solid POD via [HealthRepository].

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/daily_log.dart';
import 'package:lillith_app/models/period_event.dart';
import 'package:lillith_app/models/temperature_reading.dart';
import 'package:lillith_app/services/health_repository.dart';

class LogEntry extends StatefulWidget {
  const LogEntry({super.key});

  @override
  State<LogEntry> createState() => _LogEntryState();
}

class _LogEntryState extends State<LogEntry> {
  final _repo = HealthRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController();

  DateTime _date = _today();
  ReadingSource _source = ReadingSource.manual;
  bool _saving = false;

  // Daily-log state for the selected day.
  FlowIntensity _flow = FlowIntensity.none;
  int? _pain;
  final Set<Symptom> _symptoms = {};

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _repo.load().then((_) {
      if (mounted) _syncFromRepo();
    });
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  /// Pull the stored flow/pain/symptoms for the selected day into local state.
  void _syncFromRepo() {
    final log = _repo.logFor(_date);
    setState(() {
      _flow = log?.flow ?? FlowIntensity.none;
      _pain = log?.painLevel;
      _symptoms
        ..clear()
        ..addAll(log?.symptoms ?? const {});
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: _today(),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _syncFromRepo();
    }
  }

  Future<void> _saveTemperature() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _repo.addReading(
      TemperatureReading(
        date: _date,
        celsius: double.parse(_tempController.text.trim()),
        source: _source,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _tempController.clear();
    _snack('Temperature for ${_fmtDate(_date)} saved to your POD.');
  }

  Future<void> _saveDailyLog() async {
    setState(() => _saving = true);
    await _repo.setDailyLog(
      DailyLog(
        date: _date,
        flow: _flow,
        symptoms: _symptoms,
        painLevel: _pain,
      ),
    );
    // Logging a flow also anchors a period start on the first bleeding day so
    // cycle statistics pick it up, if none is logged near this date.
    if (_flow.isBleeding && !_hasNearbyPeriodStart(_date)) {
      await _repo.addPeriod(PeriodEvent(startDate: _date));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    _snack('Your log for ${_fmtDate(_date)} is saved and encrypted.');
  }

  bool _hasNearbyPeriodStart(DateTime date) {
    return _repo.periods.any(
      (p) => (p.startDate.difference(date).inDays).abs() <= 4,
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DateSelector(date: _date, onTap: _saving ? null : _pickDate),
              const SizedBox(height: 16),
              _flowCard(context),
              const SizedBox(height: 16),
              _painCard(context),
              const SizedBox(height: 16),
              _symptomsCard(context),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _saveDailyLog,
                icon: const Icon(Icons.favorite_rounded),
                label: Text('Save my day (${_fmtDate(_date)})'),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 12),
              _temperatureCard(context),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _importFromDevice,
                icon: const Icon(Icons.watch_rounded),
                label: const Text('Import from ring / watch'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flowCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Period flow',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap how heavy your flow is today.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final f in FlowIntensity.values)
                  _FlowOption(
                    intensity: f,
                    selected: _flow == f,
                    onTap: _saving ? null : () => setState(() => _flow = f),
                    color: scheme.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _painCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Pain', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  _pain == null ? 'Not rated' : '${_pain!} / 10',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'The 0–10 scale nurses use: 0 is no pain, 10 is the worst '
              'imaginable.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: (_pain ?? 0).toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '${_pain ?? 0}',
              onChanged:
                  _saving ? null : (v) => setState(() => _pain = v.round()),
            ),
            if (_pain != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      _saving ? null : () => setState(() => _pain = null),
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _symptomsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Symptoms',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap anything you feel today. We use this to suggest relief and '
              'learn your pattern.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in Symptom.values)
                  FilterChip(
                    avatar: Icon(s.icon, size: 18),
                    label: Text(s.label),
                    selected: _symptoms.contains(s),
                    onSelected: _saving
                        ? null
                        : (on) => setState(() {
                              on ? _symptoms.add(s) : _symptoms.remove(s);
                            }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _temperatureCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Skin temperature',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the resting/overnight skin temperature for the selected '
                'day. This powers your next-period prediction.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temperature',
                  suffixText: '°C',
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null) return 'Enter a number';
                  if (value < 30 || value > 45) {
                    return 'Enter a skin temperature in °C (30–45)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReadingSource>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Source'),
                items: [
                  for (final s in ReadingSource.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: _saving
                    ? null
                    : (s) => setState(() => _source = s ?? _source),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _saving ? null : _saveTemperature,
                icon: const Icon(Icons.thermostat_rounded),
                label: const Text('Save temperature'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _importFromDevice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.watch_rounded),
        title: const Text('Import from device'),
        content: const Text(
          'Direct sync with smart rings and watches (Oura, Samsung, Apple '
          'Watch, and others) is coming soon.\n\n'
          'LillithApp already stores each reading with its source, so once a '
          'device is connected its overnight skin-temperature data will appear '
          'here automatically alongside your manual entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// An interactive flow-intensity option: a column of drops that fill up with
/// the chosen intensity.

class _FlowOption extends StatelessWidget {
  const _FlowOption({
    required this.intensity,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final FlowIntensity intensity;
  final bool selected;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 0 drops for "none" (a dashed circle), else 1–4 drops.
    final drops = intensity.level;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 22,
              child: drops == 0
                  ? Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: scheme.outline,
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < drops; i++)
                          Icon(
                            Icons.water_drop_rounded,
                            size: 12,
                            color: selected ? color : scheme.outline,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              intensity.label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_month_rounded),
        title: const Text('Date'),
        subtitle: Text(_fmtDate(date)),
        trailing: const Icon(Icons.edit_calendar_rounded),
        onTap: onTap,
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
