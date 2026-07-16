/// LillithApp - evidence-based relief suggestions for period symptoms.
///
/// This is the app's curated, *sourced* knowledge base of self-care measures
/// for common menstrual symptoms. Every remedy is either recommended by a
/// verified health authority (NHS, Cleveland Clinic, Mayo Clinic, the US Office
/// on Women's Health, NIH/NCBI, the Sleep Foundation, the American Migraine
/// Foundation) or is widely reported as genuinely helpful by real people —
/// never a product or brand pitch. Each carries its [EvidenceTier] and links to
/// the original sources so the user can read further and judge for themselves.
///
/// The relief screen ranks these per symptom, learning from the user's own
/// [RemedyRating] feedback so what has worked for *them* rises to the top. Where
/// a remedy needs something to buy, [Remedy.shopItem] names it so it can be
/// added to the shopping list.
///
/// IMPORTANT: this is general wellness information, not medical advice. Each
/// symptom also carries a [SymptomAdvice.seeDoctorIf] red-flag note pointing to
/// when professional advice should be sought.

library;

/// How well-supported a remedy is.

enum EvidenceTier {
  /// Backed by health authorities / clinical evidence.
  clinical,

  /// Commonly reported as helpful by people in forums and patient communities.
  community,

  /// Both: authority-recommended *and* widely reported to help.
  both;

  /// Short badge label for the UI.

  String get label => switch (this) {
        EvidenceTier.clinical => 'Clinically backed',
        EvidenceTier.community => 'Community favourite',
        EvidenceTier.both => 'Backed + loved',
      };
}

/// A citation for a remedy: a readable [name] and a resolving [url].

class Source {
  const Source(this.name, this.url);
  final String name;
  final String url;
}

/// A single self-care suggestion for a symptom.

class Remedy {
  const Remedy({
    required this.title,
    required this.howTo,
    required this.whyItHelps,
    required this.tier,
    required this.sources,
    this.shopItem,
  });

  /// Short name, e.g. "Heat therapy". Also the stable identifier used to key
  /// the user's [RemedyRating] feedback.

  final String title;

  /// Concrete instructions on how to actually do it.

  final String howTo;

  /// Brief mechanism / why people find it helps.

  final String whyItHelps;

  /// How well-supported the remedy is.

  final EvidenceTier tier;

  /// Where the claim comes from.

  final List<Source> sources;

  /// If this remedy involves buying something, the item to add to the shopping
  /// list (null for behavioural remedies like exercise or sleep).

  final String? shopItem;
}

/// The complete relief guidance for one symptom.

class SymptomAdvice {
  const SymptomAdvice({
    required this.key,
    required this.displayName,
    required this.seeDoctorIf,
    required this.remedies,
  });

  /// Matches [Symptom.key] so a logged symptom looks up its advice.

  final String key;
  final String displayName;

  /// When to seek professional medical advice for this symptom.

  final String seeDoctorIf;
  final List<Remedy> remedies;
}

/// The curated advice, keyed by symptom key (see [Symptom]).

