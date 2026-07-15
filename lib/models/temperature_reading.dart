/// LillithApp - a single skin-temperature reading.
///
/// A reading is the temperature recorded for one calendar day. Cycle tracking
/// uses the overnight/resting skin temperature reported by a smart ring or
/// watch (or entered by hand), so readings are stored at day granularity: at
/// most one reading per date, keyed on the date alone.

library;

/// Where a [TemperatureReading] came from.
///
/// The [manual] source is used for hand-entered values. The device sources
/// exist so that a future import from a smart ring or watch can tag its data
/// without any change to the storage format.

enum ReadingSource {
  manual,
  ring,
  watch;

  /// Human-friendly label for display in the UI.

  String get label => switch (this) {
        ReadingSource.manual => 'Manual entry',
        ReadingSource.ring => 'Smart ring',
        ReadingSource.watch => 'Smart watch',
      };

  /// Parse a stored source string back into an enum value, defaulting to
  /// [manual] for unknown or missing values so old/foreign data still loads.

  static ReadingSource fromName(String? name) => ReadingSource.values
      .firstWhere((s) => s.name == name, orElse: () => ReadingSource.manual);
}

/// One skin-temperature reading for a single day.

class TemperatureReading {
  TemperatureReading({
    required DateTime date,
    required this.celsius,
    this.source = ReadingSource.manual,
  }) : date = DateTime(date.year, date.month, date.day);

  /// The day the reading applies to. Always normalised to midnight (date-only)
  /// so a day has at most one reading regardless of the time it was entered.

  final DateTime date;

  /// The skin temperature in degrees Celsius.

  final double celsius;

  /// Where the reading came from (hand-entered or imported from a device).

  final ReadingSource source;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'celsius': celsius,
        'source': source.name,
      };

  factory TemperatureReading.fromJson(Map<String, dynamic> json) =>
      TemperatureReading(
        date: DateTime.parse(json['date'] as String),
        celsius: (json['celsius'] as num).toDouble(),
        source: ReadingSource.fromName(json['source'] as String?),
      );
}
