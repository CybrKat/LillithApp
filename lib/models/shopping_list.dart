/// LillithApp - the user's relief shopping list.
///
/// When a remedy needs something to buy (a heat pack, magnesium, ginger tea),
/// the user can add that item here. The list is persisted on the POD so it is
/// available across devices, and each item can be checked off once bought.

library;

/// One item the user wants to buy to help with their symptoms.

class ShoppingItem {
  ShoppingItem({
    required this.name,
    this.note,
    this.symptomKey,
    this.bought = false,
  });

  /// The thing to buy, e.g. "Heat pack". Also acts as the item's identity, so
  /// adding the same item twice just updates it rather than duplicating.

  final String name;

  /// Optional context, e.g. which remedy suggested it.

  final String? note;

  /// The [Symptom.key] this item was added for, if any.

  final String? symptomKey;

  /// Whether the user has already bought it.

  final bool bought;

  ShoppingItem copyWith({bool? bought}) => ShoppingItem(
        name: name,
        note: note,
        symptomKey: symptomKey,
        bought: bought ?? this.bought,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (note != null) 'note': note,
        if (symptomKey != null) 'symptom': symptomKey,
        'bought': bought,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        name: json['name'] as String,
        note: json['note'] as String?,
        symptomKey: json['symptom'] as String?,
        bought: json['bought'] as bool? ?? false,
      );
}
