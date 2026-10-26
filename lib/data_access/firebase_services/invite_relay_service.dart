import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/app_config.dart';
import '../../models/auth_failure.dart';

/// Asks the invitation e-mail relay (a Google Apps Script web app, see
/// tools/invite_relay) to send the e-mail of one invitation.
///
/// The relay checks the signed-in user's Firebase ID token and reads the
/// invitation itself, so the app only sends the invitation id: nobody can use
/// it to e-mail an arbitrary address with arbitrary text.
class InviteRelayService {
  const InviteRelayService({String? url})
    : _url = url ?? AppConfig.inviteRelayUrl;

  final String _url;

  static const _timeout = Duration(seconds: 25);

  /// dart:io only treats 303 as a redirect for a POST, but Apps Script answers
  /// a POST with a 302 to the page that holds the result.
  static const _redirects = [301, 302, 303, 307, 308];

  /// The last reason the relay gave for refusing (for the debug log).
  static String? lastError;

  /// True when the relay accepted the request and sent the e-mail.
  /// Throws an [AuthException] (network) when it can't be reached, and a
  /// [StateError] when the relay address isn't configured yet.
  Future<bool> send({
    required String idToken,
    required String invitationId,
  }) async {
    if (_url.isEmpty) {
      throw StateError('The invitation e-mail relay is not set up yet.');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final body = jsonEncode({
        'idToken': idToken,
        'invitationId': invitationId,
      });
      // Apps Script answers a POST with a redirect to the page that holds the
      // result, so the redirect is followed by hand (with GET).
      var request = await client.postUrl(Uri.parse(_url));
      request.followRedirects = false;
      request.headers.contentType = ContentType(
        'text',
        'plain',
        charset: 'utf-8',
      );
      final bytes = utf8.encode(body);
      request.contentLength = bytes.length;
      request.add(bytes);
      var response = await request.close().timeout(_timeout);
      var hops = 0;
      while (_redirects.contains(response.statusCode) && hops < 4) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null) break;
        request = await client.getUrl(Uri.parse(location));
        request.followRedirects = false;
        response = await request.close().timeout(_timeout);
        hops++;
      }
      final text = await response.transform(utf8.decoder).join();
      final json = jsonDecode(text);
      final ok = json is Map && json['ok'] == true;
      lastError = ok
          ? null
          : (json is Map ? '${json['error']}' : 'unexpected answer');
      if (!ok) debugPrint('Invitation relay refused: $lastError');
      return ok;
    } on TimeoutException {
      throw const AuthException(AuthFailure.network);
    } on SocketException {
      throw const AuthException(AuthFailure.network);
    } on FormatException {
      lastError = 'the relay did not answer with JSON (is it deployed as a web app open to Anyone?)';
      debugPrint('Invitation relay: $lastError');
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
