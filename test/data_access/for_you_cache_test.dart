import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/repositories/for_you_cache.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a written list reads back in order', () async {
    final cache = ForYouCache();
    await cache.write('u1', ['s-a', 'i-b']);
    expect(await cache.read('u1'), ['s-a', 'i-b']);
  });

  test('each user has their own list', () async {
    final cache = ForYouCache();
    await cache.write('u1', ['s-a']);
    expect(await cache.read('u2'), isEmpty);
  });

  test('nothing saved reads as empty', () async {
    expect(await ForYouCache().read('u1'), isEmpty);
  });
}
