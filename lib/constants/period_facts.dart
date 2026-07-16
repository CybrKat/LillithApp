/// LillithApp - science-backed period facts and a curated Q&A knowledge base.
///
/// Two things live here, both drawn from verified health authorities:
///
///  * [periodFacts] — short, science-backed facts about the menstrual cycle.
///    The dashboard opens with a "Today's health fact" drawn from this list,
///    rotating so it feels fresh each day.
///
///  * [knowledgeBase] — a small set of question/answer entries the "Ask a
///    question" screen searches. It is deliberately an *offline, curated*
///    knowledge base (no external AI, nothing leaves the device) so answers
///    stay private and grounded in cited sources.
///
/// This is general educational information, not medical advice.

library;

import 'package:lillith_app/constants/symptom_advice.dart' show Source;

/// One science-backed fact about periods, with its source.

class PeriodFact {
  const PeriodFact(this.text, this.source);
  final String text;
  final Source source;
}

/// One curated question/answer entry for the Ask screen.

class KnowledgeEntry {
  const KnowledgeEntry({
    required this.question,
    required this.answer,
    required this.keywords,
    required this.sources,
  });

  final String question;
  final String answer;

  /// Lower-case terms used to match a user's typed question.

  final List<String> keywords;
  final List<Source> sources;

  /// A relevance score for [query]: counts keyword and question-word hits.

  int scoreFor(String query) {
    final q = query.toLowerCase();
    if (q.trim().isEmpty) return 0;
    var score = 0;
    for (final k in keywords) {
      if (q.contains(k)) score += 2;
    }
    for (final word in q.split(RegExp(r'[^a-z0-9]+'))) {
      if (word.length < 3) continue;
      if (question.toLowerCase().contains(word)) score += 1;
      if (answer.toLowerCase().contains(word)) score += 1;
    }
    return score;
  }
}

/// Science-backed facts shown as "Today's health fact".

const List<PeriodFact> periodFacts = [
  PeriodFact(
    'A menstrual cycle is counted from the first day of one period to the '
    'first day of the next. Anywhere from 21 to 35 days is considered '
    'normal for adults — there is no single "right" length.',
    Source(
      'Office on Women\'s Health',
      'https://www.womenshealth.gov/menstrual-cycle/your-menstrual-cycle',
    ),
  ),
  PeriodFact(
    'Ovulation usually happens about 12–14 days before your next period '
    'starts — not necessarily on "day 14", since that depends on your '
    'own cycle length.',
    Source(
      'NHS',
      'https://www.nhs.uk/conditions/periods/fertility-in-the-menstrual-cycle/',
    ),
  ),
  PeriodFact(
    'Your basal body temperature rises slightly (about 0.3°C) after '
    'ovulation and stays up until your period — the biphasic shift '
    'LillithApp looks for.',
    Source(
      'NIH / NCBI',
      'https://www.ncbi.nlm.nih.gov/books/NBK279054/',
    ),
  ),
  PeriodFact(
    'The average amount of blood lost in a period is only about 30–70 ml '
    '(a few tablespoons) across the whole period, despite how it can feel.',
    Source(
      'NHS',
      'https://www.nhs.uk/conditions/heavy-periods/',
    ),
  ),
  PeriodFact(
    'Period blood is not "dirty" — it is a mix of blood and tissue from the '
    'uterine lining (the endometrium) that builds up each cycle.',
    Source(
      'Cleveland Clinic',
      'https://my.clevelandclinic.org/health/articles/10132-menstrual-cycle',
    ),
  ),
  PeriodFact(
    'Mild cramps happen because the uterus contracts, squeezing its blood '
    'vessels and briefly cutting its oxygen supply, which releases '
    'pain-triggering chemicals called prostaglandins.',
    Source(
      'NHS',
      'https://www.nhs.uk/symptoms/period-pain/',
    ),
  ),
  PeriodFact(
    'It is normal for cycle length to vary a little month to month. Tracking '
    'several cycles gives a far better prediction than any single one.',
    Source(
      'ACOG',
      'https://www.acog.org/womens-health/faqs/the-menstrual-cycle',
    ),
  ),
  PeriodFact(
    'PMS symptoms are extremely common, affecting most people who menstruate '
    'at some point. Severe, life-disrupting symptoms can be PMDD, which '
    'has specific treatments.',
    Source(
      'Office on Women\'s Health',
      'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
    ),
  ),
  PeriodFact(
    'Exercise had the largest pain-reducing effect of any self-care measure '
    'in reviews of period pain — even gentle movement helps.',
    Source(
      'NCBI/PMC systematic review',
      'https://pmc.ncbi.nlm.nih.gov/articles/PMC6337810/',
    ),
  ),
  PeriodFact(
    'The first period (menarche) usually arrives between ages 10 and 15, and '
    'cycles can stay irregular for the first couple of years while the '
    'body settles into a rhythm.',
    Source(
      'ACOG',
      'https://www.acog.org/womens-health/faqs/your-first-period',
    ),
  ),
  PeriodFact(
    'Iron can be lost through menstrual blood, so people with heavy periods '
    'are more prone to iron deficiency — a common, treatable cause of '
    'period-related tiredness.',
    Source(
      'NCBI/PMC randomised trial',
      'https://pmc.ncbi.nlm.nih.gov/articles/PMC3414597/',
    ),
  ),
  PeriodFact(
    'Heat applied to the lower abdomen has been found to relieve period pain '
    'about as effectively as over-the-counter painkillers.',
    Source(
      'Cleveland Clinic',
      'https://health.clevelandclinic.org/how-to-stop-period-cramps',
    ),
  ),
  PeriodFact(
    'Periods stopping (amenorrhoea), becoming very irregular, or unusually '
    'heavy can be a signal worth checking with a doctor — your cycle is a '
    'useful vital sign.',
    Source(
      'ACOG',
      'https://www.acog.org/womens-health/faqs/the-menstrual-cycle',
    ),
  ),
  PeriodFact(
    'You can still get pregnant during your period, because sperm can survive '
    'for several days and ovulation timing varies — periods are not a '
    'reliable form of contraception.',
    Source(
      'NHS',
      'https://www.nhs.uk/conditions/contraception/when-periods-after-stopping-pill/',
    ),
  ),
];

