/// LillithApp - a recorded period start.
///
/// The user logs the day their period began. The history of these start dates
/// drives cycle-length statistics and, together with the skin-temperature
/// series, the next-period prediction.

library;

/// The first day of a menstrual period, as logged by the user.

class PeriodEvent {
  PeriodEvent({required DateTime startDate})
      : startDate = DateTime(startDate.year, startDate.month, startDate.day);

  /// The day the period started. Normalised to midnight (date-only).

  final DateTime startDate;

  Map<String, dynamic> toJson() => {
        'startDate': startDate.toIso8601String(),
      };

  factory PeriodEvent.fromJson(Map<String, dynamic> json) =>
      PeriodEvent(startDate: DateTime.parse(json['startDate'] as String));
}
