/// LillithApp - a day's interactive flow + symptom log.
///
/// Alongside the temperature series and period-start anchors, the user can
/// record, for any calendar day, how heavy their flow was and which symptoms
/// they felt. That richer daily picture drives the flow visualisation and the
/// personalised relief suggestions.
///
/// Like the other models, a [DailyLog] is keyed on the date alone (normalised
/// to midnight) so a day has at most one log.

library;

import 'package:flutter/material.dart';

/// How heavy the menstrual flow was on a given day.
///
/// Ordered from [none] (no bleeding) through to [heavy]; the numeric [level]
/// gives the flow chart a value to plot and lets the UI render an escalating
/// number of drop icons.

enum FlowIntensity {
  none,
  spotting,
  light,
  medium,
  heavy;

  /// Human-friendly label for display in the UI.

  String get label => switch (this) {
        FlowIntensity.none => 'None',
        FlowIntensity.spotting => 'Spotting',
        FlowIntensity.light => 'Light',
        FlowIntensity.medium => 'Medium',
        FlowIntensity.heavy => 'Heavy',
      };

  /// A 0–4 magnitude used by the flow chart and for the drop-count in the UI.

  int get level => index;

  /// Whether this represents any bleeding at all (spotting and above).

  bool get isBleeding => this != FlowIntensity.none;

  /// Parse a stored name back into a value, defaulting to [none] for unknown or
  /// missing values so old/foreign data still loads.

  static FlowIntensity fromName(String? name) => FlowIntensity.values
      .firstWhere((f) => f.name == name, orElse: () => FlowIntensity.none);
}

/// A symptom the user can tag on a day.
///
/// Each value carries a friendly [label] and a soft, rounded [icon]. The [key]
/// matches the keys used by the relief-suggestion content so a logged symptom
/// can look up the advice compiled for it.

enum Symptom {
  cramps('Cramps', Icons.spa_rounded),
  bloating('Bloating', Icons.bubble_chart_rounded),
  fatigue('Fatigue', Icons.bedtime_rounded),
  mood('Mood swings', Icons.sentiment_dissatisfied_rounded),
  headache('Headache', Icons.psychology_alt_rounded),
  backPain('Back pain', Icons.airline_seat_recline_normal_rounded),
  breastTenderness('Breast tenderness', Icons.favorite_rounded),
  nausea('Nausea', Icons.sick_rounded),
  insomnia('Insomnia', Icons.nights_stay_rounded),
  cravings('Cravings', Icons.cookie_rounded);

  const Symptom(this.label, this.icon);

  /// Human-friendly label for display in the UI.

  final String label;

  /// A soft, rounded icon representing the symptom.

  final IconData icon;

  /// Stable storage/lookup key (the enum name).

  String get key => name;

  /// Parse a stored name back into a value, or null if it is unknown so
  /// removed/foreign symptoms are silently dropped rather than crashing a load.

  static Symptom? fromName(String? name) {
    for (final s in Symptom.values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// One day's flow intensity and set of symptoms.

class DailyLog {
  DailyLog({
    required DateTime date,
    this.flow = FlowIntensity.none,
    Set<Symptom> symptoms = const {},
    int? painLevel,
  })  : date = DateTime(date.year, date.month, date.day),
        symptoms = Set.unmodifiable(symptoms),
        // Clamp to the 0–10 clinical pain scale; null means "not rated".
        painLevel = painLevel?.clamp(0, 10).toInt();

  /// The day this log applies to. Normalised to midnight (date-only).

  final DateTime date;

  /// How heavy the flow was on this day.

  final FlowIntensity flow;

  /// The symptoms the user tagged on this day.

  final Set<Symptom> symptoms;

  /// Pain rated on the 0–10 scale used in emergency departments (0 = no pain,
  /// 10 = worst imaginable). Null when the user has not rated pain that day.

  final int? painLevel;

  /// Whether this log carries no information worth persisting — used by the
  /// repository to prune empty days.

  bool get isEmpty =>
      flow == FlowIntensity.none && symptoms.isEmpty && painLevel == null;

  /// A copy with selected fields replaced. Pass [clearPain] to unset the pain
  /// rating (since a null [painLevel] argument means "leave unchanged").

  DailyLog copyWith({
    FlowIntensity? flow,
    Set<Symptom>? symptoms,
    int? painLevel,
    bool clearPain = false,
  }) =>
      DailyLog(
        date: date,
        flow: flow ?? this.flow,
        symptoms: symptoms ?? this.symptoms,
        painLevel: clearPain ? null : (painLevel ?? this.painLevel),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'flow': flow.name,
        'symptoms': symptoms.map((s) => s.name).toList(),
        if (painLevel != null) 'painLevel': painLevel,
      };

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        date: DateTime.parse(json['date'] as String),
        flow: FlowIntensity.fromName(json['flow'] as String?),
        symptoms: {
          for (final s in (json['symptoms'] as List? ?? const []))
            if (Symptom.fromName(s as String?) case final symptom?) symptom,
        },
        painLevel: (json['painLevel'] as num?)?.toInt(),
      );
}
