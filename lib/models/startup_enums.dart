/// Every fixed list used by a startup profile (Figma "Add Startup" /
/// "Edit Startup"). Each value has:
/// - [value]: the string stored in Firestore (never change it once shipped),
/// - [label]: the text shown in the UI.
///
/// Older documents stored a previous set of values. Each `fromValue` still
/// reads those (see the `_legacy` maps) and returns the nearest current
/// value; new writes always use the current values.
library;

import '../app_constants/app_strings.dart';

/// Shared lookup so each enum can turn a Firestore string back into a value.
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
  other('other', 'Other');

  const Sector(this.value, this.label);

  final String value;
  final String label;

  /// Stored values from before the Figma list: old value -> nearest sector.
  static const _legacy = {
    'ecommerce_retail': Sector.ecommerce,
    'logistics_transport': Sector.logistics,
    'food_beverage': Sector.other,
    'software_cloud': Sector.other,
  };

  static Sector? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
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

  static const _legacy = {
    'idea': StartupStage.preSeed,
    'mvp': StartupStage.preSeed,
    'early_revenue': StartupStage.seed,
    'growth': StartupStage.seriesA,
  };

  static StartupStage? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
}

/// The "Commerce model" field (called "business model" in older code and
/// in the stored field name `businessModel`).
enum BusinessModel {
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

  const BusinessModel(this.value, this.label, this.shortLabel);

  final String value;

  /// Full text for the dropdown, e.g. "Business-to-Consumer (B2C)".
  final String label;

  /// Just the abbreviation, for cards and the profile ("B2C"; "Other").
  final String shortLabel;

  static const _legacy = {'marketplace': BusinessModel.other};

  static BusinessModel? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value, _legacy);
}

/// A city. Not an enum: the list is the same city list the Create Account
/// screen uses ([AppStrings.allCities]), so the two can never drift apart.
class StartupLocation {
  const StartupLocation._(this.value, this.label);

  /// Stored string: the city name lower-cased with underscores
  /// ("Al Khobar" -> "al_khobar").
  final String value;
  final String label;

  static String _slug(String city) =>
      city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  /// Every selectable city, in the shared list's order.
  static final List<StartupLocation> values = List.unmodifiable([
    for (final city in AppStrings.allCities)
      StartupLocation._(_slug(city), city),
  ]);

  /// Only exists so old documents with city "other" still load. It is not in
  /// [values], so it can't be picked on a new startup.
  static const other = StartupLocation._('other', 'Other');

  // Const handles for the cities the app refers to by name (samples, tests).
  // Equality is by [value], so they equal the instances in [values].
  static const riyadh = StartupLocation._('riyadh', 'Riyadh');
  static const jeddah = StartupLocation._('jeddah', 'Jeddah');
  static const dammam = StartupLocation._('dammam', 'Dammam');
  static const alKhobar = StartupLocation._('al_khobar', 'Al Khobar');
  static const makkah = StartupLocation._('makkah', 'Makkah');
  static const madinah = StartupLocation._('madinah', 'Madinah');

  static const _legacy = {
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
