/// The "Other" write-in can't repeat an option that is already in the list.
///
/// Two texts count as the same when they only differ by capital letters,
/// spaces, symbols or one trailing "s": "fintech", "FinTechs" and "Fin Tech" are all
/// the option "FinTech".
class OtherCheck {
  const OtherCheck._();

  static String _key(String text) {
    // Letters and digits only: capitals, spaces, hyphens, brackets and
    // other symbols don't make a text different.
    var k = text.toLowerCase().replaceAll(
      RegExp(r'[^\p{L}\p{N}]', unicode: true),
      '',
    );
    if (k.length > 1 && k.endsWith('s')) k = k.substring(0, k.length - 1);
    return k;
  }

  /// True when [typed] is one of [options] (see above). Blank never repeats.
  static bool repeats(String? typed, Iterable<String> options) {
    final t = (typed ?? '').trim();
    if (t.isEmpty) return false;
    final key = _key(t);
    return options.any((o) => _key(o) == key);
  }
}
