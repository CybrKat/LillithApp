/// LillithApp - the user's reproductive-health profile.
///
/// Cycles don't happen in a vacuum: conditions like endometriosis or PCOS and
/// fertility treatments such as IVF meaningfully change what's "normal" for a
/// person and which relief suggestions are appropriate. The user can record
/// these here so the app can tailor its notes (and remind them when something
/// warrants professional advice). Stored encrypted on the POD like all other
/// health data.

library;

/// A diagnosed condition that affects the menstrual cycle.

enum ReproductiveCondition {
  endometriosis('Endometriosis'),
  pcos('PCOS'),
  dysmenorrhea('Dysmenorrhea (painful periods)'),
  adenomyosis('Adenomyosis'),
  fibroids('Uterine fibroids'),
  pmdd('PMDD'),
  ovarianCysts('Ovarian cysts'),
  thyroidDisorder('Thyroid disorder'),
  perimenopause('Perimenopause');

  const ReproductiveCondition(this.label);

  /// Human-friendly label for display in the UI.

  final String label;

  static ReproductiveCondition? fromName(String? name) {
    for (final c in ReproductiveCondition.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// A fertility treatment or goal the user is currently engaged with.

enum FertilityTreatment {
  tryingToConceive('Trying to conceive'),
  ivf('IVF'),
  iui('IUI'),
  ovulationInduction('Ovulation induction'),
  hormoneTherapy('Hormone therapy'),
  eggFreezing('Egg freezing'),
  contraceptive('Hormonal contraceptive');

  const FertilityTreatment(this.label);

  /// Human-friendly label for display in the UI.

  final String label;

  static FertilityTreatment? fromName(String? name) {
    for (final t in FertilityTreatment.values) {
      if (t.name == name) return t;
    }
    return null;
  }
}

/// The user's reproductive-health profile: conditions, fertility context and
/// any free-text notes they want to keep alongside their cycle data.

class HealthProfile {
  HealthProfile({
    Set<ReproductiveCondition> conditions = const {},
    Set<FertilityTreatment> treatments = const {},
    this.notes = '',
  })  : conditions = Set.unmodifiable(conditions),
        treatments = Set.unmodifiable(treatments);

  final Set<ReproductiveCondition> conditions;
  final Set<FertilityTreatment> treatments;
  final String notes;

  /// Whether the profile holds nothing worth persisting.

  bool get isEmpty =>
      conditions.isEmpty && treatments.isEmpty && notes.trim().isEmpty;

  HealthProfile copyWith({
    Set<ReproductiveCondition>? conditions,
    Set<FertilityTreatment>? treatments,
    String? notes,
  }) =>
      HealthProfile(
        conditions: conditions ?? this.conditions,
        treatments: treatments ?? this.treatments,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'conditions': conditions.map((c) => c.name).toList(),
        'treatments': treatments.map((t) => t.name).toList(),
        'notes': notes,
      };

  factory HealthProfile.fromJson(Map<String, dynamic> json) => HealthProfile(
        conditions: {
          for (final c in (json['conditions'] as List? ?? const []))
            if (ReproductiveCondition.fromName(c as String?) case final v?) v,
        },
        treatments: {
          for (final t in (json['treatments'] as List? ?? const []))
            if (FertilityTreatment.fromName(t as String?) case final v?) v,
        },
        notes: json['notes'] as String? ?? '',
      );
}
