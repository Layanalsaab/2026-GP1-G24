/// Runway: how long the current capital lasts at the current burn rate.
class Runway {
  Runway._();

  static int? months(int? capital, int? burn) {
    if (capital == null || burn == null || burn <= 0 || capital <= 0) {
      return null;
    }
    final m = capital ~/ burn;
    return m < 1 ? 1 : m;
  }

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

  static String? line(int? capital, int? burn) {
    final s = short(capital, burn);
    return s == 'No runway left' ? 'No money left' : s;
  }
}
