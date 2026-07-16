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
import 'package:lillith_app/models/daily_log.dart';
import 'package:lillith_app/models/health_profile.dart';
import 'package:lillith_app/models/period_event.dart';
import 'package:lillith_app/models/remedy_feedback.dart';
import 'package:lillith_app/models/shopping_list.dart';
import 'package:lillith_app/models/temperature_reading.dart';

class HealthRepository extends ChangeNotifier {
  HealthRepository._();

  /// Shared instance used across the app's screens.
  static final HealthRepository instance = HealthRepository._();

  final List<TemperatureReading> _readings = [];
  final List<PeriodEvent> _periods = [];
  final List<DailyLog> _logs = [];

  /// Remedy verdicts keyed by [RemedyFeedback.id]. A map (not a list) because
  /// there is at most one verdict per remedy and lookups happen per render.
  final Map<String, RemedyFeedback> _feedback = {};

  /// The user's shopping list (remedy items they want to buy).
  final List<ShoppingItem> _shopping = [];

  /// The user's reproductive-health profile (conditions, fertility context).
  HealthProfile _profile = HealthProfile();

  bool _loaded = false;
  bool _loading = false;
  String? _error;

  /// Readings, newest first.
  List<TemperatureReading> get readings =>
      List.unmodifiable(_readings..sort((a, b) => b.date.compareTo(a.date)));

  /// Period starts, newest first.
  List<PeriodEvent> get periods => List.unmodifiable(
        _periods..sort((a, b) => b.startDate.compareTo(a.startDate)),
      );

  /// Daily flow + symptom logs, newest first.
  List<DailyLog> get dailyLogs =>
      List.unmodifiable(_logs..sort((a, b) => b.date.compareTo(a.date)));

