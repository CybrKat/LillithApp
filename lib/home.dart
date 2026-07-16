/// LillithApp - the dashboard shown on the home page.
///
/// Summarises where the user is in their cycle: the predicted next period, the
/// current cycle day, and the most recent temperature reading. All values come
/// from [HealthRepository] (loaded from the POD) via [CyclePredictor].

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/temperature_reading.dart';
import 'package:lillith_app/screens/learn.dart' show factOfTheDay;
import 'package:lillith_app/services/cycle_predictor.dart';
import 'package:lillith_app/services/health_repository.dart';
import 'package:lillith_app/services/symptom_predictor.dart';
import 'package:lillith_app/utils/links.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _repo = HealthRepository.instance;
  static const _predictor = CyclePredictor();
  static const _symptomPredictor = SymptomPredictor();
  bool _seeding = false;

  Future<void> _loadSample() async {
    setState(() => _seeding = true);
    await _repo.seedSampleMonth();
    if (!mounted) return;
    setState(() => _seeding = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Loaded a month of sample data — explore every feature!'),
      ),);
  }

  @override
  void initState() {
    super.initState();
    // Kick off the POD load; the AnimatedBuilder rebuilds when it completes.
    _repo.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        if (_repo.isLoading && !_repo.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final now = DateTime.now();
        final prediction = _predictor.predict(
          readings: _repo.readings,
          periods: _repo.periods,
          today: now,
        );
        final forecast = _symptomPredictor.predict(
          logs: _repo.dailyLogs,
          periods: _repo.periods,
          today: now,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_repo.error != null) _ErrorBanner(message: _repo.error!),
                  const _FactOfTheDayCard(),
                  const SizedBox(height: 16),
                  if (!_repo.hasData) ...[
                    _SampleDataPrompt(busy: _seeding, onLoad: _loadSample),
                    const SizedBox(height: 16),
                  ],
                  _PredictionCard(prediction: prediction),
                  const SizedBox(height: 16),
                  _StatsRow(
                    prediction: prediction,
                    latestReading:
                        _repo.readings.isEmpty ? null : _repo.readings.first,
                  ),
                  const SizedBox(height: 16),
                  if (forecast.hasData) _ForecastCard(forecast: forecast),
                  if (forecast.hasData) const SizedBox(height: 16),
                  const _DataOwnershipCard(),
                  const SizedBox(height: 16),
                  const _DisclaimerCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.prediction});

  final CyclePrediction prediction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final next = prediction.predictedNextPeriod;
    final days = prediction.daysUntilNextPeriod(DateTime.now());

    final String headline;
    if (next == null) {
      headline = 'No prediction yet';
    } else if (days == null) {
      headline = _fmtDate(next);
    } else if (days == 0) {
      headline = 'Expected today';
    } else if (days > 0) {
      headline = 'In $days ${days == 1 ? "day" : "days"}';
    } else {
      headline = '${-days} ${days == -1 ? "day" : "days"} overdue';
    }

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Text(
                  'Next period',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const Spacer(),
                _ConfidenceChip(confidence: prediction.confidence),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              headline,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (next != null) ...[
              const SizedBox(height: 4),
              Text(
                _fmtDate(next),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              prediction.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.prediction, required this.latestReading});

  final CyclePrediction prediction;
  final TemperatureReading? latestReading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_today_rounded,
            label: 'Cycle day',
            value: prediction.currentCycleDay?.toString() ?? '—',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.thermostat_rounded,
            label: 'Latest temp',
            value: latestReading == null
                ? '—'
                : '${latestReading!.celsius.toStringAsFixed(2)} °C',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.loop_rounded,
            label: 'Avg cycle',
            value: prediction.averageCycleLength == null
                ? '—'
                : '${prediction.averageCycleLength!.toStringAsFixed(0)} d',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.confidence});

  final PredictionConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final (label, MaterialColor color) = switch (confidence) {
      PredictionConfidence.none => ('No data', Colors.grey),
      PredictionConfidence.low => ('Low confidence', Colors.orange),
      PredictionConfidence.medium => ('Medium confidence', Colors.amber),
      PredictionConfidence.high => ('High confidence', Colors.green),
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.18),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      label: Text(label, style: TextStyle(color: color.shade900)),
    );
  }
}

class _SampleDataPrompt extends StatelessWidget {
  const _SampleDataPrompt({required this.busy, required this.onLoad});

  final bool busy;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: scheme.onTertiaryContainer,),
                const SizedBox(width: 8),
                Text('New here? Try it with sample data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Load a realistic month of readings, period starts and symptom '
              'logs so you can explore every feature straight away. (Also on '
              'the My Profile page.)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: busy ? null : onLoad,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('Load a month of sample data'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactOfTheDayCard extends StatelessWidget {
  const _FactOfTheDayCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fact = factOfTheDay();
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
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Today's health fact",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              fact.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(fact.source.name),
                onPressed: () => openUrl(fact.source.url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});

  final SymptomForecast forecast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Your forecast',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              forecast.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (forecast.likely.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in forecast.likely.take(5))
                    Chip(
                      avatar: Icon(l.symptom.icon, size: 16),
                      label: Text('${l.symptom.label} · ${l.percent}%'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataOwnershipCard extends StatelessWidget {
  const _DataOwnershipCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_rounded, color: scheme.onPrimaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This is yours, and only yours',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Everything you log is encrypted and stored on your own '
                    'Solid POD — not our servers. See the Privacy page to '
                    'share with a doctor or take it back anytime.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'LillithApp gives wellness estimates from your own data. It is '
                'not a medical device and should not be used for contraception '
                'or diagnosis. Your readings stay encrypted on your Solid POD.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
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
