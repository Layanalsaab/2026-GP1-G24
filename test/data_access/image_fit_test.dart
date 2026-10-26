import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:startsa/data_access/device_services/image_fit.dart';
import 'package:startsa/helpers/picture_data.dart';

/// A photo-like picture: smooth colour gradients plus some noise.
img.Image _photo(int size, {int noise = 24}) {
  final r = Random(7);
  final im = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      int n() => noise == 0 ? 0 : r.nextInt(noise) - noise ~/ 2;
      im.setPixelRgb(
        x,
        y,
        ((x * 255 / size) + n()).clamp(0, 255).round(),
        ((y * 255 / size) + n()).clamp(0, 255).round(),
        (((x + y) * 128 / size) + n()).clamp(0, 255).round(),
      );
    }
  }
  return im;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('fit'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, List<int> bytes) =>
      File('${dir.path}/$name')..writeAsBytesSync(bytes);

  test('a 256 x 256 JPEG at 70 % is far under 100 KB', () async {
    final bytes = img.encodeJpg(_photo(256), quality: 70);
    // ignore: avoid_print
    print('256x256, quality 70: ${(bytes.length / 1024).toStringAsFixed(1)} KB');
    expect(bytes.length, lessThan(ImageFit.maxBytes));
    final file = write('a.jpg', bytes);
    expect(await ImageFit.bytesUnder(file), hasLength(bytes.length));
  });

  test('a picture over 100 KB is compressed again until it fits', () async {
    final big = img.encodeJpg(_photo(700, noise: 90), quality: 95);
    // ignore: avoid_print
    print('700x700, quality 95: ${(big.length / 1024).toStringAsFixed(1)} KB');
    expect(big.length, greaterThan(ImageFit.maxBytes));
    final file = write('b.jpg', big);
    final out = await ImageFit.bytesUnder(file);
    // ignore: avoid_print
    print('after compressing again: ${(out.length / 1024).toStringAsFixed(1)} KB');
    expect(out.length, lessThanOrEqualTo(ImageFit.maxBytes));
    // The file itself was replaced with the smaller version.
    expect(file.lengthSync(), out.length);
  });

  test('a picture that can never fit is refused', () async {
    final huge = img.encodeJpg(_photo(2400, noise: 255), quality: 100);
    final file = write('c.jpg', huge);
    expect(ImageFit.bytesUnder(file), throwsA(isA<ImageTooLarge>()));
  });

  test('the base64 text stays under the 150000 characters the rules allow', () async {
    final file = write('d.jpg', img.encodeJpg(_photo(256), quality: 70));
    final text = await ImageFit.base64Of(file);
    // ignore: avoid_print
    print('base64 length: ${text.length} characters');
    expect(text.length, lessThan(150000));
    // And it comes back as the same picture.
    expect(PictureData.bytes(text), isNotNull);
  });

  test('PictureData decodes once and ignores bad text', () {
    final text = 'AAAA';
    expect(identical(PictureData.bytes(text), PictureData.bytes(text)), isTrue);
    expect(PictureData.bytes('not base64 !!'), isNull);
    expect(PictureData.bytes(''), isNull);
    expect(PictureData.bytes(null), isNull);
  });
}
