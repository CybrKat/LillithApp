/// LillithApp - forecast likely symptoms and pain from the user's own history.
///
/// This is the "learning" companion to [CyclePredictor]. Where that predicts
/// *when* the next period is due, this predicts *how the user may feel* in the
/// days ahead, purely from their own logged history — no population averages,
/// no assumptions imposed from outside.
///
/// Method (deliberately simple and explainable):
///  1. For every logged day, work out its **cycle day** — how many days after
///     the most recent period start it fell on.
///  2. Bucket the user's symptoms and pain ratings by cycle day.
///  3. For each of the next few days, look at the matching cycle-day bucket
///     (±1 day tolerance) and compute how often each symptom occurred there and
///     the typical pain. Those frequencies become the forecast.
///
/// The more the user logs, the sharper this gets — the app quietly improves its
/// picture of *their* cycle over time. It is a personal pattern, not medical
/// advice or a diagnosis.

library;

import 'package:lillith_app/models/daily_log.dart';
import 'package:lillith_app/models/period_event.dart';

/// A single symptom's likelihood in the forecast window.

class SymptomLikelihood {
  const SymptomLikelihood({
    required this.symptom,
    required this.probability,
    required this.occurrences,
    required this.sampleDays,
  });

  final Symptom symptom;

  /// 0.0–1.0 chance the symptom shows up on the matching cycle day, from the
  /// user's own history.
  final double probability;

  /// How many past days at this cycle position carried the symptom.
  final int occurrences;

  /// How many past days informed this estimate.
  final int sampleDays;

  /// A friendly percentage for display.
  int get percent => (probability * 100).round();
}

/// The result of a [SymptomPredictor] run.

class SymptomForecast {
  const SymptomForecast({
    required this.likely,
    this.typicalPain,
    required this.loggedDays,
    required this.explanation,
  });

  /// Symptoms likely in the window, most likely first.
  final List<SymptomLikelihood> likely;

  /// Typical pain (0–10) around this cycle position, if ever rated.
  final double? typicalPain;

  /// Total number of days the user has logged (drives confidence messaging).
  final int loggedDays;

  /// A short, warm human-readable summary.
  final String explanation;

  bool get hasData => likely.isNotEmpty || typicalPain != null;
}

class SymptomPredictor {
  const SymptomPredictor({this.windowDays = 7, this.minProbability = 0.34});

  /// How many days ahead to forecast.
  final int windowDays;

  /// Minimum historical frequency for a symptom to be surfaced.
  final double minProbability;

  /// Build a forecast for the days starting at [today], using logged [logs] and
  /// period [periods]. [today] is injected for deterministic testing.
  SymptomForecast predict({
    required List<DailyLog> logs,
    required List<PeriodEvent> periods,
    required DateTime today,
  }) {
    final now = DateTime(today.year, today.month, today.day);
    final starts = periods.map((p) => p.startDate).toList()..sort();
    final loggedDays = logs.length;

    if (starts.isEmpty || logs.length < 3) {
      return SymptomForecast(
        likely: const [],
        loggedDays: loggedDays,
        explanation: starts.isEmpty
            ? 'Log a period start and a few days of symptoms, and LillithApp '
                'will start to learn your personal pattern.'
            : 'Keep logging how you feel each day — after a handful of entries '
                'your personal forecast will appear here.',
      );
    }

    // Index every logged day by its cycle day (days since the last period
    // start on or before it). Days with no preceding start are skipped.
    final byCycleDay = <int, List<DailyLog>>{};
    for (final log in logs) {
      final cd = _cycleDayOf(log.date, starts);
      if (cd == null) continue;
      byCycleDay.putIfAbsent(cd, () => []).add(log);
    }
    if (byCycleDay.isEmpty) {
      return SymptomForecast(
        likely: const [],
        loggedDays: loggedDays,
        explanation: 'Keep logging — a personal forecast is on its way.',
      );
    }

    final currentCycleDay = now.difference(starts.last).inDays + 1;

    // For each symptom take its best (highest) probability across the window's
    // cycle-day buckets. Aggregate pain the same way.
    final best = <Symptom, SymptomLikelihood>{};
    final painValues = <int>[];

    for (var offset = 0; offset < windowDays; offset++) {
      final cd = currentCycleDay + offset;
      final bucket = <DailyLog>[
        ...?byCycleDay[cd - 1],
        ...?byCycleDay[cd],
        ...?byCycleDay[cd + 1],
      ];
      if (bucket.isEmpty) continue;

      for (final log in bucket) {
        if (log.painLevel != null) painValues.add(log.painLevel!);
      }

      for (final symptom in Symptom.values) {
        final occ = bucket.where((l) => l.symptoms.contains(symptom)).length;
        final prob = occ / bucket.length;
        final existing = best[symptom];
        if (existing == null || prob > existing.probability) {
          best[symptom] = SymptomLikelihood(
            symptom: symptom,
            probability: prob,
            occurrences: occ,
            sampleDays: bucket.length,
          );
        }
      }
    }

    final likely = best.values
        .where((l) => l.probability >= minProbability && l.occurrences > 0)
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final typicalPain = painValues.isEmpty
        ? null
        : painValues.reduce((a, b) => a + b) / painValues.length;

    return SymptomForecast(
      likely: likely,
      typicalPain: typicalPain,
      loggedDays: loggedDays,
      explanation: _explain(likely, typicalPain),
    );
  }

  String _explain(List<SymptomLikelihood> likely, double? pain) {
    if (likely.isEmpty && pain == null) {
      return 'No strong pattern yet around this point in your cycle — the more '
          'you log, the clearer it becomes.';
    }
    final parts = <String>[];
    if (likely.isNotEmpty) {
      final names = likely.take(3).map((l) => l.symptom.label.toLowerCase());
      parts.add('Around this point in past cycles you often noted '
          '${_join(names.toList())}.');
    }
    if (pain != null) {
      parts.add('Your pain around now has typically been about '
          '${pain.toStringAsFixed(0)}/10.');
    }
    parts.add('This is your own pattern, not a certainty — be gentle with '
        'yourself.');
    return parts.join(' ');
  }

  String _join(List<String> items) {
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
  }

  /// The cycle day for [date]: 1 + days since the most recent period start on
  /// or before it, or null if [date] precedes all starts.
  int? _cycleDayOf(DateTime date, List<DateTime> sortedStarts) {
    DateTime? start;
    for (final s in sortedStarts) {
      if (!s.isAfter(date)) {
        start = s;
      } else {
        break;
      }
    }
    if (start == null) return null;
    return date.difference(start).inDays + 1;
  }
}
