/// LillithApp - evidence-based, personalised symptom relief.
///
/// For each symptom the user picks (recent symptoms are offered first), this
/// screen shows the curated, *sourced* remedies from [symptomAdvice], ranked so
/// that whatever the user has told us **helped them** rises to the top and
/// whatever **did not help** sinks to an optional footnote. That is the app
/// learning from the user's own choices over time.
///
/// Each remedy can be marked helpful / not helpful, and — where it involves
/// something to buy — added to the Pod-saved shopping list, found nearby, or
/// searched for online. Every symptom also carries a clear "when to see a
/// professional" note.

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/constants/symptom_advice.dart';
import 'package:lillith_app/models/daily_log.dart';
import 'package:lillith_app/models/remedy_feedback.dart';
import 'package:lillith_app/models/shopping_list.dart';
import 'package:lillith_app/services/health_repository.dart';
import 'package:lillith_app/utils/links.dart';

class Relief extends StatefulWidget {
  const Relief({super.key});

  @override
  State<Relief> createState() => _ReliefState();
}

class _ReliefState extends State<Relief> {
  final _repo = HealthRepository.instance;
  Symptom? _selected;

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  /// Symptoms the user logged in roughly the last two weeks, most recent first.
  List<Symptom> get _recentSymptoms {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final seen = <Symptom>{};
    for (final log in _repo.dailyLogs) {
      if (log.date.isBefore(cutoff)) continue;
      seen.addAll(log.symptoms);
    }
    return seen.toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        final recent = _recentSymptoms;
        final selected =
            _selected ?? (recent.isNotEmpty ? recent.first : Symptom.cramps);
        final advice = symptomAdvice[selected.key];

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text('Relief', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Gentle, science-backed ideas for how you feel — and we remember '
              'what works for you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (recent.isNotEmpty) ...[
              Text(
                'Recently logged',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in Symptom.values)
                  ChoiceChip(
                    avatar: Icon(s.icon, size: 18),
                    label: Text(s.label),
                    selected: selected == s,
                    onSelected: (_) => setState(() => _selected = s),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (advice != null) ...[
              _SeeDoctorCard(text: advice.seeDoctorIf),
              const SizedBox(height: 16),
              ..._rankedRemedies(advice).map(
                (r) => _RemedyCard(
                  symptomKey: advice.key,
                  remedy: r,
                  rating: _repo.ratingFor(advice.key, r.title),
                  onRate: (rating) =>
                      _repo.rateRemedy(advice.key, r.title, rating),
                  onAddToList: r.shopItem == null
                      ? null
                      : () => _addToList(r.shopItem!, advice.displayName),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _ProfessionalHelpCard(),
          ],
        );
      },
    );
  }

  /// Remedies ordered by the user's own verdict (helped first, then untried,
  /// then didn't-help), preserving the curated order within each group.
  List<Remedy> _rankedRemedies(SymptomAdvice advice) {
    final list = [...advice.remedies];
    list.sort((a, b) {
      final ra = _repo.ratingFor(advice.key, a.title).rank;
      final rb = _repo.ratingFor(advice.key, b.title).rank;
      return rb.compareTo(ra);
    });
    return list;
  }

  Future<void> _addToList(String item, String symptomName) async {
    await _repo.addShoppingItem(
      ShoppingItem(name: item, note: 'For $symptomName', symptomKey: null),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Added "$item" to your list.')));
  }
}

class _SeeDoctorCard extends StatelessWidget {
  const _SeeDoctorCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: scheme.onTertiaryContainer,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When to see a professional',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemedyCard extends StatelessWidget {
  const _RemedyCard({
    required this.symptomKey,
    required this.remedy,
    required this.rating,
    required this.onRate,
    required this.onAddToList,
  });

  final String symptomKey;
  final Remedy remedy;
  final RemedyRating rating;
  final ValueChanged<RemedyRating> onRate;
  final VoidCallback? onAddToList;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final helped = rating == RemedyRating.helped;
    return Card(
      color: helped ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (helped)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.star_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ),
                Expanded(
                  child: Text(
                    remedy.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _TierBadge(tier: remedy.tier),
              ],
            ),
            if (rating == RemedyRating.didNotHelp)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'You marked this as not for you — kept here just '
                  'in case.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.outline,
                      ),
                ),
              ),
            const SizedBox(height: 10),
            Text(remedy.howTo, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              remedy.whyItHelps,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 12),
            // Sources.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in remedy.sources)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(s.name),
                    onPressed: () => openUrl(s.url),
                  ),
              ],
            ),
            const Divider(height: 24),
            // Learning feedback + shopping actions.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onRate(
                    helped ? RemedyRating.untried : RemedyRating.helped,
                  ),
                  icon: Icon(
                    helped
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                  ),
                  label: Text(helped ? 'Helped me' : 'This helped'),
                ),
                TextButton.icon(
                  onPressed: () => onRate(
                    rating == RemedyRating.didNotHelp
                        ? RemedyRating.untried
                        : RemedyRating.didNotHelp,
                  ),
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 18),
                  label: const Text("Didn't help"),
                ),
                if (onAddToList != null) ...[
                  OutlinedButton.icon(
                    onPressed: onAddToList,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    label: const Text('Add to list'),
                  ),
                  TextButton.icon(
                    onPressed: () => openMapsNearMe(remedy.shopItem!),
                    icon: const Icon(Icons.place_rounded, size: 18),
                    label: const Text('Find nearby'),
                  ),
                  TextButton.icon(
                    onPressed: () => openRetailerSearch(remedy.shopItem!),
                    icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                    label: const Text('Buy online'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});
  final EvidenceTier tier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, IconData icon) = switch (tier) {
      EvidenceTier.clinical => (
          scheme.secondaryContainer,
          Icons.verified_rounded
        ),
      EvidenceTier.community => (
          scheme.tertiaryContainer,
          Icons.groups_rounded
        ),
      EvidenceTier.both => (
          scheme.primaryContainer,
          Icons.workspace_premium_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13),
          const SizedBox(width: 4),
          Text(tier.label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _ProfessionalHelpCard extends StatelessWidget {
  const _ProfessionalHelpCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'A gentle reminder',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These ideas are for everyday comfort, not a diagnosis. If pain '
              'is severe, keeps getting worse, stops you living your life, or '
              'something just feels wrong, please talk to a doctor, nurse or '
              'pharmacist — you deserve real support, and asking is always '
              'okay.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
