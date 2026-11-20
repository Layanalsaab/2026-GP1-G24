import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageFit {
  const ImageFit._();

  static const maxBytes = 100 * 1024;

  /// The qualities tried, in order, when the file is too big.
  static const _qualities = [60, 50, 40, 30, 20];

  /// The bytes of file, compressed until they are at most maxBytes.
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

  /// The picture as the base64 text saved in photoData / logoData.
  static Future<String> base64Of(File file) async =>
      base64Encode(await bytesUnder(file));
}

/// A picture that can't be brought under ImageFit.maxBytes.
class ImageTooLarge implements Exception {
  const ImageTooLarge();
}
