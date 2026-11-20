library;

import '../app_constants/app_strings.dart';

T? _fromValue<T extends Enum>(
  List<T> values,
  Object? raw,
  String Function(T) value, [
  Map<String, T> legacy = const {},
]) {
  for (final item in values) {
    if (value(item) == raw) return item;
  }
  return legacy[raw];
}

enum Sector {
  healthtech('healthtech', 'HealthTech'),
  fintech('fintech', 'Fintech'),
  edtech('edtech', 'EdTech'),
  ecommerce('ecommerce', 'E-commerce'),
  logistics('logistics', 'Logistics'),
  agritech('agritech', 'AgriTech'),
  proptech('proptech', 'PropTech'),
  cleantech('cleantech', 'CleanTech'),
  tourism('tourism', 'Tourism'),
  saas('saas', 'SaaS'),
  ai('ai', 'AI'),
  cybersecurity('cybersecurity', 'Cybersecurity'),
  gaming('gaming', 'Gaming'),
  media('media', 'Media'),
  foodtech('foodtech', 'FoodTech'),
  mobility('mobility', 'Mobility'),
  retail('retail', 'Retail'),
  energy('energy', 'Energy'),
  insurtech('insurtech', 'InsurTech'),
  legaltech('legaltech', 'LegalTech'),
  hrtech('hr_tech', 'HR Tech'),
  biotech('biotech', 'Biotech'),
  manufacturing('manufacturing', 'Manufacturing'),
  sports('sports', 'Sports'),
  other('other', 'Other');

  const Sector(this.value, this.label);

  final String value;
  final String label;

  static const _legacy = {
    'ecommerce_retail': Sector.ecommerce,
    'logistics_transport': Sector.logistics,
    'food_beverage': Sector.foodtech,
    'software_cloud': Sector.saas,
    'hrtech': Sector.hrtech,
  };

  static Sector? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);

  /// The sector with this display label ("HR Tech"), or null.
  static Sector? fromLabel(String label) {
    for (final item in values) {
      if (item.label == label) return item;
    }
    return null;
  }
}

enum StartupStage {
  preSeed('pre_seed', 'Pre-seed'),
  seed('seed', 'Seed'),
  seriesA('series_a', 'Series A'),
  seriesB('series_b', 'Series B'),
  seriesC('series_c', 'Series C'),
  other('other', 'Other');

  const StartupStage(this.value, this.label);

  final String value;
  final String label;

  /// The stages a founder can pick (and investors can follow), in order.
  static const picks = [preSeed, seed, seriesA, seriesB, seriesC];

  static const _legacy = {
    'idea': StartupStage.preSeed,
    'mvp': StartupStage.preSeed,
    'early_revenue': StartupStage.seed,
    'growth': StartupStage.seriesA,
  };

  static StartupStage? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
}

enum CommerceModel {
  b2g('b2g', 'Business-to-Government (B2G)', 'B2G'),
  b2b('b2b', 'Business-to-Business (B2B)', 'B2B'),
  b2b2c('b2b2c', 'Business-to-Business-to-Consumer (B2B2C)', 'B2B2C'),
  d2c('d2c', 'Direct-to-Consumer (D2C)', 'D2C'),
  b2c('b2c', 'Business-to-Consumer (B2C)', 'B2C'),
  c2c('c2c', 'Consumer-to-Consumer (C2C)', 'C2C'),
  b2e('b2e', 'Business-to-Employee (B2E)', 'B2E'),
  c2b('c2b', 'Consumer-to-Business (C2B)', 'C2B'),
  g2c('g2c', 'Government-to-Citizen (G2C)', 'G2C'),
  g2g('g2g', 'Government-to-Government (G2G)', 'G2G'),
  other('other', 'Other', 'Other');

  const CommerceModel(this.value, this.label, this.shortLabel);

  final String value;

  /// Full text for the dropdown, e.g.
  final String label;

  /// Just the abbreviation, for cards and the profile ("B2C"; "Other").
  final String shortLabel;

  /// The four commerce models that can be picked, in this order.
  static const picks = [b2b, b2c, b2g, other];

  static const _legacy = {'marketplace': CommerceModel.other};

  static CommerceModel? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
}

/// A city.
class StartupLocation {
  const StartupLocation._(this.value, this.label);

  final String value;
  final String label;

  static String _slug(String city) =>
      city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  /// Every selectable city, in the shared list's order.
  static final List<StartupLocation> values = List.unmodifiable([
    for (final city in AppStrings.allCities)
      StartupLocation._(_slug(city), city),
  ]);

  factory StartupLocation.custom(String label) =>
      StartupLocation._(_slug(label), label);

  /// Only exists so old documents with city "other" still load.
  static const other = StartupLocation._('other', 'Other');

  static const riyadh = StartupLocation._('riyadh', 'Riyadh');
  static const jeddah = StartupLocation._('jeddah', 'Jeddah');
  static const dammam = StartupLocation._('dammam', 'Dammam');
  static const makkah = StartupLocation._('makkah', 'Makkah');
  static const madinah = StartupLocation._('madinah', 'Madinah');

  static const _legacy = {
    'taif': 'taif',
    'unaizah': 'unaizah',
    'yanbu': 'yanbu',
    'khobar': 'al_khobar',
    'mecca': 'makkah',
    'medina': 'madinah',
  };

  static StartupLocation? fromValue(Object? raw) {
    if (raw is! String) return null;
    if (raw == other.value) return other;
    final current = _legacy[raw] ?? raw;
    for (final item in values) {
      if (item.value == current) return item;
    }
    if (const ['taif', 'unaizah', 'yanbu'].contains(current)) {
      return StartupLocation._(
        current,
        '${current[0].toUpperCase()}${current.substring(1)}',
      );
    }
    if (RegExp(r'^[a-z0-9_]+$').hasMatch(current) && current.isNotEmpty) {
      final words = current.split('_').where((w) => w.isNotEmpty);
      return StartupLocation._(
        current,
        [for (final w in words) '${w[0].toUpperCase()}${w.substring(1)}']
            .join(' '),
      );
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is StartupLocation && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'StartupLocation($value)';
}

enum LookingFor {
  funding('funding', 'Funding'),
  cofounder('cofounder', 'Co-founder'),
  talent('talent', 'Talent'),
  partnership('partnership', 'Partnership'),
  support('support', 'Support'),
  mentorship('mentorship', 'Mentorship'),
  advisors('advisors', 'Advisors'),
  marketing('marketing', 'Marketing'),
  techDevelopment('tech_development', 'Tech development'),
  other('other', 'Other');

  const LookingFor(this.value, this.label);

  final String value;
  final String label;

  static const _legacy = {
    'partnerships': LookingFor.partnership,
    'team_members': LookingFor.talent,
    'services': LookingFor.techDevelopment,
  };

  static LookingFor? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
}
