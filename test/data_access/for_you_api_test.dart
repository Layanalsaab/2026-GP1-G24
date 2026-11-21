import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:startsa/data_access/remote/for_you_api.dart';
import 'package:startsa/models/home_item.dart';

ForYouApi _api(
  http.Client client, {
  String? base = 'https://x.test',
  Future<String?> Function()? token,
  Duration timeout = const Duration(seconds: 5),
}) => ForYouApi(
  client: client,
  idToken: token ?? () async => 'tok',
  baseUrl: base,
  timeout: timeout,
);

MockClient _failIfCalled() =>
    MockClient((_) async => fail('no request expected'));

void main() {
  test('forYou returns the picks in order and sends the login token', () async {
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({
          'items': [
            {'id': 'a', 'kind': 'startup', 'score': 0.9},
            {'id': 'b', 'kind': 'investor', 'score': 0.5},
          ],
          'generatedAt': '2026-11-22T00:00:00Z',
        }),
        200,
      );
    });
    final picks = await _api(client).forYou();
    expect(picks!.map((p) => (p.id, p.kind, p.score)).toList(), [
      ('a', HomeItemKind.startup, 0.9),
      ('b', HomeItemKind.investor, 0.5),
    ]);
    expect(picks.map((p) => p.key).toList(), ['s-a', 'i-b']);
    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://x.test/for-you');
    expect(seen.headers['Authorization'], 'Bearer tok');
  });

  test('forYou returns null on 401, 500, bad JSON and timeouts', () async {
    for (final client in [
      MockClient((_) async => http.Response('no', 401)),
      MockClient((_) async => http.Response('no', 500)),
      MockClient((_) async => http.Response('not json', 200)),
      MockClient((_) => Completer<http.Response>().future),
    ]) {
      final api = _api(client, timeout: const Duration(milliseconds: 50));
      expect(await api.forYou(), isNull);
    }
  });

  test('no token or no address means no request', () async {
    final noToken = _api(_failIfCalled(), token: () async => null);
    expect(await noToken.forYou(), isNull);
    expect(await noToken.profileText(HomeItemKind.startup, 's1'), isFalse);

    final noAddress = _api(_failIfCalled(), base: '');
    expect(noAddress.enabled, isFalse);
    expect(await noAddress.forYou(), isNull);
    expect(await noAddress.profileText(HomeItemKind.startup, 's1'), isFalse);
    expect(_api(_failIfCalled()).enabled, isTrue);
  });

  test('items with an unknown kind are skipped', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'items': [
            {'id': 'p', 'kind': 'program', 'score': 1.0},
            {'id': 'a', 'kind': 'startup', 'score': 0.4},
          ],
        }),
        200,
      ),
    );
    final picks = await _api(client).forYou();
    expect(picks!.map((p) => p.id).toList(), ['a']);
  });

  test('profileText posts kind and id and reports success', () async {
    late http.Request seen;
    final ok = MockClient((req) async {
      seen = req;
      return http.Response('{"updated": true}', 200);
    });
    expect(await _api(ok).profileText(HomeItemKind.startup, 's1'), isTrue);
    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://x.test/profile-text');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(seen.body), {'kind': 'startup', 'id': 's1'});

    final denied = MockClient((_) async => http.Response('no', 403));
    expect(await _api(denied).profileText(HomeItemKind.startup, 's1'), isFalse);
  });

  test('profileText for a program sends nothing', () async {
    expect(
      await _api(_failIfCalled()).profileText(HomeItemKind.program, 'p'),
      isFalse,
    );
  });
}