const Map<String, SymptomAdvice> symptomAdvice = {
  'cramps': SymptomAdvice(
    key: 'cramps',
    displayName: 'Cramps',
    seeDoctorIf:
        'See a doctor if cramps are severe or worse than usual and painkillers '
        "don't help, if periods become heavier or irregular, or if you have "
        'pain during sex, pain when peeing or pooing, or bleeding between '
        'periods.',
    remedies: [
      Remedy(
        title: 'Heat therapy',
        howTo:
            'Hold a heat pad or hot water bottle (wrapped in a towel) against '
            'your lower tummy, or take a warm bath or shower.',
        whyItHelps:
            'Heat relaxes the uterine muscles and boosts blood flow, easing '
            'cramping; studies find it works about as well as painkillers.',
        tier: EvidenceTier.both,
        shopItem: 'Heat pad / hot water bottle',
        sources: [
          Source('NHS', 'https://www.nhs.uk/symptoms/period-pain/'),
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/how-to-stop-period-cramps',
          ),
        ],
      ),
      Remedy(
        title: 'Gentle exercise',
        howTo:
            'Try light activity like walking, cycling, swimming or yoga during '
            'your period, even on low-energy days.',
        whyItHelps:
            "Movement releases endorphins, the body's natural painkillers, and "
            'is a first-line non-drug option for period pain.',
        tier: EvidenceTier.clinical,
        sources: [
          Source('NHS', 'https://www.nhs.uk/symptoms/period-pain/'),
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/how-to-stop-period-cramps',
          ),
        ],
      ),
      Remedy(
        title: 'Anti-inflammatory painkillers (NSAIDs)',
        howTo: 'Take over-the-counter ibuprofen at the recommended dose when '
            'cramps start; avoid ibuprofen if you have asthma or stomach, '
            'kidney or heart problems.',
        whyItHelps:
            'NSAIDs block prostaglandins, the chemicals that trigger painful '
            'uterine contractions.',
        tier: EvidenceTier.clinical,
        shopItem: 'Ibuprofen (NSAID)',
        sources: [
          Source('NHS', 'https://www.nhs.uk/symptoms/period-pain/'),
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/how-to-stop-period-cramps',
          ),
        ],
      ),
      Remedy(
        title: 'Stay hydrated',
        howTo:
            'Sip water regularly through the day rather than letting yourself '
            'get thirsty.',
        whyItHelps:
            'Dehydration can make cramps feel worse, so keeping fluids up may '
            'reduce discomfort.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/how-to-stop-period-cramps',
          ),
        ],
      ),
      Remedy(
        title: 'Ginger',
        howTo: 'Take ginger powder (roughly 750–2000 mg daily) or drink ginger '
            'tea during the first 3–4 days of your period.',
        whyItHelps:
            'Trials suggest ginger eases menstrual pain about as well as '
            'NSAIDs, likely by lowering prostaglandins; it is well tolerated.',
        tier: EvidenceTier.both,
        shopItem: 'Ginger tea / ground ginger',
        sources: [
          Source(
            'NCBI/PMC meta-analysis',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC4871956/',
          ),
        ],
      ),
    ],
  ),
  'bloating': SymptomAdvice(
    key: 'bloating',
    displayName: 'Bloating',
    seeDoctorIf:
        'See a doctor if bloating is persistent (lasts more than a week or '
        "doesn't ease after your period), is severe, or comes with a swollen "
        'tummy, fever, vomiting, or unusual bleeding.',
    remedies: [
      Remedy(
        title: 'Cut back on salt',
        howTo:
            'Reduce salty and heavily processed foods, especially in the one '
            'to two weeks before your period.',
        whyItHelps:
            'Salt makes your body hold onto water, so eating less of it '
            'reduces fluid retention and puffiness.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/symptoms/21740-bloated-stomach',
          ),
        ],
      ),
      Remedy(
        title: 'Stay well hydrated',
        howTo:
            'Drink plenty of water through the day instead of fizzy or sugary '
            'drinks.',
        whyItHelps:
            'It sounds counterintuitive, but good hydration supports digestion '
            'and helps your body flush out retained fluid.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/symptoms/21740-bloated-stomach',
          ),
        ],
      ),
      Remedy(
        title: 'Keep moving',
        howTo:
            'Go for a walk or do some gentle activity rather than sitting for '
            'long stretches.',
        whyItHelps:
            'Physical activity keeps your bowels moving and helps clear '
            'trapped gas and fluid that add to bloating.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/symptoms/21740-bloated-stomach',
          ),
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Avoid carbonated and gassy foods',
        howTo: 'Skip fizzy drinks, cut back on gas-producing foods, and eat '
            'slowly while chewing thoroughly.',
        whyItHelps:
            'This reduces swallowed air and intestinal gas that make bloating '
            'feel worse.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/symptoms/21740-bloated-stomach',
          ),
        ],
      ),
      Remedy(
        title: 'Magnesium',
        howTo: 'A daily magnesium supplement may help; check the dose with a '
            'pharmacist or doctor first.',
        whyItHelps:
            'Research links magnesium to reduced premenstrual fluid retention '
            'and fewer PMS symptoms overall.',
        tier: EvidenceTier.both,
        shopItem: 'Magnesium supplement',
        sources: [
          Source(
            'PubMed literature review',
            'https://pubmed.ncbi.nlm.nih.gov/28392498/',
          ),
        ],
      ),
    ],
  ),
  'fatigue': SymptomAdvice(
    key: 'fatigue',
    displayName: 'Fatigue',
    seeDoctorIf:
        "See a doctor if fatigue is severe, doesn't improve with self-care, or "
        'comes with very heavy periods, breathlessness or paleness (possible '
        'iron-deficiency anaemia), or is interfering with your daily life.',
    remedies: [
      Remedy(
        title: 'Boost iron and check your ferritin',
        howTo: 'Eat iron-rich foods like red meat, beans, lentils, spinach and '
            'fortified cereal, and ask your doctor to check your ferritin if '
            'you have heavy periods or ongoing tiredness.',
        whyItHelps:
            'Heavy periods can deplete iron; a randomised trial found iron cut '
            'fatigue in women with low ferritin even when not anaemic.',
        tier: EvidenceTier.clinical,
        shopItem: 'Iron-rich foods / iron supplement',
        sources: [
          Source(
            'NCBI/PMC randomised trial',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC3414597/',
          ),
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/period-fatigue',
          ),
        ],
      ),
      Remedy(
        title: 'Prioritise sleep',
        howTo:
            'Aim for about 8 hours a night, keep a consistent sleep schedule, '
            'and try a slightly cooler bedroom.',
        whyItHelps:
            'Too little sleep worsens PMS symptoms and low mood; consistent '
            'rest helps steady your energy.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/period-fatigue',
          ),
        ],
      ),
      Remedy(
        title: 'Regular aerobic exercise',
        howTo: 'Get regular aerobic activity such as brisk walking through the '
            'month, keeping to lighter movement on tough days.',
        whyItHelps:
            'Exercise is shown to reduce cycle-related fatigue and difficulty '
            'concentrating, partly through endorphin release.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/period-fatigue',
          ),
        ],
      ),
      Remedy(
        title: 'Hydrate and eat balanced meals',
        howTo:
            'Drink water regularly and eat regular, balanced meals; cut back '
            'on caffeine, salt and sugar in the two weeks before your period.',
        whyItHelps:
            'Dehydration and blood-sugar crashes worsen tiredness, so steady '
            'fuel and less caffeine and sugar keep energy more stable.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/period-fatigue',
          ),
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Get enough calcium',
        howTo: 'Include calcium-rich foods such as milk, cheese and yoghurt in '
            'your daily diet.',
        whyItHelps:
            'Studies show calcium can reduce PMS symptoms including fatigue, '
            'cravings and low mood.',
        tier: EvidenceTier.clinical,
        shopItem: 'Calcium-rich foods',
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://www.womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
    ],
  ),
  'mood': SymptomAdvice(
    key: 'mood',
    displayName: 'Mood',
    seeDoctorIf:
        'See a GP if low mood, anxiety or irritability seriously disrupt your '
        "daily life, work or relationships, don't improve with self-help over "
        '2–3 cycles, or you ever have thoughts of harming yourself. This '
        'pattern can be PMDD, which has specific treatments.',
    remedies: [
      Remedy(
        title: 'Regular aerobic exercise',
        howTo:
            'Aim for about 30 minutes of moderate activity like brisk walking, '
            'cycling or swimming on most days, especially in the week or two '
            'before your period.',
        whyItHelps:
            'Boosts endorphins and helps ease low mood, irritability and '
            'fatigue linked to PMS.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'NHS – PMS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Steady, balanced meals',
        howTo: 'Eat smaller meals every 2–3 hours, favour whole grains and '
            'complex carbs, and cut back on sugar, caffeine and salt in the '
            'run-up to your period.',
        whyItHelps:
            'Keeps blood sugar stable and supports serotonin, smoothing out '
            'mood dips and cravings.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'NHS – PMS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
        ],
      ),
      Remedy(
        title: 'Protect your sleep',
        howTo: 'Aim for around 8 hours a night and keep a consistent sleep and '
            'wake schedule.',
        whyItHelps:
            'Poor or irregular sleep worsens irritability and mood swings; '
            'adequate rest helps stabilise them.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'NHS – PMS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
        ],
      ),
      Remedy(
        title: 'Stress-reduction practice',
        howTo:
            'Build in a short daily calming routine such as yoga, meditation, '
            'breathing exercises or journaling, especially premenstrually.',
        whyItHelps:
            'Calms the nervous system and gives coping tools, reducing tension '
            'and emotional reactivity.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'NHS – PMS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Calcium-rich diet',
        howTo: 'Include calcium-rich foods such as yoghurt, milk or fortified '
            'plant milk daily; ask your doctor before adding a supplement.',
        whyItHelps:
            'Adequate calcium is linked to less PMS-related low mood, fatigue '
            'and cravings.',
        tier: EvidenceTier.clinical,
        shopItem: 'Calcium-rich foods',
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
    ],
  ),
  'headache': SymptomAdvice(
    key: 'headache',
    displayName: 'Headache',
    seeDoctorIf:
        "Seek emergency care for a sudden or 'worst-ever' headache, or one "
        'with vision loss, slurred speech, weakness, numbness, confusion, or '
        'following a head injury. See a doctor if migraines are getting more '
        "frequent or severe, or aren't controlled by your usual approach.",
    remedies: [
      Remedy(
        title: 'Rest in a cool, dark room with a cold pack',
        howTo: 'Lie down in a quiet, dark room and place a wrapped ice pack or '
            'cold compress on your forehead or the back of your neck.',
        whyItHelps:
            'Cuts down light and sound stimulation and the cold helps numb '
            'and dull the throbbing pain.',
        tier: EvidenceTier.both,
        shopItem: 'Cold pack',
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/8260-menstrual-migraines-hormone-headaches',
          ),
        ],
      ),
      Remedy(
        title: 'Magnesium mini-prevention',
        howTo: 'Ask your doctor about daily magnesium (Cleveland Clinic notes '
            'around 400 mg magnesium oxide at bedtime), often started around '
            'day 15 of your cycle until your period begins.',
        whyItHelps:
            'Magnesium levels tend to dip before your period; topping it up '
            'may prevent or lessen menstrual migraine.',
        tier: EvidenceTier.both,
        shopItem: 'Magnesium supplement',
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/8260-menstrual-migraines-hormone-headaches',
          ),
          Source(
            'American Migraine Foundation',
            'https://americanmigrainefoundation.org/resource-library/menstrual-migraine-treatment-and-prevention/',
          ),
        ],
      ),
      Remedy(
        title: 'Steady sleep, meals and hydration',
        howTo: 'Keep a regular sleep schedule, avoid skipping meals, and drink '
            'enough water, particularly around your period.',
        whyItHelps:
            'Missed meals, dehydration and disrupted sleep are common migraine '
            'triggers, so keeping them stable heads off attacks.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/8260-menstrual-migraines-hormone-headaches',
          ),
        ],
      ),
      Remedy(
        title: 'Keep a headache and cycle diary',
        howTo:
            'Log each headache alongside your cycle dates plus sleep, food and '
            'stress, and review it for patterns.',
        whyItHelps: 'Confirms the link to your period and reveals triggers, so '
            'treatment can be timed before an attack.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'American Migraine Foundation',
            'https://americanmigrainefoundation.org/resource-library/menstrual-migraine-treatment-and-prevention/',
          ),
        ],
      ),
      Remedy(
        title: 'Time an NSAID around your period',
        howTo: "With your doctor's guidance, take an NSAID such as naproxen "
            'starting a couple of days before your period and through the '
            'first days.',
        whyItHelps:
            "Used as short 'mini-prevention', NSAIDs can reduce the frequency, "
            'severity and duration of menstrual migraine.',
        tier: EvidenceTier.clinical,
        shopItem: 'Naproxen / ibuprofen (NSAID)',
        sources: [
          Source(
            'American Migraine Foundation',
            'https://americanmigrainefoundation.org/resource-library/menstrual-migraine-treatment-and-prevention/',
          ),
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/8260-menstrual-migraines-hormone-headaches',
          ),
        ],
      ),
    ],
  ),
  'backPain': SymptomAdvice(
    key: 'backPain',
    displayName: 'Back pain',
    seeDoctorIf:
        'See a doctor if back or period pain is severe, worse than usual and '
        'not eased by painkillers, steadily worsening cycle to cycle, or comes '
        'with very heavy or irregular bleeding, pain during sex, fever or '
        'bleeding between periods, which can point to conditions like '
        'endometriosis.',
    remedies: [
      Remedy(
        title: 'Apply heat to your lower back',
        howTo: 'Hold a heat pad or wrapped hot water bottle against your lower '
            'back, or soak in a warm bath.',
        whyItHelps:
            'Relaxes tense muscles and boosts blood flow to the area, easing '
            'cramping-related back ache.',
        tier: EvidenceTier.both,
        shopItem: 'Heat pad / hot water bottle',
        sources: [
          Source(
            'NHS – Period pain',
            'https://www.nhs.uk/symptoms/period-pain/',
          ),
          Source(
            'Cleveland Clinic – Dysmenorrhea',
            'https://my.clevelandclinic.org/health/diseases/4148-dysmenorrhea',
          ),
        ],
      ),
      Remedy(
        title: 'Gentle movement / exercise',
        howTo:
            'Keep moving with walking, swimming or cycling on most days rather '
            'than staying still.',
        whyItHelps:
            'Releases endorphins; exercise showed the largest pain-reducing '
            'effect in reviews of menstrual pain.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'NCBI/PMC systematic review',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC6337810/',
          ),
          Source(
            'NHS – Period pain',
            'https://www.nhs.uk/symptoms/period-pain/',
          ),
        ],
      ),
      Remedy(
        title: 'Gentle stretching and yoga',
        howTo: 'Spend 5–10 minutes on gentle back and hip stretches such as '
            "child's pose and cat-cow, breathing slowly throughout.",
        whyItHelps:
            'Releases tension in the lower back, hips and pelvis and relaxes '
            'cramping muscles.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'Cleveland Clinic – Dysmenorrhea',
            'https://my.clevelandclinic.org/health/diseases/4148-dysmenorrhea',
          ),
          Source(
            'NCBI/PMC systematic review',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC6337810/',
          ),
        ],
      ),
      Remedy(
        title: 'Massage the lower back and abdomen',
        howTo:
            'Use your hands or ask someone to gently massage your lower back '
            'and lower tummy.',
        whyItHelps:
            'Eases muscle tension and can dampen pain signals, offering relief '
            'alongside heat.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'NHS – Period pain',
            'https://www.nhs.uk/symptoms/period-pain/',
          ),
          Source(
            'Patient.info',
            'https://patient.info/womens-health/periods-and-period-problems/period-pain-dysmenorrhoea',
          ),
        ],
      ),
      Remedy(
        title: 'Try a TENS machine',
        howTo: 'Place the electrode pads on your lower back or abdomen and use '
            'the low-level electrical pulses as directed.',
        whyItHelps:
            'The mild electrical current is thought to interfere with pain '
            'signals travelling to the brain.',
        tier: EvidenceTier.community,
        shopItem: 'TENS machine',
        sources: [
          Source(
            'Patient.info',
            'https://patient.info/womens-health/periods-and-period-problems/period-pain-dysmenorrhoea',
          ),
        ],
      ),
    ],
  ),
  'breastTenderness': SymptomAdvice(
    key: 'breastTenderness',
    displayName: 'Breast tenderness',
    seeDoctorIf:
        'See a doctor if breast pain lasts more than two weeks, keeps getting '
        'worse, is in one fixed spot, or comes with a new lump, nipple '
        'discharge, or skin changes (dimpling, redness).',
    remedies: [
      Remedy(
        title: 'Wear a well-fitted, supportive bra',
        howTo:
            'Get properly measured and wear a supportive (non-underwired) bra '
            'by day, a sports bra for exercise, and a soft bra at night when '
            'tender.',
        whyItHelps:
            'Limits movement and stretching of sensitive breast tissue, which '
            'many people find reduces cyclical soreness.',
        tier: EvidenceTier.both,
        shopItem: 'Supportive / soft bra',
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/15469-breast-pain-mastalgia',
          ),
          Source(
            'Patient.info',
            'https://patient.info/womens-health/breast-problems/breast-pain',
          ),
        ],
      ),
      Remedy(
        title: 'Over-the-counter pain relief',
        howTo:
            'Take paracetamol or ibuprofen on painful days, or rub a topical '
            'anti-inflammatory (NSAID) gel directly onto the sore area.',
        whyItHelps:
            'NSAIDs lower prostaglandins and inflammation; topical forms '
            'target the tender spot with less whole-body exposure.',
        tier: EvidenceTier.clinical,
        shopItem: 'Paracetamol / ibuprofen gel',
        sources: [
          Source(
            'Patient.info',
            'https://patient.info/womens-health/breast-problems/breast-pain',
          ),
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/15469-breast-pain-mastalgia',
          ),
        ],
      ),
      Remedy(
        title: 'Apply heat to the sore area',
        howTo: 'Hold a warm compress, heating pad, or hot water bottle against '
            'the most painful part of the breast for 10–15 minutes.',
        whyItHelps:
            'Warmth relaxes tissue and eases the aching, heavy feeling of '
            'hormone-driven tenderness.',
        tier: EvidenceTier.clinical,
        shopItem: 'Heat pad / hot water bottle',
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/15469-breast-pain-mastalgia',
          ),
        ],
      ),
      Remedy(
        title: 'Cut back on caffeine',
        howTo:
            'Reduce coffee, tea, energy drinks, and chocolate in the week or '
            'two before your period and see whether soreness eases.',
        whyItHelps:
            'Some people find lowering caffeine reduces breast tenderness, and '
            'it is a simple change to trial.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://my.clevelandclinic.org/health/diseases/15469-breast-pain-mastalgia',
          ),
        ],
      ),
      Remedy(
        title: 'Regular aerobic exercise',
        howTo:
            'Aim for regular moderate activity such as brisk walking, cycling, '
            'or swimming across the month, not just when symptoms hit.',
        whyItHelps:
            'Regular exercise is linked to lower overall PMS symptom load, '
            'including physical symptoms like breast sensitivity.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
          Source(
            'NCBI/PMC',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC7465566/',
          ),
        ],
      ),
    ],
  ),
  'nausea': SymptomAdvice(
    key: 'nausea',
    displayName: 'Nausea',
    seeDoctorIf:
        "Seek care if you can't keep fluids down, vomit blood or something "
        'like coffee grounds, have severe or persistent vomiting, high fever, '
        'severe one-sided or worsening pain, or unexplained weight loss.',
    remedies: [
      Remedy(
        title: 'Try ginger',
        howTo: 'Sip ginger tea, chew a small piece of fresh ginger, or take '
            'ginger in divided doses through the day when queasy.',
        whyItHelps:
            'Ginger acts on the gut and is a well-studied, effective remedy '
            'for nausea and vomiting in several settings.',
        tier: EvidenceTier.both,
        shopItem: 'Ginger tea / fresh ginger',
        sources: [
          Source('PubMed', 'https://pubmed.ncbi.nlm.nih.gov/22951628/'),
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/nausea-during-period',
          ),
        ],
      ),
      Remedy(
        title: 'Peppermint aromatherapy',
        howTo: 'Inhale the scent of peppermint essential oil or sip peppermint '
            'tea when nausea rises.',
        whyItHelps:
            'Peppermint has been shown in trials to reduce nausea severity and '
            'is a low-risk thing to try.',
        tier: EvidenceTier.both,
        shopItem: 'Peppermint tea / oil',
        sources: [
          Source(
            'NCBI/PMC',
            'https://pmc.ncbi.nlm.nih.gov/articles/PMC7605047/',
          ),
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/nausea-during-period',
          ),
        ],
      ),
      Remedy(
        title: 'Small, bland meals and sip fluids',
        howTo:
            'Eat little and often, choosing plain foods like crackers, toast, '
            'or rice, and keep sipping water or a clear drink through the day.',
        whyItHelps:
            'An empty or overloaded stomach worsens queasiness; bland food and '
            'steady fluids settle the stomach and prevent dehydration.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/nausea-during-period',
          ),
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Fresh air and gentle movement',
        howTo: 'Step outside for fresh air or take a slow walk, and distract '
            'yourself with music or a show when nausea peaks.',
        whyItHelps:
            'Light activity and distraction can ease the sensation of nausea '
            'and reduce focus on it.',
        tier: EvidenceTier.community,
        sources: [
          Source(
            'Medical News Today',
            'https://www.medicalnewstoday.com/articles/nausea-during-period',
          ),
        ],
      ),
    ],
  ),
  'insomnia': SymptomAdvice(
    key: 'insomnia',
    displayName: 'Insomnia',
    seeDoctorIf:
        'Talk to a doctor if poor sleep is severe, lasts beyond a few cycles, '
        'or affects your daily functioning and mood, so causes like PMDD or a '
        'sleep disorder can be checked.',
    remedies: [
      Remedy(
        title: 'Keep a consistent sleep schedule',
        howTo:
            'Go to bed and wake up at about the same time every day, including '
            'weekends, and avoid long daytime naps.',
        whyItHelps:
            'A steady rhythm supports your body clock, which is easier to '
            'disrupt when hormones shift before your period.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Sleep Foundation',
            'https://www.sleepfoundation.org/insomnia/pms-and-insomnia',
          ),
        ],
      ),
      Remedy(
        title: 'Cool, dark, quiet bedroom',
        howTo: 'Keep the room dark, quiet, and slightly cool, and stop using '
            'screens in bed.',
        whyItHelps:
            'A cool, dark environment aids sleep onset and offsets the higher '
            'body temperature and restlessness of the luteal phase.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Sleep Foundation',
            'https://www.sleepfoundation.org/insomnia/pms-and-insomnia',
          ),
        ],
      ),
      Remedy(
        title: 'Limit caffeine and alcohol before bed',
        howTo:
            'Avoid caffeine for at least 6 hours before bed and limit alcohol '
            'and cigarettes in the hours before sleep.',
        whyItHelps: 'Caffeine is a stimulant and alcohol fragments sleep, both '
            'compounding premenstrual sleep problems.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Sleep Foundation',
            'https://www.sleepfoundation.org/insomnia/pms-and-insomnia',
          ),
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Wind-down routine and daytime exercise',
        howTo:
            'Build a calming pre-bed routine such as reading, gentle yoga, or '
            'music, and get about 30 minutes of exercise earlier in the day.',
        whyItHelps:
            'Relaxation lowers pre-sleep arousal and regular daytime activity '
            'deepens sleep and improves mood.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Sleep Foundation',
            'https://www.sleepfoundation.org/insomnia/pms-and-insomnia',
          ),
          Source(
            'NHS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
        ],
      ),
      Remedy(
        title: 'Consider CBT-I',
        howTo: 'If insomnia recurs each cycle, ask a clinician about cognitive '
            'behavioural therapy for insomnia (CBT-I), available in-person or '
            'via apps.',
        whyItHelps:
            'CBT-I retrains the thoughts and habits that keep insomnia going '
            'and is a first-line, drug-free treatment.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Sleep Foundation',
            'https://www.sleepfoundation.org/insomnia/pms-and-insomnia',
          ),
        ],
      ),
    ],
  ),
  'cravings': SymptomAdvice(
    key: 'cravings',
    displayName: 'Cravings',
    seeDoctorIf:
        'See a doctor if cravings come with severe mood symptoms or binge '
        'eating that disrupt your life (possible PMDD), or if you crave '
        'non-food items like ice or dirt, which can signal iron deficiency.',
    remedies: [
      Remedy(
        title: 'Prioritise complex carbs and fibre',
        howTo:
            'Base meals on whole grains, legumes, starchy vegetables, fruit, '
            'and vegetables rather than refined sugar.',
        whyItHelps:
            'Complex carbs support serotonin and keep blood sugar steady, so '
            'you feel fuller and crave less.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/period-cravings',
          ),
          Source(
            'Office on Women\'s Health',
            'https://womenshealth.gov/menstrual-cycle/premenstrual-syndrome',
          ),
        ],
      ),
      Remedy(
        title: 'Keep protein-rich snacks ready',
        howTo:
            'Prep snacks like Greek yoghurt with fruit, cottage cheese, nuts, '
            'or seeds so a satisfying option is on hand when a craving hits.',
        whyItHelps:
            'Protein and healthy fats are more filling than sugary snacks and '
            'blunt the urge to keep grazing.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/period-cravings',
          ),
        ],
      ),
      Remedy(
        title: 'Eat small, regular meals and stay hydrated',
        howTo: 'Eat several small balanced meals through the day instead of '
            'skipping and overeating later, and drink water regularly.',
        whyItHelps:
            'Stable blood sugar and good hydration prevent the dips and thirst '
            'that get mistaken for cravings.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/period-cravings',
          ),
          Source(
            'NHS',
            'https://www.nhs.uk/conditions/pre-menstrual-syndrome/',
          ),
        ],
      ),
      Remedy(
        title: 'Move and sleep well',
        howTo: 'Keep up regular exercise and aim for a consistent, adequate '
            "night's sleep in the premenstrual week.",
        whyItHelps:
            'Exercise and sleep lower stress and steady the hunger hormones '
            'and cravings that poor sleep amplifies.',
        tier: EvidenceTier.clinical,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/period-cravings',
          ),
        ],
      ),
      Remedy(
        title: 'Healthy swaps, without over-restricting',
        howTo:
            'Satisfy a chocolate or sweet craving with a smaller or healthier '
            'version, and allow an occasional treat rather than banning it.',
        whyItHelps:
            'Gentle substitution and avoiding extreme restriction help you '
            'enjoy food while sidestepping guilt-driven overeating.',
        tier: EvidenceTier.both,
        sources: [
          Source(
            'Cleveland Clinic',
            'https://health.clevelandclinic.org/period-cravings',
          ),
        ],
      ),
    ],
  ),
};
