import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/auth_failure.dart';

/// One document read from Firestore: its id and its (plain Dart) data.
typedef FirestoreDocument = ({String id, Map<String, dynamic> data});

/// Cloud Firestore. The only code that talks to `FirebaseFirestore`.
class FirestoreService {
  /// Firestore never reports an error when the database doesn't exist or the
  /// phone is offline: it just waits. A timeout turns "waits forever" into a
  /// failure the app can handle.
  static const _timeout = Duration(seconds: 15);

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// A value Firestore replaces with the server's time when writing.
  Object serverTimestamp() => FieldValue.serverTimestamp();

  /// A new, unused document id. Generated on the device (no network call), so
  /// files can be uploaded under the id before the document is written.
  String newDocumentId(String collection) =>
      _db.collection(collection).doc().id;

  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) => _guard(() => _db.collection(collection).doc(id).set(data));

  /// Changes only the given fields of an existing document.
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) => _guard(() => _db.collection(collection).doc(id).update(data));

  Future<void> deleteDocument(String collection, String id) =>
      _guard(() => _db.collection(collection).doc(id).delete());

  /// Deletes the document. Deleting a document that doesn't exist is not an error.
  Future<void> deleteDocument(String collection, String id) =>
      _guard(() => _db.collection(collection).doc(id).delete());

  /// Returns the document's data, or null when it doesn't exist.
  Future<Map<String, dynamic>?> getDocument(String collection, String id) =>
      _guard(() async {
        final snapshot = await _db.collection(collection).doc(id).get();
        final data = snapshot.data();
        return data == null ? null : _toPlain(data);
      });

  /// Every document in [collection] whose [field] equals [value].
  /// Reads from the server, so pull-to-refresh always shows fresh data.
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value,
  ) => _guard(() async {
    final snapshot = await _db
        .collection(collection)
        .where(field, isEqualTo: value)
        .get(const GetOptions(source: Source.server));
    return [
      for (final doc in snapshot.docs) (id: doc.id, data: _toPlain(doc.data())),
    ];
  });

  /// Replaces Firestore [Timestamp]s with [DateTime]s, so models never import
  /// Firebase.
  Map<String, dynamic> _toPlain(Map<String, dynamic> data) => {
    for (final entry in data.entries)
      entry.key: entry.value is Timestamp
          ? (entry.value as Timestamp).toDate()
          : entry.value,
  };

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
      throw AuthException(switch (e.code) {
        'unavailable' => AuthFailure.network,
        'permission-denied' ||
        'unauthenticated' => AuthFailure.permissionDenied,
        'not-found' => AuthFailure.notFound,
        _ => AuthFailure.unknown,
      });
    }
  }
}