  /// The flow + symptom log for [date], or null if that day has none.
  DailyLog? logFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    for (final l in _logs) {
      if (l.date == day) return l;
    }
    return null;
  }

  /// The user's verdict on the remedy identified by [symptomKey] + [title],
  /// defaulting to [RemedyRating.untried] when they have not rated it.
  RemedyRating ratingFor(String symptomKey, String title) =>
      _feedback[RemedyFeedback.idFor(symptomKey, title)]?.rating ??
      RemedyRating.untried;

  /// The shopping list, unbought items first.
  List<ShoppingItem> get shoppingList => List.unmodifiable(
        _shopping..sort((a, b) => (a.bought ? 1 : 0) - (b.bought ? 1 : 0)),
      );

  /// The user's reproductive-health profile.
  HealthProfile get profile => _profile;

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
      _clearAll();
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

  /// Replace the whole flow + symptom log for [log.date], then persist. An
  /// empty log (no flow, no symptoms) removes the day rather than storing a
  /// blank entry, so days the user clears don't linger.
  Future<void> setDailyLog(DailyLog log) async {
    _logs.removeWhere((l) => l.date == log.date);
    if (!log.isEmpty) _logs.add(log);
    await _save();
  }

  /// Set just the flow intensity for [date], keeping any symptoms already
  /// logged that day, then persist.
  Future<void> setFlow(DateTime date, FlowIntensity flow) async {
    final existing = logFor(date) ?? DailyLog(date: date);
    await setDailyLog(existing.copyWith(flow: flow));
  }

  /// Toggle a single [symptom] on [date], keeping the day's flow, then persist.
  Future<void> toggleSymptom(DateTime date, Symptom symptom) async {
    final existing = logFor(date) ?? DailyLog(date: date);
    final next = Set<Symptom>.from(existing.symptoms);
    next.contains(symptom) ? next.remove(symptom) : next.add(symptom);
    await setDailyLog(existing.copyWith(symptoms: next));
  }

  /// Record the user's [rating] of a remedy, then persist. Rating a remedy
  /// [RemedyRating.untried] clears any stored verdict. This is what lets the
  /// Relief screen learn: helped remedies float to the top next time.
  Future<void> rateRemedy(
    String symptomKey,
    String title,
    RemedyRating rating,
  ) async {
    final id = RemedyFeedback.idFor(symptomKey, title);
    if (rating == RemedyRating.untried) {
      _feedback.remove(id);
    } else {
      _feedback[id] = RemedyFeedback(
        symptomKey: symptomKey,
        remedyTitle: title,
        rating: rating,
      );
    }
    await _save();
  }

  /// Add an item to the shopping list (idempotent by name), then persist.
  Future<void> addShoppingItem(ShoppingItem item) async {
    final exists = _shopping.any(
      (s) => s.name.toLowerCase() == item.name.toLowerCase(),
    );
    if (!exists) _shopping.add(item);
    await _save();
  }

  /// Toggle the bought flag on the shopping item named [name], then persist.
  Future<void> toggleBought(String name) async {
    for (var i = 0; i < _shopping.length; i++) {
      if (_shopping[i].name == name) {
        _shopping[i] = _shopping[i].copyWith(bought: !_shopping[i].bought);
        break;
      }
    }
    await _save();
  }

  /// Remove the shopping item named [name], then persist.
  Future<void> removeShoppingItem(String name) async {
    _shopping.removeWhere((s) => s.name == name);
    await _save();
  }

  /// Replace the reproductive-health profile, then persist.
  Future<void> setProfile(HealthProfile profile) async {
    _profile = profile;
    await _save();
  }

  /// Whether any cycle data has been logged yet (used to offer sample data).
  bool get hasData =>
      _readings.isNotEmpty || _periods.isNotEmpty || _logs.isNotEmpty;

  /// Populate the POD with a realistic month of sample data so the app can be
  /// explored (and demoed) end-to-end without hand-entering weeks of readings.
  ///
  /// It writes two period starts, ~35 days of biphasic temperatures, and daily
  /// flow/symptom/pain logs clustered during bleeding and premenstrually — then
  /// persists the whole document through the same encrypted [writePod] path as
  /// real data. Existing entries on the same dates are replaced.
  Future<void> seedSampleMonth() async {
    final base = DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    DateTime daysAgo(int n) => today.subtract(Duration(days: n));

    final start1 = daysAgo(34);
    final start2 = daysAgo(6);

    for (final s in [start1, start2]) {
      _periods.removeWhere((p) => p.startDate == s);
      _periods.add(PeriodEvent(startDate: s));
    }

    // Biphasic temperature curve: cooler follicular phase, ~0.3 °C warmer
    // luteal phase after ovulation (~cycle day 14), with a small deterministic
    // wobble so it looks hand-logged rather than synthetic.
    for (var ago = 34; ago >= 0; ago--) {
      final date = daysAgo(ago);
      final cycleStart = date.isBefore(start2) ? start1 : start2;
      final cycleDay = date.difference(cycleStart).inDays;
      final postOvulation = cycleDay >= 14;
      final wobble = (((ago * 7) % 5) - 2) * 0.03;
      final celsius = (postOvulation ? 36.70 : 36.40) + wobble;
      _readings.removeWhere((r) => r.date == date);
      _readings.add(
        TemperatureReading(
          date: date,
          celsius: double.parse(celsius.toStringAsFixed(2)),
        ),
      );
    }

    void putLog(
      DateTime date, {
      FlowIntensity flow = FlowIntensity.none,
      Set<Symptom> symptoms = const {},
      int? pain,
    }) {
      if (date.isBefore(start1) || date.isAfter(today)) return;
      _logs.removeWhere((l) => l.date == date);
      final log = DailyLog(
        date: date,
        flow: flow,
        symptoms: symptoms,
        painLevel: pain,
      );
      if (!log.isEmpty) _logs.add(log);
    }

    const bleedFlows = [
      FlowIntensity.heavy,
      FlowIntensity.medium,
      FlowIntensity.medium,
      FlowIntensity.light,
      FlowIntensity.spotting,
    ];
    for (final s in [start1, start2]) {
      // Bleeding days: heavier + more painful early, easing off.
      for (var i = 0; i < bleedFlows.length; i++) {
        putLog(
          s.add(Duration(days: i)),
          flow: bleedFlows[i],
          symptoms: {Symptom.cramps, if (i < 2) Symptom.backPain},
          pain: i < 2 ? 6 - i : 3,
        );
      }
      // Premenstrual days: mood, bloating, fatigue, cravings building up.
      for (var i = 1; i <= 3; i++) {
        putLog(
          s.subtract(Duration(days: i)),
          symptoms: {
            Symptom.mood,
            Symptom.bloating,
            if (i <= 2) Symptom.fatigue,
            if (i == 1) Symptom.cravings,
          },
          pain: 1 + i,
        );
      }
    }

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
    _clearAll();
    if (content.trim().isEmpty) return;
    final data = jsonDecode(content) as Map<String, dynamic>;
    for (final r in (data['readings'] as List? ?? const [])) {
      _readings.add(TemperatureReading.fromJson(r as Map<String, dynamic>));
    }
    for (final p in (data['periods'] as List? ?? const [])) {
      _periods.add(PeriodEvent.fromJson(p as Map<String, dynamic>));
    }
    for (final l in (data['dailyLogs'] as List? ?? const [])) {
      _logs.add(DailyLog.fromJson(l as Map<String, dynamic>));
    }
    for (final f in (data['remedyFeedback'] as List? ?? const [])) {
      final fb = RemedyFeedback.fromJson(f as Map<String, dynamic>);
      _feedback[fb.id] = fb;
    }
    for (final s in (data['shopping'] as List? ?? const [])) {
      _shopping.add(ShoppingItem.fromJson(s as Map<String, dynamic>));
    }
    final profileJson = data['profile'];
    if (profileJson is Map<String, dynamic>) {
      _profile = HealthProfile.fromJson(profileJson);
    }
  }

  /// Reset all in-memory state to empty (used on load / first run).
  void _clearAll() {
    _readings.clear();
    _periods.clear();
    _logs.clear();
    _feedback.clear();
    _shopping.clear();
    _profile = HealthProfile();
  }

  String _encode() => jsonEncode({
        'version': 3,
        'readings': _readings.map((r) => r.toJson()).toList(),
        'periods': _periods.map((p) => p.toJson()).toList(),
        'dailyLogs': _logs.map((l) => l.toJson()).toList(),
        'remedyFeedback': _feedback.values.map((f) => f.toJson()).toList(),
        'shopping': _shopping.map((s) => s.toJson()).toList(),
        'profile': _profile.toJson(),
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
