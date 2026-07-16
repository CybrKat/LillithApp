/// LillithApp - learn about periods and ask gentle questions.
///
/// Two things here, both grounded in cited health authorities:
///  * a rotating, science-backed "Did you know?" fact library;
///  * an "Ask me anything" box that searches a curated, offline [knowledgeBase]
///    (nothing leaves the device) and answers in the warm, unhurried voice of a
///    kind counsellor rather than a blunt search engine.
///
/// The tone is deliberate: curious, reassuring and never judgemental, because
/// for many people these are questions they have never felt safe to ask.

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/constants/period_facts.dart';
import 'package:lillith_app/constants/symptom_advice.dart' show Source;
import 'package:lillith_app/utils/links.dart';

class Learn extends StatefulWidget {
  const Learn({super.key});

  @override
  State<Learn> createState() => _LearnState();
}

class _LearnState extends State<Learn> {
  final _controller = TextEditingController();
  KnowledgeEntry? _answer;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ask() {
    final query = _controller.text.trim();
    KnowledgeEntry? best;
    var bestScore = 0;
    for (final entry in knowledgeBase) {
      final score = entry.scoreFor(query);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }
    setState(() {
      _searched = true;
      _answer = bestScore > 0 ? best : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('Learn', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'A kind, curious place to understand your body. Every answer comes '
          'from trusted health sources.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _AskCard(
          controller: _controller,
          onAsk: _ask,
        ),
        if (_searched) ...[
          const SizedBox(height: 16),
          if (_answer != null)
            _AnswerCard(entry: _answer!)
          else
            const _NoAnswerCard(),
        ],
        const SizedBox(height: 28),
        Text('Did you know?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Little truths about your cycle, each from a verified source.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final fact in periodFacts) _FactCard(fact: fact),
      ],
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({required this.controller, required this.onAsk});

  final TextEditingController controller;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.forum_rounded, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Text(
                  'Ask me anything',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'There are no silly questions here. Ask in your own words — like '
              '"why do I get cramps?" or "how long should my cycle be?"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onAsk(),
              decoration: InputDecoration(
                hintText: 'Type your question…',
                fillColor: scheme.surface,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: onAsk,
                  tooltip: 'Ask',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.entry});
  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.question,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Thanks for asking — that is a really good question. 💜',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in entry.sources)
                  ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(s.name),
                    onPressed: () => openUrl(s.url),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAnswerCard extends StatelessWidget {
  const _NoAnswerCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'I don\'t have that one yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "I couldn't find a good match for that in my little library — and "
              "that's on me, not you. Try asking in a different way, or take a "
              'look at the facts below. For anything worrying or personal, a '
              'doctor, nurse or pharmacist is always a safe person to ask.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});
  final PeriodFact fact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    fact.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(fact.source.name),
                onPressed: () => openUrl(fact.source.url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the fact to show as "Today's health fact", rotating by day so it is
/// stable within a day but fresh across days. Shared with the dashboard.
PeriodFact factOfTheDay([DateTime? now]) {
  final d = now ?? DateTime.now();
  final dayOfYear = d.difference(DateTime(d.year)).inDays; // 0-based day index
  return periodFacts[dayOfYear % periodFacts.length];
}

/// Exposed so other files (e.g. the dashboard) can reuse [Source] links.
typedef LearnSource = Source;
