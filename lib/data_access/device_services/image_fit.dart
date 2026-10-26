import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Makes a picked (already cropped) photo or logo small enough to be saved
/// INSIDE a Firestore document, so no Firebase Storage is needed.
///
/// The pickers already crop to a square and compress to at most 256 x 256,
/// JPEG ~70 %. That is normally 10-40 KB. If a file is still over
/// [maxBytes], it is compressed again with a lower quality until it fits.
class ImageFit {
  const ImageFit._();

  /// The largest picture we store (about 100 KB as bytes; as base64 text this
  /// is ~137,000 characters, under the 150,000 the rules allow).
  static const maxBytes = 100 * 1024;

  /// The qualities tried, in order, when the file is too big.
  static const _qualities = [60, 50, 40, 30, 20];

  /// The bytes of [file], compressed until they are at most [maxBytes].
  /// Throws [ImageTooLarge] when it can't be made small enough. When it had to
  /// be compressed again, [file] is overwritten with the smaller version.
  static Future<Uint8List> bytesUnder(File file) async {
    final original = await file.readAsBytes();
    if (original.length <= maxBytes) return original;
    final decoded = await compute(img.decodeImage, original);
    if (decoded == null) throw const ImageTooLarge();
    for (final q in _qualities) {
      final out = Uint8List.fromList(img.encodeJpg(decoded, quality: q));
      if (out.length <= maxBytes) {
        await file.writeAsBytes(out);
        return out;
      }
    }
    throw const ImageTooLarge();
  }

  /// The picture as the base64 text saved in `photoData` / `logoData`.
  static Future<String> base64Of(File file) async =>
      base64Encode(await bytesUnder(file));
}

/// A picture that can't be brought under [ImageFit.maxBytes].
class ImageTooLarge implements Exception {
  const ImageTooLarge();
}
