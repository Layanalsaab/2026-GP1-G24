/// Runway: how long the current capital lasts at the current burn rate.
class Runway {
  Runway._();

  /// Whole months of runway (at least 1), or null when it is not a number of
  /// months (no burn, or no capital).
  static int? months(int? capital, int? burn) {
    if (capital == null || burn == null || burn <= 0 || capital <= 0) {
      return null;
    }
    final m = capital ~/ burn;
    return m < 1 ? 1 : m;
  }

  /// "About 6 months of runway", "About 1 month of runway",
  /// "Cash-flow positive" (burn 0), "No runway left" (capital 0), or null
  /// while the burn rate is empty.
  static String? label(int? capital, int? burn) {
    if (burn == null) return null;
    if (burn <= 0) return 'Cash-flow positive';
    if (capital == null || capital <= 0) return 'No runway left';
    final m = months(capital, burn)!;
    return m == 1 ? 'About 1 month of runway' : 'About $m months of runway';
  }

  /// The short form for a box: "About 6 months" / "Cash-flow positive".
  static String? short(int? capital, int? burn) {
    final l = label(capital, burn);
    if (l == null) return null;
    return l.endsWith(' of runway') ? l.substring(0, l.length - 10) : l;
  }
}
