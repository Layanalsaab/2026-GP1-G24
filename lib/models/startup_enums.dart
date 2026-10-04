/// Every fixed list used by a startup profile. Each value has:
/// - [value]: the string stored in Firestore (never change it once shipped),
/// - [label]: the text shown in the UI.
library;

/// Shared lookup so each enum can turn a Firestore string back into a value.
T? _fromValue<T extends Enum>(
  List<T> values,
  Object? raw,
  String Function(T) value,
) {
  for (final item in values) {
    if (value(item) == raw) return item;
  }
  return null;
}

enum Sector {
  fintech('fintech', 'FinTech'),
  ecommerceRetail('ecommerce_retail', 'E-commerce & Retail'),
  healthtech('healthtech', 'HealthTech'),
  edtech('edtech', 'EdTech'),
  logisticsTransport('logistics_transport', 'Logistics & Transport'),
  foodBeverage('food_beverage', 'Food & Beverage'),
  softwareCloud('software_cloud', 'Software & Cloud Services'),
  other('other', 'Other');

  const Sector(this.value, this.label);

  final String value;
  final String label;

  static Sector? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value);
}

enum StartupStage {
  idea('idea', 'Idea'),
  mvp('mvp', 'MVP'),
  earlyRevenue('early_revenue', 'Early revenue'),
  growth('growth', 'Growth');

  const StartupStage(this.value, this.label);

  final String value;
  final String label;

  static StartupStage? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value);
}

enum BusinessModel {
  b2b('b2b', 'B2B'),
  b2c('b2c', 'B2C'),
  b2b2c('b2b2c', 'B2B2C'),
  marketplace('marketplace', 'Marketplace');

  const BusinessModel(this.value, this.label);

  final String value;
  final String label;

  static BusinessModel? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value);
}

enum StartupLocation {
  riyadh('riyadh', 'Riyadh'),
  jeddah('jeddah', 'Jeddah'),
  dammam('dammam', 'Dammam'),
  khobar('khobar', 'Khobar'),
  mecca('mecca', 'Mecca'),
  medina('medina', 'Medina'),
  tabuk('tabuk', 'Tabuk'),
  abha('abha', 'Abha'),
  other('other', 'Other');

  const StartupLocation(this.value, this.label);

  final String value;
  final String label;

  static StartupLocation? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value);
}

enum LookingFor {
  funding('funding', 'Funding'),
  partnerships('partnerships', 'Partnerships'),
  teamMembers('team_members', 'Team members'),
  mentorship('mentorship', 'Mentorship'),
  services('services', 'Services');

  const LookingFor(this.value, this.label);

  final String value;
  final String label;

  static LookingFor? fromValue(Object? raw) =>
      _fromValue(values, raw, (e) => e.value);
}
