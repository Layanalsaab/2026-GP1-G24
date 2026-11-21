import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/home_item.dart';
import '../firebase_services/auth_service.dart';

/// One item of the server's For You list.
class ForYouPick {
  const ForYouPick(this.id, this.kind, this.score);

  final String id;
  final HomeItemKind kind;
  final double score;

  /// The bookmark-style key: `s-<id>` for a startup, `i-<id>` for an investor.
  String get key => '${kind == HomeItemKind.startup ? 's' : 'i'}-$id';
}

/// What the app needs from the For You server (replaceable in tests).
abstract class ForYouSource {
  /// False when no server address is configured (the app makes no calls).
  bool get enabled;

  /// The server's ranked list, or null when it gave no answer.
  Future<List<ForYouPick>?> forYou();

  /// Asks the server to rebuild the profile text of one item; true on success.
  Future<bool> profileText(HomeItemKind kind, String id);
}

/// Background refresh after a profile edit.
extension ForYouProfileRefresh on ForYouSource {
  /// Asks the server to re-encode one profile. Fire and forget: nothing is
  /// awaited by the caller, and a failure is logged, never thrown.
  void refreshProfileText(HomeItemKind kind, String id) {
    unawaited(() async {
      try {
        if (!enabled) return;
        await profileText(kind, id);
      } catch (e) {
        debugPrint('profile-text refresh failed: $e');
      }
    }());
  }
}

/// Talks to the For You server over HTTP. Every failure is logged and treated
/// as "no answer"; nothing is ever shown to the user.
class ForYouApi implements ForYouSource {
  ForYouApi({
    http.Client? client,
    Future<String?> Function()? idToken,
    String? baseUrl,
    this.timeout = const Duration(seconds: 70),
  }) : _client = client ?? http.Client(),
       _idToken = idToken ?? (() => AuthService().idToken()),
       _baseUrl = _trimSlash(
         baseUrl ?? const String.fromEnvironment('FOR_YOU_API_URL'),
       );

  /// The app-wide instance.
  static ForYouSource instance = ForYouApi();

  final http.Client _client;
  final Future<String?> Function() _idToken;
  final String _baseUrl;

  /// How long to wait for the server (it can take about a minute to wake).
  final Duration timeout;

  static String _trimSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  @override
  bool get enabled => _baseUrl.isNotEmpty;

  @override
  Future<List<ForYouPick>?> forYou() async {
    try {
      final response = await _post('/for-you');
      if (response == null) return null;
      final items = (jsonDecode(response.body) as Map)['items'] as List;
      final picks = <ForYouPick>[];
      for (final item in items) {
        final kind = switch ((item as Map)['kind']) {
          'startup' => HomeItemKind.startup,
          'investor' => HomeItemKind.investor,
          _ => null,
        };
        if (kind == null) continue;
        picks.add(
          ForYouPick(
            item['id'] as String,
            kind,
            (item['score'] as num).toDouble(),
          ),
        );
      }
      return picks;
    } catch (e) {
      debugPrint('For You server: $e');
      return null;
    }
  }

  @override
  Future<bool> profileText(HomeItemKind kind, String id) async {
    if (kind == HomeItemKind.program) return false;
    try {
      final response = await _post(
        '/profile-text',
        body: jsonEncode({'kind': kind.name, 'id': id}),
      );
      return response != null;
    } catch (e) {
      debugPrint('For You server: $e');
      return false;
    }
  }

  /// POSTs to path; null when there is no address or token, or the answer is
  /// not a 200.
  Future<http.Response?> _post(String path, {String? body}) async {
    if (!enabled) return null;
    final token = await _idToken();
    if (token == null) return null;
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$path'),
          headers: {
            'Authorization': 'Bearer $token',
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      debugPrint('For You server $path: HTTP ${response.statusCode}');
      return null;
    }
    return response;
  }
}
