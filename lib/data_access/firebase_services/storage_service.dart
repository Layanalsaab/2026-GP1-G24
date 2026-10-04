import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';

/// Firebase Storage. The only code that talks to `FirebaseStorage`.
/// Every Firebase error is translated into an [AuthException].
class StorageService {
  /// Uploads are larger than Firestore writes, so they get more time.
  static const _timeout = Duration(seconds: 60);

  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads [file] to [path] and returns its public download URL.
  Future<String> uploadFile({
    required String path,
    required File file,
    required String contentType,
  }) => _guard(() async {
    final ref = _storage.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  });

  /// Deletes the file behind a download URL. A file that is already gone
  /// counts as deleted.
  Future<void> deleteByUrl(String downloadUrl) => _guard(() async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on TimeoutException {
      throw const AuthException(AuthFailure.network);
    } on FirebaseException catch (e) {
      debugPrint('Storage error: ${e.code} ${e.message}');
      throw AuthException(switch (e.code) {
        'retry-limit-exceeded' || 'unavailable' => AuthFailure.network,
        'unauthorized' || 'unauthenticated' => AuthFailure.permissionDenied,
        'object-not-found' => AuthFailure.notFound,
        _ => AuthFailure.unknown,
      });
    } on ArgumentError {
      // refFromURL rejects URLs that aren't Firebase Storage URLs.
      throw const AuthException(AuthFailure.notFound);
    }
  }
}
