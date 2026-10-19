/// Matches tab, part 1: reading the documents and the hard filters
/// (knowledge-based). Part 2, the score and the ranking, is
/// content_ranker.dart.
///
/// Works on the Firestore documents as stored (field names agreed on
/// 19 Oct 2026, see firestore-field-names-v1.md):
/// - `startups/{id}`: stored values ('fintech', 'seed', 'b2b', 'riyadh').
/// - `investors/{id}`: labels ('Fintech', 'Seed', 'SAR 100K – 500K').
///
/// The Python reference is matching_v2.py; test/recommender/matching_test.dart
/// checks that both give the same results.
library;

/// Investor sector label -> the startups' stored value (the 25 sectors).
const Map<String, String> sectorValue = {
  'HealthTech': 'healthtech',
  'Fintech': 'fintech',
  'EdTech': 'edtech',
  'E-commerce': 'ecommerce',
  'Logistics': 'logistics',
  'AgriTech': 'agritech',
  'PropTech': 'proptech',
  'CleanTech': 'cleantech',
  'Tourism': 'tourism',
  'SaaS': 'saas',
  'AI': 'ai',
  'Cybersecurity': 'cybersecurity',
  'Gaming': 'gaming',
  'Media': 'media',
  'FoodTech': 'foodtech',
  'Mobility': 'mobility',
  'Retail': 'retail',
  'Energy': 'energy',
  'InsurTech': 'insurtech',
  'LegalTech': 'legaltech',
  'HR Tech': 'hr_tech',
  'Biotech': 'biotech',
  'Manufacturing': 'manufacturing',
  'Sports': 'sports',
  'Other': 'other',
};

/// Investor stage label -> the startups' stored value.
const Map<String, String> stageValue = {
  'Pre-seed': 'pre_seed',
  'Seed': 'seed',
  'Series A': 'series_a',
  'Series B': 'series_b',
  'Series C': 'series_c',
  'Other': 'other',
};

/// Investor commerce-model label -> the startups' stored `businessModel`.
const Map<String, String> modelValue = {
  'Business-to-Government (B2G)': 'b2g',
  'Business-to-Business (B2B)': 'b2b',
  'Business-to-Business-to-Consumer (B2B2C)': 'b2b2c',
  'Direct-to-Consumer (D2C)': 'd2c',
  'Business-to-Consumer (B2C)': 'b2c',
  'Consumer-to-Consumer (C2C)': 'c2c',
  'Business-to-Employee (B2E)': 'b2e',
  'Consumer-to-Business (C2B)': 'c2b',
  'Government-to-Citizen (G2C)': 'g2c',
  'Government-to-Government (G2G)': 'g2g',
  'Other': 'other',
};

/// City label -> its region (the app's 25 cities). The region is never
/// stored: it is worked out from the city.
const Map<String, String> cityRegion = {
  'Abha': 'Asir',
  'Al Ahsa': 'Eastern Province',
  'Al Baha': 'Al Baha',
  'Al Jubail': 'Eastern Province',
  'Al Kharj': 'Riyadh',
  'Al Khobar': 'Eastern Province',
  'Al Qatif': 'Eastern Province',
  'Arar': 'Northern Borders',
  'Buraydah': 'Qassim',
  'Dammam': 'Eastern Province',
  'Dhahran': 'Eastern Province',
  'Hafar Al Batin': 'Eastern Province',
  'Hail': 'Hail',
  'Jazan': 'Jazan',
  'Jeddah': 'Makkah',
  'Khamis Mushait': 'Asir',
  'Makkah': 'Makkah',
  'Madinah': 'Madinah',
  'Najran': 'Najran',
  'Riyadh': 'Riyadh',
  'Sakaka': 'Al Jouf',
  'Tabuk': 'Tabuk',
  'Taif': 'Makkah',
  'Unaizah': 'Qassim',
  'Yanbu': 'Madinah',
};

/// "How much do you usually invest in one startup?" -> the band's minimum
/// in SAR. Null (Other, or no answer) means the ticket is not checked.
const Map<String, int?> ticketMin = {
  'Under SAR 100K': 0,
  'SAR 100K – 500K': 100000,
  'SAR 500K – 1M': 500000,
  'SAR 1M – 5M': 1000000,
  'Over SAR 5M': 5000000,
  'Other': null,
};

/// "How many startups have you invested in?" -> the activity boost signal.
const Map<String, double> activityByCount = {
  '0': 0.0,
  '1–5': 0.5,
  '6–15': 1.0,
  '16+': 1.0,
};