/// The curated Q&A knowledge base for the Ask screen.

const List<KnowledgeEntry> knowledgeBase = [
  KnowledgeEntry(
    question: 'How long should my cycle be?',
    answer:
        'A cycle is counted from the first day of one period to the first day '
        'of the next. For adults, 21 to 35 days is considered normal, and it '
        'is normal for it to vary a little each month. Tracking several cycles '
        'gives the most reliable picture.',
    keywords: ['cycle length', 'how long', 'normal cycle', 'days', '28'],
    sources: [
      Source(
        'Office on Women\'s Health',
        'https://www.womenshealth.gov/menstrual-cycle/your-menstrual-cycle',
      ),
    ],
  ),
  KnowledgeEntry(
    question: 'When do I ovulate?',
    answer:
        'Ovulation typically happens about 12–14 days before your next period '
        'begins. If your cycles are shorter or longer than 28 days, that means '
        'ovulation is earlier or later than "day 14". A rise in basal body '
        'temperature is one sign it has happened.',
    keywords: ['ovulate', 'ovulation', 'fertile', 'fertility', 'conceive'],
    sources: [
      Source(
        'NHS',
        'https://www.nhs.uk/conditions/periods/fertility-in-the-menstrual-cycle/',
      ),
    ],
  ),
  KnowledgeEntry(
    question: 'Why do I get period cramps?',
    answer:
        'Cramps happen because the uterus contracts to shed its lining. These '
        'contractions briefly squeeze the blood vessels in the uterus wall, '
        'releasing prostaglandins that cause pain. Heat, gentle exercise and '
        'anti-inflammatory painkillers are the best-supported ways to ease '
        'them.',
    keywords: ['cramp', 'cramps', 'pain', 'hurt', 'prostaglandin', 'ache'],
    sources: [
      Source('NHS', 'https://www.nhs.uk/symptoms/period-pain/'),
    ],
  ),
  KnowledgeEntry(
    question: 'How much bleeding is normal?',
    answer:
        'Most people lose only about 30–70 ml of blood over an entire period. '
        'Soaking through a pad or tampon every hour or two, passing large '
        'clots, or bleeding longer than 7 days can indicate heavy periods '
        'worth discussing with a doctor.',
    keywords: ['heavy', 'bleeding', 'blood', 'clots', 'flow', 'how much'],
    sources: [
      Source('NHS', 'https://www.nhs.uk/conditions/heavy-periods/'),
    ],
  ),
  KnowledgeEntry(
    question: 'Is it normal for my period to be irregular?',
    answer:
        'Some variation is normal, and cycles are often irregular in the first '
        'couple of years after periods begin and again approaching menopause. '
        'Persistent irregularity, very long gaps, or periods that stop can be '
        'linked to conditions like PCOS or thyroid problems and are worth a '
        'check-up.',
    keywords: [
      'irregular',
      'late',
      'missed',
      'skipped',
      'pcos',
      'unpredictable',
    ],
    sources: [
      Source(
        'ACOG',
        'https://www.acog.org/womens-health/faqs/the-menstrual-cycle',
      ),
    ],
  ),
  KnowledgeEntry(
    question: 'What is PMS and when should I worry?',
    answer:
        'PMS (premenstrual syndrome) is the cluster of physical and emotional '
        'symptoms — mood changes, bloating, tenderness, fatigue — in the days '
        'before your period. It is very common. When symptoms are severe '
        'enough to disrupt your life, it may be PMDD, which has specific '
        'treatments; speak to a GP.',
    keywords: [
      'pms',
      'pmdd',
      'mood',
      'irritable',
      'emotional',
      'before period',
    ],
    sources: [
      Source(
        'Office on Women\'s Health',
        'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
      ),
    ],
  ),
  KnowledgeEntry(
    question: 'Can I get pregnant on my period?',
    answer:
        'Yes, it is possible. Sperm can survive for several days, and because '
        'ovulation timing varies, having sex during your period can still lead '
        'to pregnancy. Periods are not a reliable form of contraception.',
    keywords: ['pregnant', 'pregnancy', 'contraception', 'sex', 'protection'],
    sources: [
      Source(
        'NHS',
        'https://www.nhs.uk/conditions/contraception/when-periods-after-stopping-pill/',
      ),
    ],
  ),
  KnowledgeEntry(
    question: 'Does tracking temperature really predict my period?',
    answer: 'Your basal body temperature rises slightly (around 0.3°C) after '
        'ovulation and stays elevated until your period. Spotting that shift, '
        'combined with your logged cycle history, lets LillithApp estimate '
        'when your next period is likely to start. It is an estimate, not a '
        'guarantee, and not a contraceptive method.',
    keywords: ['temperature', 'bbt', 'predict', 'prediction', 'basal', 'shift'],
    sources: [
      Source('NIH / NCBI', 'https://www.ncbi.nlm.nih.gov/books/NBK279054/'),
    ],
  ),
];
