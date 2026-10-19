import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/models/auth_failure.dart';

/// A Firestore stand-in that behaves like the OLD security rules: it rejects
/// any user document holding a field outside the original list.
class _OldRulesFirestore extends FirestoreService {
  _OldRulesFirestore();

  final writes = <String, Map<String, Object?>>{};
  int attempts = 0;

  static const _allowedOnCreate = {'role', 'fullName', 'email', 'createdAt'};
  static const _allowedOnUpdate = {'fullName', 'bio', 'city'};

  @override
  Object serverTimestamp() => 'now';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    attempts++;
    if (!_allowedOnCreate.containsAll(data.keys)) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    writes[id] = data;
  }

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    attempts++;
    if (!_allowedUpdateKeys(data)) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    writes[id] = {...?writes[id], ...data};
  }

  bool _allowedUpdateKeys(Map<String, Object?> data) =>
      _allowedOnUpdate.containsAll(data.keys);
}

void main() {
  test(
    'Edit profile keeps name, bio and city when the rules are old',
    () async {
      final firestore = _OldRulesFirestore();
      final repo = UserRepository(firestore: firestore);

      await repo.updateProfile(
        uid: 'u1',
        fullName: 'Sara A',
        bio: 'New bio',
        phone: '551234567',
        sectorsOfInterest: const ['Fintech'],
        city: 'Jeddah',
      );

      expect(firestore.writes['u1'], {
        'fullName': 'Sara A',
        'bio': 'New bio',
        'city': 'Jeddah',
      });
    },
  );
}
