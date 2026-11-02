import 'package:startsa/data_access/firebase_services/firestore_service.dart';

/// An in-memory Firestore that ALSO records every write the app makes, with
/// who made it. The recording is replayed against the real security rules
/// (tools/rules_tests/parity.test.mjs) to prove the app and the rules agree.
///
/// Special values are recorded as markers so they survive JSON:
/// `{"\$ts":1}` server time, `{"\$del":1}` delete field,
/// `{"\$union":[..]}` / `{"\$remove":[..]}` array changes.
class RecordingFirestore extends FirestoreService {
  /// Who is signed in: used to label each recorded write.
  String actorUid = 'u1';
  String actorEmail = 'u1@gmail.com';
  bool actorVerified = true;

  /// Name of the scenario the next writes belong to.
  String scenario = 'none';

  final Map<String, Map<String, Map<String, Object?>>> store = {};
  final List<Map<String, Object?>> log = [];
  int _ids = 0;

  void as(String uid, String email) {
    actorUid = uid;
    actorEmail = email;
  }

  @override
  Object serverTimestamp() => const _Marker('\$ts');

  @override
  Object deleteField() => const _Marker('\$del');

  @override
  Object arrayUnion(List<Object> values) => _Marker('\$union', values);

  @override
  Object arrayRemove(List<Object> values) => _Marker('\$remove', values);

  @override
  String newDocumentId(String collection) => 'gen${++_ids}';

  void _record(
    String op,
    String collection,
    String id,
    Map<String, Object?>? data, {
    bool merge = false,
    int? batch,
  }) {
    log.add({
      'scenario': scenario,
      'uid': actorUid,
      'email': actorEmail,
      'verified': actorVerified,
      'op': op,
      'collection': collection,
      'id': id,
      if (merge) 'merge': true,
      'batch': ?batch,
      'data': ?(data == null ? null : _encode(data)),
    });
  }

  static Object? _encode(Object? v) {
    if (v is _Marker) return v.toJson();
    if (v is Map) return {for (final e in v.entries) '${e.key}': _encode(e.value)};
    if (v is Iterable) return [for (final e in v) _encode(e)];
    if (v is DateTime) return {'\$date': v.toIso8601String()};
    return v;
  }

  // ---- applying a write to the in-memory copy ----

  Object? _plain(Object? v) {
    if (v is _Marker) return v.name == '\$ts' ? DateTime.utc(2026, 1, 1) : null;
    if (v is Map) return {for (final e in v.entries) e.key: _plain(e.value)};
    if (v is List) return [for (final e in v) _plain(e)];
    return v;
  }

  void _apply(Map<String, Object?> doc, String key, Object? value) {
    final parts = key.split('.');
    var cur = doc;
    for (var i = 0; i < parts.length - 1; i++) {
      final next = cur[parts[i]];
      if (next is Map<String, Object?>) {
        cur = next;
      } else {
        final fresh = <String, Object?>{};
        cur[parts[i]] = fresh;
        cur = fresh;
      }
    }
    final last = parts.last;
    if (value is _Marker) {
      switch (value.name) {
        case '\$del':
          cur.remove(last);
        case '\$ts':
          cur[last] = DateTime.utc(2026, 1, 1);
        case '\$union':
          final list = [...?(cur[last] as List?)];
          for (final v in value.values) {
            if (!list.contains(v)) list.add(v);
          }
          cur[last] = list;
        case '\$remove':
          final list = [...?(cur[last] as List?)]
            ..removeWhere(value.values.contains);
          cur[last] = list;
      }
    } else {
      cur[last] = _plain(value);
    }
  }

  void _set(String c, String id, Map<String, Object?> data, bool merge) {
    final coll = store[c] ??= {};
    final doc = merge ? (coll[id] ??= {}) : <String, Object?>{};
    for (final e in data.entries) {
      _apply(doc, e.key, e.value);
    }
    coll[id] = doc;
  }

  void _update(String c, String id, Map<String, Object?> data) {
    final doc = (store[c] ??= {})[id] ??= {};
    for (final e in data.entries) {
      _apply(doc, e.key, e.value);
    }
  }

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async {
    _record('set', collection, id, data, merge: merge);
    _set(collection, id, data, merge);
  }

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    _record('update', collection, id, data);
    _update(collection, id, data);
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    _record('delete', collection, id, null);
    store[collection]?.remove(id);
  }

  int _batches = 0;

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    final batch = ++_batches;
    for (final w in writes) {
      switch (w.kind) {
        case FirestoreWriteKind.set:
          _record('set', w.collection, w.id, w.data, batch: batch);
          _set(w.collection, w.id, w.data, false);
        case FirestoreWriteKind.update:
          _record('update', w.collection, w.id, w.data, batch: batch);
          _update(w.collection, w.id, w.data);
        case FirestoreWriteKind.delete:
          _record('delete', w.collection, w.id, null, batch: batch);
          store[w.collection]?.remove(w.id);
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    final d = store[collection]?[id];
    return d == null ? null : _copy(d) as Map<String, dynamic>;
  }

  static Object? _copy(Object? v) {
    if (v is Map) return {for (final e in v.entries) '${e.key}': _copy(e.value)};
    if (v is List) return [for (final e in v) _copy(e)];
    return v;
  }

  @override
  Future<List<FirestoreDocument>> listCollection(
    String collection, {
    int limit = 100,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      (id: e.key, data: _copy(e.value) as Map<String, dynamic>),
  ];

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      if (e.value[field] == value)
        (id: e.key, data: _copy(e.value) as Map<String, dynamic>),
  ];

  @override
  Future<List<FirestoreDocument>> queryWhereAll(
    String collection,
    Map<String, Object> where,
  ) async => [
    for (final e in (store[collection] ?? {}).entries)
      if (where.entries.every((w) => e.value[w.key] == w.value))
        (id: e.key, data: _copy(e.value) as Map<String, dynamic>),
  ];

  @override
  Future<List<FirestoreDocument>> queryWhereArrayContains(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      if ((e.value[field] is List) && (e.value[field] as List).contains(value))
        (id: e.key, data: _copy(e.value) as Map<String, dynamic>),
  ];
}

class _Marker {
  const _Marker(this.name, [this.values = const []]);
  final String name;
  final List<Object> values;
  Map<String, Object?> toJson() => {
    name: values.isEmpty ? 1 : RecordingFirestore._encode(values),
  };
}
