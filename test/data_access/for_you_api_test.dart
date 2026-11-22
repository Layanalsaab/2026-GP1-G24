import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  test('profileTextDone counts every finished call, success or failure; '
      'none when there is no address', () async {
    final ok = _api(
      MockClient((_) async => http.Response('{"updated": true}', 200)),
    );
    expect(ok.profileTextDone.value, 0);
    expect(await ok.profileText(HomeItemKind.startup, 's1'), isTrue);
    expect(ok.profileTextDone.value, 1);
    await ok.profileText(HomeItemKind.investor, 'u1');
    expect(ok.profileTextDone.value, 2);

    for (final client in [
      MockClient((_) async => http.Response('no', 500)),
      MockClient((_) async => throw http.ClientException('down')),
      MockClient((_) => Completer<http.Response>().future),
    ]) {
      final failed = _api(client, timeout: const Duration(milliseconds: 50));
      expect(await failed.profileText(HomeItemKind.startup, 's1'), isFalse);
      expect(failed.profileTextDone.value, 1);
    }

    final off = _api(_failIfCalled(), base: '');
    expect(await off.profileText(HomeItemKind.startup, 's1'), isFalse);
    expect(off.profileTextDone.value, 0);
  });

  test('profileText for a program sends nothing', () async {
    expect(
      await _api(_failIfCalled()).profileText(HomeItemKind.program, 'p'),
      isFalse,
    );
  });

  group('refreshProfileText', () {
    test('a synchronous or asynchronous throw never escapes', () async {
      await runZonedGuarded(() async {
        _Fake(sync: true).refreshProfileText(HomeItemKind.startup, 's');
        _Fake(sync: false).refreshProfileText(HomeItemKind.startup, 's');
        await Future<void>.delayed(Duration.zero);
      }, (e, _) => fail('unhandled: $e'));
    });

    test('disabled makes no call', () async {
      final f = _Fake(enabled: false);
      f.refreshProfileText(HomeItemKind.investor, 'u');
      await Future<void>.delayed(Duration.zero);
      expect(f.calls, 0);
    });

    test('enabled makes one call', () async {
      final f = _Fake();
      f.refreshProfileText(HomeItemKind.investor, 'u');
      await Future<void>.delayed(Duration.zero);
      expect(f.calls, 1);
    });
  });
}

class _Fake implements ForYouSource {
  _Fake({this.enabled = true, this.sync});
  @override
  final bool enabled;
  final bool? sync;
  int calls = 0;

  @override
  Future<List<ForYouPick>?> forYou() async => null;

  @override
  Future<bool> profileText(HomeItemKind kind, String id) {
    calls++;
    if (sync == true) throw StateError('boom');
    if (sync == false) return Future.error(StateError('boom'));
    return Future.value(true);
  }

  @override
  final ValueListenable<int> profileTextDone = ValueNotifier<int>(0);
}
