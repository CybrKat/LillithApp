/// Tests for LillithApp's [CyclePredictor].
///
/// These exercise the pure prediction logic deterministically (today is
/// injected), covering the no-data, cycle-average and temperature-shift paths.

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:lillith_app/models/period_event.dart';
import 'package:lillith_app/models/temperature_reading.dart';
import 'package:lillith_app/services/cycle_predictor.dart';

void main() {
  const predictor = CyclePredictor();

  test('no periods logged → insufficient data', () {
    final result = predictor.predict(
      readings: const [],
      periods: const [],
      today: DateTime(2026, 7, 15),
    );
    expect(result.method, PredictionMethod.insufficientData);
    expect(result.predictedNextPeriod, isNull);
  });

  test('regular cycle history → average-based prediction', () {
    final periods = [
      PeriodEvent(startDate: DateTime(2026, 4, 1)),
      PeriodEvent(startDate: DateTime(2026, 4, 29)), // 28 days
      PeriodEvent(startDate: DateTime(2026, 5, 27)), // 28 days
    ];
    final result = predictor.predict(
      readings: const [],
      periods: periods,
      today: DateTime(2026, 6, 10),
    );
    expect(result.method, PredictionMethod.cycleAverage);
    expect(result.averageCycleLength, closeTo(28, 0.01));
    // Last start 27 May + 28 days = 24 June.
    expect(result.predictedNextPeriod, DateTime(2026, 6, 24));
    expect(result.currentCycleDay, 15); // 27 May → 10 Jun inclusive
  });

  test('biphasic temperature shift → ovulation-based prediction', () {
    final start = DateTime(2026, 6, 1);
    // Follicular baseline ~36.3 for 8 days, then a sustained rise to ~36.65.
    final readings = <TemperatureReading>[];
    for (var day = 0; day < 8; day++) {
      readings.add(
        TemperatureReading(
          date: start.add(Duration(days: day)),
          celsius: 36.30,
          source: ReadingSource.ring,
        ),
      );
    }
    for (var day = 8; day < 16; day++) {
      readings.add(
        TemperatureReading(
          date: start.add(Duration(days: day)),
          celsius: 36.65,
          source: ReadingSource.ring,
        ),
      );
    }

    final result = predictor.predict(
      readings: readings,
      periods: [PeriodEvent(startDate: start)],
      today: start.add(const Duration(days: 16)),
    );

    expect(result.method, PredictionMethod.temperatureShift);
    // Rise begins on day index 8 (9 June); ovulation is the day before (8 Jun),
    // plus a 14-day default luteal phase → 22 June.
    expect(result.estimatedOvulation, DateTime(2026, 6, 8));
    expect(result.predictedNextPeriod, DateTime(2026, 6, 22));
  });

  test('flat temperature (no shift) falls back to cycle average', () {
    final periods = [
      PeriodEvent(startDate: DateTime(2026, 5, 1)),
      PeriodEvent(startDate: DateTime(2026, 5, 30)), // 29-day cycle
    ];
    final flat = [
      for (var day = 0; day < 14; day++)
        TemperatureReading(
          date: DateTime(2026, 5, 30).add(Duration(days: day)),
          celsius: 36.4,
        ),
    ];
    final result = predictor.predict(
      readings: flat,
      periods: periods,
      today: DateTime(2026, 6, 12),
    );
    expect(result.method, PredictionMethod.cycleAverage);
    expect(result.predictedNextPeriod, DateTime(2026, 6, 28)); // 30 May + 29
  });
}
