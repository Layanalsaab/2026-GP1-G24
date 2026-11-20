import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/startup_notice.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';

/// The notice inbox (docs: Closing a Startup, Leaving and Deleting an Account): users/{uid}/notices.
class NoticeRepository {
  NoticeRepository({AuthService? auth, FirestoreService? firestore})
    : _auth = auth ?? AuthService(),
      _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static NoticeRepository instance = NoticeRepository();

  final AuthService _auth;
  final FirestoreService _firestore;

  static String _collectionOf(String uid) =>
      '${FirestoreCollections.users}/$uid/${FirestoreCollections.notices}';

  String? get _uid {
    try {
      return _auth.currentAccount?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Sends notice to every person in to (not to me, not twice).
  Future<void> send(Iterable<String> to, StartupNotice notice) async {
    final me = _uid;
    if (me == null) return;
    for (final uid in {...to}) {
      if (uid.isEmpty || uid == me) continue;
      try {
        final col = _collectionOf(uid);
        await _firestore.setDocument(col, _firestore.newDocumentId(col), {
          ...notice.toMap(),
          'createdAt': _firestore.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Could not send the notice to $uid: $e');
      }
    }
  }

  /// My notices, oldest first.
  Future<List<StartupNotice>> mine() async {
    final me = _uid;
    if (me == null) return const [];
    final docs = await _firestore.listCollection(_collectionOf(me), limit: 50);
    final out = [
      for (final d in docs) ?StartupNotice.fromMap(d.id, d.data),
    ];
    out.sort(
      (a, b) => (a.createdAt ?? DateTime(2000)).compareTo(
        b.createdAt ?? DateTime(2000),
      ),
    );
    return out;
  }

  /// notice was shown: it goes.
  Future<void> dismiss(StartupNotice notice) async {
    final me = _uid;
    if (me == null || notice.id.isEmpty) return;
    try {
      await _firestore.deleteDocument(_collectionOf(me), notice.id);
    } catch (e) {
      debugPrint('Could not remove the notice: $e');
    }
  }

  /// Account deletion: my notices go with my account.
  Future<void> clearMine() async {
    try {
      for (final n in await mine()) {
        await dismiss(n);
      }
    } catch (_) {}
  }
}