/// "Al Khobar" -> "al_khobar" (same rule as StartupLocation).
String citySlug(String city) =>
    city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

final Map<String, String> _cityBySlug = {
  for (final city in cityRegion.keys) citySlug(city): city,
};

int? _int(Object? raw) => raw is num ? raw.toInt() : null;

/// The fields of a `startups/{id}` document that matching reads.
class MatchStartup {
  MatchStartup.fromMap(this.id, Map<String, dynamic> data)
    : name = (data['name'] as String?) ?? '',
      sector = data['sector'] as String?,
      stage = data['stage'] as String?,
      businessModel = data['businessModel'] as String?,
      location = data['location'] as String?,
      lookingFor = [
        for (final v in (data['lookingFor'] as List?) ?? const [])
          if (v is String) v,
      ],
      fundingRequirement = _int(data['fundingRequirement']),
      isPublic = data['isPublic'] == true,
      crunchbaseRank = _int(data['crunchbaseRank']);

  final String id;
  final String name;
  final String? sector;
  final String? stage;
  final String? businessModel;
  final String? location;
  final List<String> lookingFor;
  final int? fundingRequirement;
  final bool isPublic;

  /// Dataset startups only; used to break ties.
  final int? crunchbaseRank;

  bool get isRaising =>
      lookingFor.contains('funding') && (fundingRequirement ?? 0) > 0;

  String? get region => cityRegion[_cityBySlug[location ?? '']];
}

/// The fields of an `investors/{id}` document that matching reads. The
/// lists are turned into the startups' stored values once, here.
class MatchInvestor {
  MatchInvestor.fromMap(this.id, Map<String, dynamic> data)
    : name = (data['fullName'] as String?) ?? '',
      sectors = _values(data['preferredSectors'], sectorValue),
      stages = _values(data['preferredStages'], stageValue),
      models = _values(data['preferredCommerceModels'], modelValue),
      city = data['city'] as String?,
      ticketSize = data['ticketSize'] as String?,
      roundSizeMin = _int(data['roundSizeMin']),
      roundSizeMax = _int(data['roundSizeMax']),
      investmentsCount = data['investmentsCount'] as String?,
      crunchbaseRank = _int(data['crunchbaseRank']);

  final String id;
  final String name;
  final Set<String> sectors;
  final Set<String> stages;
  final Set<String> models;
  final String? city;
  final String? ticketSize;
  final int? roundSizeMin;
  final int? roundSizeMax;
  final String? investmentsCount;

  /// Dataset investors only; used to break ties.
  final int? crunchbaseRank;

  static Set<String> _values(Object? raw, Map<String, String> toValue) => {
    if (raw is List)
      for (final label in raw)
        if (label is String && toValue.containsKey(label)) toValue[label]!,
  };

  /// Matches opens only after the investor chose sectors and stages.
  bool get interestsComplete => sectors.isNotEmpty && stages.isNotEmpty;

  String? get region => cityRegion[city ?? ''];
}

/// Null = not checked (the startup isn't raising, or the ticket is Other).
bool? ticketFits(MatchInvestor investor, MatchStartup startup) {
  if (!startup.isRaising) return null;
  final min = ticketMin[investor.ticketSize ?? ''];
  if (min == null) return null;
  return min <= startup.fundingRequirement!;
}

/// Null = not checked (the startup isn't raising, or no round size given).
bool? roundSizeFits(MatchInvestor investor, MatchStartup startup) {
  final lo = investor.roundSizeMin;
  final hi = investor.roundSizeMax;
  if (!startup.isRaising || (lo == null && hi == null)) return null;
  final need = startup.fundingRequirement!;
  return (lo == null || need >= lo) && (hi == null || need <= hi);
}

/// The hard filters a pair fails; empty = the pair can match.
List<String> failedFilters(MatchInvestor investor, MatchStartup startup) => [
  if (!investor.sectors.contains(startup.sector)) 'sector',
  if (!investor.stages.contains(startup.stage)) 'stage',
  if (ticketFits(investor, startup) == false) 'ticket',
  if (roundSizeFits(investor, startup) == false) 'round size',
];

/// A close match: not an exact one, but the sector or the stage fits and
/// the ticket and round size still fit. Close matches fill a Matches list
/// after every exact match, so every startup gets matches.
bool isClose(MatchInvestor investor, MatchStartup startup) {
  final failed = failedFilters(investor, startup);
  return failed.length == 1 &&
      (failed.first == 'sector' || failed.first == 'stage');
}
