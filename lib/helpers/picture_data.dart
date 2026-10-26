import 'dart:convert';
import 'dart:typed_data';

/// Turns the base64 text saved in `photoData` / `logoData` into image bytes.
///
/// Each picture is decoded ONCE and kept, so lists and rebuilds never decode
/// the same text again (the same [Uint8List] also lets Flutter's image cache
/// recognise it).
class PictureData {
  const PictureData._();

  static final Map<String, Uint8List> _cache = {};

  /// Newest pictures kept (a few hundred KB at most each).
  static const _maxCached = 120;

  /// The bytes of [base64Text], or null when there is none or it is not valid.
  static Uint8List? bytes(String? base64Text) {
    final text = (base64Text ?? '').trim();
    if (text.isEmpty) return null;
    final hit = _cache[text];
    if (hit != null) return hit;
    try {
      final decoded = base64Decode(text);
      if (decoded.isEmpty) return null;
      if (_cache.length >= _maxCached) _cache.remove(_cache.keys.first);
      return _cache[text] = decoded;
    } catch (_) {
      return null;
    }
  }

  /// Forget everything (tests).
  static void clear() => _cache.clear();
}
