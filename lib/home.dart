/// LillithApp - the dashboard shown on the home page.
///
/// Summarises where the user is in their cycle: the predicted next period, the
/// current cycle day, and the most recent temperature reading. All values come
/// from [HealthRepository] (loaded from the POD) via [CyclePredictor].

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/temperature_reading.dart';
import 'package:lillith_app/services/cycle_predictor.dart';
import 'package:lillith_app/services/health_repository.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.title});

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _repo = HealthRepository.instance;
  static const _predictor = CyclePredictor();

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

        final prediction = _predictor.predict(
          readings: _repo.readings,
          periods: _repo.periods,
          today: DateTime.now(),
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
                  _PredictionCard(prediction: prediction),
                  const SizedBox(height: 16),
                  _StatsRow(
                    prediction: prediction,
                    latestReading:
                        _repo.readings.isEmpty ? null : _repo.readings.first,
                  ),
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
                Icon(Icons.favorite, color: scheme.onPrimaryContainer),
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
            icon: Icons.calendar_today,
            label: 'Cycle day',
            value: prediction.currentCycleDay?.toString() ?? '—',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.thermostat,
            label: 'Latest temp',
            value: latestReading == null
                ? '—'
                : '${latestReading!.celsius.toStringAsFixed(2)} °C',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.repeat,
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
              Icons.info_outline,
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
            Icons.warning_amber,
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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
