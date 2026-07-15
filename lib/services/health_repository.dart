/// LillithApp - load and persist cycle data on the user's Solid POD.
///
/// All temperature readings and period events live in a single JSON document
/// ([healthDataFile]) inside the app's `data` directory on the POD, written
/// **encrypted** so the health data stays private to the POD owner. The
/// repository keeps an in-memory copy as the source of truth for the running
/// session and writes the whole document back after every mutation.
///
/// It is a [ChangeNotifier] so screens can rebuild whenever data changes.

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart'
    show readPod, writePod, ResourceNotExistException;

import 'package:lillith_app/constants/app.dart';
import 'package:lillith_app/models/period_event.dart';
import 'package:lillith_app/models/temperature_reading.dart';

class HealthRepository extends ChangeNotifier {
  HealthRepository._();

  /// Shared instance used across the app's screens.
  static final HealthRepository instance = HealthRepository._();

  final List<TemperatureReading> _readings = [];
  final List<PeriodEvent> _periods = [];

  bool _loaded = false;
  bool _loading = false;
  String? _error;

  /// Readings, newest first.
  List<TemperatureReading> get readings =>
      List.unmodifiable(_readings..sort((a, b) => b.date.compareTo(a.date)));

  /// Period starts, newest first.
  List<PeriodEvent> get periods =>
      List.unmodifiable(_periods..sort((a, b) => b.startDate.compareTo(a.startDate)));

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;

  /// The last load/save error, if any, for the UI to surface.
  String? get error => _error;

  /// Load the cycle document from the POD. Safe to call repeatedly; the first
  /// successful load latches [isLoaded]. A missing document (first run) is not
  /// an error — it just means there is no data yet.
  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final content = await readPod(healthDataFile);
      _decode(content);
      _loaded = true;
    } on ResourceNotExistException {
      // No data file yet — a brand-new user. Start empty.
      _readings.clear();
      _periods.clear();
      _loaded = true;
    } catch (e) {
      _error = 'Could not load your cycle data: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Add or replace the reading for its day, then persist.
  Future<void> addReading(TemperatureReading reading) async {
    _readings
      ..removeWhere((r) => r.date == reading.date)
      ..add(reading);
    await _save();
  }

  /// Remove the reading for [date] (if any), then persist.
  Future<void> removeReading(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    _readings.removeWhere((r) => r.date == day);
    await _save();
  }

  /// Log a period start for its day (deduplicated per day), then persist.
  Future<void> addPeriod(PeriodEvent event) async {
    _periods
      ..removeWhere((p) => p.startDate == event.startDate)
      ..add(event);
    await _save();
  }

  /// Remove the period start logged on [date] (if any), then persist.
  Future<void> removePeriod(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    _periods.removeWhere((p) => p.startDate == day);
    await _save();
  }

  /// Merge imported readings (e.g. from a device export), preferring the
  /// imported value when a day already has one, then persist. Returns the
  /// number of days added or updated.
  Future<int> mergeReadings(Iterable<TemperatureReading> imported) async {
    var changed = 0;
    for (final r in imported) {
      _readings.removeWhere((existing) => existing.date == r.date);
      _readings.add(r);
      changed++;
    }
    if (changed > 0) await _save();
    return changed;
  }

  void _decode(String content) {
    _readings.clear();
    _periods.clear();
    if (content.trim().isEmpty) return;
    final data = jsonDecode(content) as Map<String, dynamic>;
    for (final r in (data['readings'] as List? ?? const [])) {
      _readings.add(TemperatureReading.fromJson(r as Map<String, dynamic>));
    }
    for (final p in (data['periods'] as List? ?? const [])) {
      _periods.add(PeriodEvent.fromJson(p as Map<String, dynamic>));
    }
  }

  String _encode() => jsonEncode({
        'version': 1,
        'readings': _readings.map((r) => r.toJson()).toList(),
        'periods': _periods.map((p) => p.toJson()).toList(),
      });

  /// Write the whole document back to the POD, encrypted, overwriting the
  /// previous version. On failure the in-memory change is kept and the error is
  /// exposed via [error] so the UI can warn that the change was not saved.
  Future<void> _save() async {
    _error = null;
    notifyListeners();
    try {
      await writePod(
        healthDataFile,
        _encode(),
        encrypted: true,
        overwrite: true,
      );
    } catch (e) {
      _error = 'Saved locally but could not sync to your POD: $e';
    } finally {
      notifyListeners();
    }
  }
}
