/// LillithApp - predict the next period from temperature and cycle history.
///
/// The physiology this relies on: after ovulation, the corpus luteum releases
/// progesterone, which raises resting body (and skin) temperature by roughly
/// 0.2–0.5 °C. This produces a *biphasic* temperature curve — a lower
/// follicular phase before ovulation and a higher luteal phase after it. The
/// luteal phase is relatively stable in length (commonly ~12–14 days), so the
/// next period can be estimated as `ovulation day + luteal length`.
///
/// The predictor uses two independent estimates and prefers whichever is best
/// supported by the data:
///
///  1. **Temperature shift** — detect the sustained rise in the current cycle,
///     infer the ovulation day, then add the luteal-phase length.
///  2. **Cycle-length average** — average the gaps between logged period starts
///     and add that to the most recent period start.
///
/// This is a wellness estimate, not a medical or contraceptive tool.

library;

import 'package:lillith_app/models/period_event.dart';
import 'package:lillith_app/models/temperature_reading.dart';

/// How a prediction was derived, so the UI can explain it to the user.

enum PredictionMethod {
  /// Not enough data to predict anything yet.
  insufficientData,

  /// Estimated from the average of logged cycle lengths.
  cycleAverage,

  /// Estimated from a detected post-ovulation temperature shift.
  temperatureShift,
}

/// A rough qualitative confidence in the prediction.

enum PredictionConfidence { none, low, medium, high }

/// The outcome of a [CyclePredictor] run.

class CyclePrediction {
  const CyclePrediction({
    required this.method,
    required this.confidence,
    this.predictedNextPeriod,
    this.lastPeriodStart,
    this.currentCycleDay,
    this.estimatedOvulation,
    this.averageCycleLength,
    required this.explanation,
  });

  final PredictionMethod method;
  final PredictionConfidence confidence;

  /// The estimated start date of the next period, or null if unknown.
  final DateTime? predictedNextPeriod;

  /// The most recent logged period start (the start of the current cycle).
  final DateTime? lastPeriodStart;

  /// Which day of the current cycle today is (day 1 == last period start).
  final int? currentCycleDay;

  /// The ovulation day inferred from the temperature shift, if detected.
  final DateTime? estimatedOvulation;

  /// The average logged cycle length in days, if computable.
  final double? averageCycleLength;

  /// A short human-readable description of how the estimate was made.
  final String explanation;

  /// Whole days from [today] until [predictedNextPeriod] (negative if overdue).
  int? daysUntilNextPeriod(DateTime today) {
    if (predictedNextPeriod == null) return null;
    final t = DateTime(today.year, today.month, today.day);
    return predictedNextPeriod!.difference(t).inDays;
  }
}

/// Default luteal-phase length (days) used when it cannot be measured from the
/// user's own history.
const int _defaultLutealLength = 14;

/// Default cycle length (days) used only as a last resort.
const int _defaultCycleLength = 28;

/// Minimum sustained rise (°C) above the follicular baseline that counts as a
/// post-ovulation temperature shift.
const double _shiftThreshold = 0.2;

/// Number of consecutive elevated readings required to confirm a shift (the
/// "three over six" style rule, simplified).
const int _sustainedDays = 3;

class CyclePredictor {
  const CyclePredictor();

