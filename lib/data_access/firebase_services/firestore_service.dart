import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';

/// Cloud Firestore. The only code that talks to `FirebaseFirestore`.
class FirestoreService {
  /// Firestore never reports an error when the database doesn't exist or the
  /// phone is offline: it just waits. A timeout turns "waits forever" into a
  /// failure the app can handle.
  static const _timeout = Duration(seconds: 15);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// A value Firestore replaces with the server's time when writing.
  Object serverTimestamp() => FieldValue.serverTimestamp();

  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) =>
      _guard(() => _db.collection(collection).doc(id).set(data));

  /// Changes only the given fields of an existing document.
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) =>
      _guard(() => _db.collection(collection).doc(id).update(data));

  /// Returns the document's data, or null when it doesn't exist.
  Future<Map<String, dynamic>?> getDocument(String collection, String id) =>
      _guard(() async {
        final snapshot = await _db.collection(collection).doc(id).get();
        return snapshot.data();
      });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on TimeoutException {
      debugPrint(
        'Firestore did not answer within ${_timeout.inSeconds}s. Is the '
        'Firestore database created in the Firebase console, and is the '
        'device online?',
      );
      throw const AuthException(AuthFailure.network);
    } on FirebaseException catch (e) {
      debugPrint('Firestore error: ${e.code} ${e.message}');
      throw AuthException(
        e.code == 'unavailable' ? AuthFailure.network : AuthFailure.unknown,
      );
    }
  }
}
