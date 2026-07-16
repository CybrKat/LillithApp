/// LillithApp - the user's personal verdict on a relief suggestion.
///
/// The relief screen shows evidence-based remedies for each symptom, but what
/// actually helps is personal. Every time the user marks a remedy as having
/// helped (or not), we remember it here so future suggestions lead with what
/// has worked for *them* — e.g. floating "heat pack" to the top and demoting
/// "pain relief" to an optional extra once they've told us heat works better.
///
/// Feedback is keyed on the pair (symptom key, remedy title) so it survives
/// re-ordering of the underlying content.

library;

/// The user's verdict on trying a remedy.

enum RemedyRating {
  /// Not yet tried / no opinion recorded. Never persisted — it is the absence
  /// of a stored verdict.
  untried,

  /// The user found this remedy helpful. Ranked to the top of its symptom.
  helped,

  /// The user tried it and it did little. Kept but demoted to "optional".
  didNotHelp;

  /// A weight used to sort remedies: helped first, untried next, unhelpful
  /// last. Higher sorts earlier.

  int get rank => switch (this) {
        RemedyRating.helped => 2,
        RemedyRating.untried => 1,
        RemedyRating.didNotHelp => 0,
      };

  /// Parse a stored name back into a value, defaulting to [untried].

  static RemedyRating fromName(String? name) => RemedyRating.values
      .firstWhere((r) => r.name == name, orElse: () => RemedyRating.untried);
}

/// One recorded verdict on a specific remedy for a specific symptom.

class RemedyFeedback {
  RemedyFeedback({
    required this.symptomKey,
    required this.remedyTitle,
    required this.rating,
  });

  /// The [Symptom.key] the remedy belongs to.

  final String symptomKey;

  /// The remedy's title (its stable identifier within a symptom).

  final String remedyTitle;

  /// The user's verdict.

  final RemedyRating rating;

  /// Composite key uniquely identifying the remedy this feedback is about.

  String get id => '$symptomKey::$remedyTitle';

  static String idFor(String symptomKey, String remedyTitle) =>
      '$symptomKey::$remedyTitle';

  Map<String, dynamic> toJson() => {
        'symptom': symptomKey,
        'remedy': remedyTitle,
        'rating': rating.name,
      };

  factory RemedyFeedback.fromJson(Map<String, dynamic> json) => RemedyFeedback(
        symptomKey: json['symptom'] as String,
        remedyTitle: json['remedy'] as String,
        rating: RemedyRating.fromName(json['rating'] as String?),
      );
}
