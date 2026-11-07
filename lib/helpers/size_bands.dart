/// The five size bands used by the Hub filters "Raising" (startups) and
/// "Investment size" (investors). Same labels as the investor sign-up.
class SizeBand {
  const SizeBand(this.label, this.low, this.high);

  final String label;

  /// In SAR; the band is [low] up to, but not including, [high].
  final int low;
  final int high;

  static const _open = 1000000000000;

  static const all = [
    SizeBand('Under SAR 100K', 0, 100000),
    SizeBand('SAR 100K – 500K', 100000, 500000),
    SizeBand('SAR 500K – 1M', 500000, 1000000),
    SizeBand('SAR 1M – 5M', 1000000, 5000000),
    SizeBand('Over SAR 5M', 5000000, _open),
  ];

  static final labels = [for (final b in all) b.label];

  static SizeBand? of(String label) {
    for (final b in all) {
      if (b.label == label) return b;
    }
    return null;
  }

  /// A startup raising [amount] is in the band (a startup that is not raising
  /// is in none).
  bool containsAmount(int? amount) =>
      amount != null && amount > 0 && amount >= low && amount < high;

  /// An investor whose usual ticket runs from [from] to [to] overlaps the
  /// band.
  bool overlaps(int from, int to) => to >= low && from < high;

  /// "SAR 100K – 500K" -> (100000, 500000); "Under SAR 100K" -> (0, 100000);
  /// "Over SAR 5M" -> (5000000, no limit); null when it is not a range
  /// ("Other", empty).
  static ({int low, int high})? parseRange(String text) {
    final t = text.replaceAll(',', '').trim();
    if (t.isEmpty) return null;
    final found = RegExp(r'(\d+(?:\.\d+)?)\s*([KkMm])?').allMatches(t).toList();
    if (found.isEmpty) return null;
    int value(RegExpMatch m, String? unit) {
      final n = double.parse(m.group(1)!);
      final u = (unit ?? m.group(2) ?? '').toUpperCase();
      return (n * (u == 'M' ? 1000000 : (u == 'K' ? 1000 : 1))).round();
    }

    if (found.length == 1) {
      final v = value(found.first, null);
      if (t.startsWith('Under')) return (low: 0, high: v);
      if (t.startsWith('Over')) return (low: v, high: _open);
      return (low: v, high: v);
    }
    // "100K – 500K": a missing unit on the first number is the second's.
    final unit = found[1].group(2);
    final a = value(found[0], found[0].group(2) ?? unit);
    final b = value(found[1], null);
    return a <= b ? (low: a, high: b) : (low: b, high: a);
  }
}
