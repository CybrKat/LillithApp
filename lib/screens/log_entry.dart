/// LillithApp - log skin temperature and period starts.
///
/// This screen is where data enters the app. Today it supports hand entry of a
/// daily temperature and logging the day a period started. It also exposes an
/// **Import from device** action: the data model already carries a
/// [ReadingSource] so a future smart-ring/watch sync (e.g. Oura, Apple Watch)
/// can drop its readings straight in via [HealthRepository.mergeReadings]
/// without any storage change.

library;

import 'package:flutter/material.dart';

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

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: _today(),
    );
    if (picked != null) setState(() => _date = picked);
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
    _snack('Temperature for ${_fmtDate(_date)} saved.');
  }

  Future<void> _logPeriodStart() async {
    setState(() => _saving = true);
    await _repo.addPeriod(PeriodEvent(startDate: _date));
    if (!mounted) return;
    setState(() => _saving = false);
    _snack('Period start on ${_fmtDate(_date)} logged.');
  }

  void _importFromDevice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.watch),
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
              _temperatureCard(context),
              const SizedBox(height: 16),
              _periodCard(context),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _importFromDevice,
                icon: const Icon(Icons.watch),
                label: const Text('Import from ring / watch'),
              ),
            ],
          ),
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
                'day.',
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
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Source',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final s in ReadingSource.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: _saving
                    ? null
                    : (s) => setState(() => _source = s ?? _source),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _saveTemperature,
                icon: const Icon(Icons.save),
                label: const Text('Save temperature'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Log the selected day as the first day of your period. This '
              'anchors cycle-length statistics and the next-period estimate.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _saving ? null : _logPeriodStart,
              icon: const Icon(Icons.water_drop),
              label: Text('Period started on ${_fmtDate(_date)}'),
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
        leading: const Icon(Icons.event),
        title: const Text('Date'),
        subtitle: Text(_fmtDate(date)),
        trailing: const Icon(Icons.edit_calendar),
        onTap: onTap,
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