  /// Produce a prediction from all logged [readings] and [periods], relative to
  /// [today] (injected so the result is deterministic and testable).
  CyclePrediction predict({
    required List<TemperatureReading> readings,
    required List<PeriodEvent> periods,
    required DateTime today,
  }) {
    final now = DateTime(today.year, today.month, today.day);

    // Order the period starts oldest → newest.
    final starts = periods.map((p) => p.startDate).toList()..sort();

    if (starts.isEmpty) {
      return const CyclePrediction(
        method: PredictionMethod.insufficientData,
        confidence: PredictionConfidence.none,
        explanation: 'Log the day your period starts to begin predicting. '
            'Add daily temperature readings to sharpen the estimate.',
      );
    }

    final lastStart = starts.last;
    final currentCycleDay = now.difference(lastStart).inDays + 1;

    // ── Cycle-length statistics ────────────────────────────────────────────
    final cycleLengths = <int>[
      for (var i = 1; i < starts.length; i++)
        starts[i].difference(starts[i - 1]).inDays,
    ].where((d) => d > 10 && d < 90).toList(); // drop implausible gaps

    final avgCycleLength = cycleLengths.isEmpty
        ? null
        : cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;

    final cycleAverageEstimate = lastStart
        .add(Duration(days: (avgCycleLength ?? _defaultCycleLength).round()));

    // ── Temperature-shift estimate for the current cycle ───────────────────
    final lutealLength =
        _historicalLutealLength(readings, starts) ?? _defaultLutealLength;
    final ovulation = _detectOvulation(
      readings: readings,
      cycleStart: lastStart,
      today: now,
    );
    final shiftEstimate = ovulation?.add(Duration(days: lutealLength));

    // ── Choose the best-supported estimate ─────────────────────────────────
    if (shiftEstimate != null) {
      return CyclePrediction(
        method: PredictionMethod.temperatureShift,
        confidence: cycleLengths.length >= 2
            ? PredictionConfidence.high
            : PredictionConfidence.medium,
        predictedNextPeriod: shiftEstimate,
        lastPeriodStart: lastStart,
        currentCycleDay: currentCycleDay,
        estimatedOvulation: ovulation,
        averageCycleLength: avgCycleLength,
        explanation:
            'A sustained temperature rise around ${_fmt(ovulation!)} suggests '
            'ovulation. Adding a $lutealLength-day luteal phase puts your next '
            'period near ${_fmt(shiftEstimate)}.',
      );
    }

    if (avgCycleLength != null) {
      return CyclePrediction(
        method: PredictionMethod.cycleAverage,
        confidence: cycleLengths.length >= 3
            ? PredictionConfidence.high
            : (cycleLengths.length >= 2
                ? PredictionConfidence.medium
                : PredictionConfidence.low),
        predictedNextPeriod: cycleAverageEstimate,
        lastPeriodStart: lastStart,
        currentCycleDay: currentCycleDay,
        averageCycleLength: avgCycleLength,
        explanation:
            'Based on your average cycle of ${avgCycleLength.toStringAsFixed(1)} '
            'days across ${cycleLengths.length} recorded '
            '${cycleLengths.length == 1 ? "cycle" : "cycles"}. Keep logging '
            'temperatures to enable ovulation-based prediction.',
      );
    }

    // Exactly one period logged and no temperature shift yet: fall back to the
    // textbook 28-day cycle so the user still sees a tentative date.
    return CyclePrediction(
      method: PredictionMethod.cycleAverage,
      confidence: PredictionConfidence.low,
      predictedNextPeriod: cycleAverageEstimate,
      lastPeriodStart: lastStart,
      currentCycleDay: currentCycleDay,
      explanation:
          'Only one period logged, so this uses a typical $_defaultCycleLength-day '
          'cycle. Log another period or daily temperatures to personalise it.',
    );
  }

  /// Detect the ovulation day within the current cycle from a sustained
  /// temperature rise, or null if no clear shift is present yet.
  ///
  /// Method: take the readings from [cycleStart] up to [today], establish a
  /// follicular baseline from the earliest readings, then find the first day
  /// after which [_sustainedDays] consecutive readings sit at least
  /// [_shiftThreshold] °C above that baseline. Ovulation is taken as the day
  /// before that rise begins.
  DateTime? _detectOvulation({
    required List<TemperatureReading> readings,
    required DateTime cycleStart,
    required DateTime today,
  }) {
    final cycle = readings
        .where((r) => !r.date.isBefore(cycleStart) && !r.date.isAfter(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Need a few baseline days plus the sustained window to judge a shift.
    if (cycle.length < 4 + _sustainedDays) return null;

    // Baseline: the mean of the follicular readings. Use up to the first 5
    // readings, but never more than half the cycle so a late start still works.
    final baselineCount = cycle.length ~/ 2 < 5 ? cycle.length ~/ 2 : 5;
    if (baselineCount < 3) return null;
    final baseline = cycle
            .take(baselineCount)
            .map((r) => r.celsius)
            .reduce((a, b) => a + b) /
        baselineCount;

    for (var i = baselineCount; i <= cycle.length - _sustainedDays; i++) {
      final window = cycle.sublist(i, i + _sustainedDays);
      final sustained =
          window.every((r) => r.celsius >= baseline + _shiftThreshold);
      if (sustained) {
        // Ovulation is conventionally the day before the temperature rise.
        final riseDay = cycle[i].date;
        return riseDay.subtract(const Duration(days: 1));
      }
    }
    return null;
  }

  /// Estimate the user's typical luteal-phase length by measuring, for each
  /// completed past cycle, the gap between its detected ovulation and the next
  /// period start. Returns null if no such measurement is possible.
  int? _historicalLutealLength(
    List<TemperatureReading> readings,
    List<DateTime> starts,
  ) {
    final lengths = <int>[];
    for (var i = 0; i < starts.length - 1; i++) {
      final cycleStart = starts[i];
      final nextStart = starts[i + 1];
      final ov = _detectOvulation(
        readings: readings,
        cycleStart: cycleStart,
        today: nextStart.subtract(const Duration(days: 1)),
      );
      if (ov != null) {
        final len = nextStart.difference(ov).inDays;
        if (len >= 9 && len <= 17) lengths.add(len);
      }
    }
    if (lengths.isEmpty) return null;
    return (lengths.reduce((a, b) => a + b) / lengths.length).round();
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
