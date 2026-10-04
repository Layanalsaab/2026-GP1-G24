import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/startup.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../firebase_services/storage_service.dart';

/// Reads and writes the `startups` collection and the startups' logos in
/// Storage. Screens and view models never touch Firebase directly.
///
/// Every method throws [AuthException] on failure (network, permission, ...).
class StartupRepository {
  StartupRepository({
    AuthService? auth,
    FirestoreService? firestore,
    StorageService? storage,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _storage = storage ?? StorageService();

  /// The app-wide instance. Tests replace it with a fake.
  static StartupRepository instance = StartupRepository();

  final AuthService _auth;
  final FirestoreService _firestore;
  final StorageService _storage;

  static const _collection = FirestoreCollections.startups;

  /// The signed-in founder's uid, straight from FirebaseAuth.
  String get _founderId {
    final uid = _auth.currentAccount?.uid;
    if (uid == null) throw const AuthException(AuthFailure.permissionDenied);
    return uid;
  }

  /// The signed-in founder's startups, most recently edited first.
  Future<List<Startup>> fetchMyStartups() async {
    final docs = await _firestore.queryWhereEqual(
      _collection,
      StartupFields.founderId,
      _founderId,
    );
    final startups = [
      for (final doc in docs) ?Startup.fromMap(doc.id, doc.data),
    ];
    // Sorted here instead of with orderBy: a founder has a handful of
    // startups, and this avoids needing a composite Firestore index.
    startups.sort((a, b) => _editedAt(b).compareTo(_editedAt(a)));
    return startups;
  }

  /// Saves a new startup and returns it as stored. [startup.id] and
  /// [startup.founderId] are ignored: both are assigned here.
  Future<Startup> create(Startup startup, {File? logo}) async {
    final founderId = _founderId;
    final id = _firestore.newDocumentId(_collection);
    // Upload first: if it fails, nothing has been written yet.
    final logoUrl = logo == null
        ? null
        : await _uploadLogo(founderId, id, logo);
    final toSave = startup.copyWith(
      id: id,
      founderId: founderId,
      logoUrl: logoUrl,
    );
    try {
      await _firestore.setDocument(_collection, id, {
        ...toSave.toMap(),
        StartupFields.createdAt: _firestore.serverTimestamp(),
        StartupFields.updatedAt: _firestore.serverTimestamp(),
      });
    } catch (_) {
      // Don't leave an orphan logo behind when the document wasn't saved.
      if (logoUrl != null) await _deleteLogoQuietly(logoUrl);
      rethrow;
    }
    return toSave;
  }

  /// Saves changes to an existing startup.
  ///
  /// Pass [newLogo] to replace the logo, or [removeLogo] to clear it. The old
  /// logo file is deleted only after the document points at the new one.
  Future<Startup> update(
    Startup startup, {
    File? newLogo,
    bool removeLogo = false,
  }) async {
    final founderId = _founderId;
    final oldLogoUrl = startup.logoUrl;
    var updated = startup;
    if (newLogo != null) {
      updated = startup.copyWith(
        logoUrl: await _uploadLogo(founderId, startup.id, newLogo),
      );
    } else if (removeLogo) {
      updated = startup.copyWith(clearLogo: true);
    }

    await _firestore.updateDocument(_collection, startup.id, {
      ...updated.toMap(),
      StartupFields.updatedAt: _firestore.serverTimestamp(),
    });

    final logoChanged = oldLogoUrl != null && oldLogoUrl != updated.logoUrl;
    if (logoChanged) await _deleteLogoQuietly(oldLogoUrl);
    return updated;
  }

  /// Deletes the startup and its logo.
  Future<void> delete(Startup startup) async {
    final logoUrl = startup.logoUrl;
    // Logo first: if that fails we stop, and the startup is still intact for
    // the founder to retry. (A missing logo file counts as deleted.)
    if (logoUrl != null) await _storage.deleteByUrl(logoUrl);
    await _firestore.deleteDocument(_collection, startup.id);
  }

  Future<String> _uploadLogo(String founderId, String startupId, File logo) {
    // A new file name per upload, so cached images never show an old logo.
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _storage.uploadFile(
      path: StoragePaths.startupLogo(founderId, startupId, fileName),
      file: logo,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _deleteLogoQuietly(String url) async {
    try {
      await _storage.deleteByUrl(url);
    } catch (e) {
      // Cleanup only: the startup itself was saved correctly.
      debugPrint('Could not delete old logo: $e');
    }
  }

  /// A just-saved document may have no server timestamp yet; treat it as new.
  DateTime _editedAt(Startup s) => s.updatedAt ?? s.createdAt ?? DateTime.now();
}
