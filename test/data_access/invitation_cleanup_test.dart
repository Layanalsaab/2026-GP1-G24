import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/invitation_repository.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

import '../support/fakes.dart';
import '../support/recording_firestore.dart';

void main() {
  late RecordingFirestore db;
  late FakeAuthService auth;
  late InvitationRepository repo;

  const startup = Startup(
    id: 's1',
    founderId: 'f1',
    name: 'Rafeeq',
    description: 'd',
    sector: Sector.fintech,
    stage: StartupStage.seed,
    commerceModel: CommerceModel.b2b,
    location: StartupLocation.riyadh,
    lookingFor: {LookingFor.talent},
    team: [
      TeamMember(
        name: 'Fahad',
        role: 'CEO',
        contribution: 'Leads',
        isFounder: true,
        uid: 'f1',
      ),
      TeamMember(
        name: 'Layan',
        email: 'layan@gmail.com',
        role: 'CTO',
        contribution: 'Builds',
        uid: 'l1',
      ),
    ],
  );

  Map<String, Object?> invitation(
    String startupId,
    String email,
    String status,
  ) => {
    'startupId': startupId,
    'startupName': 'Rafeeq',
    'emailLower': email,
    'role': 'member',
    'invitedBy': 'f1',
    'invitedByName': 'Fahad',
    'status': status,
  };

  void who(String uid, String email, {bool verified = true}) {
    db.as(uid, email);
    auth.signedIn = AuthAccount(
      uid: uid,
      email: email,
      emailVerified: verified,
    );
  }

  setUp(() {
    db = RecordingFirestore();
    auth = FakeAuthService();
    repo = InvitationRepository(auth: auth, firestore: db);
    db.store['invitations'] = {
      's1~layan@gmail.com': invitation('s1', 'layan@gmail.com', 'accepted'),
      's1~sara@gmail.com': invitation('s1', 'sara@gmail.com', 'declined'),
      's2~layan@gmail.com': invitation('s2', 'layan@gmail.com', 'accepted'),
    };
    db.store['inviteEmails'] = {
      'layan@gmail.com': {'names': <String>[]},
    };
  });

  test(
    'deleting a startup deletes all its invitations, accepted too',
    () async {
      who('f1', 'f1@gmail.com');
      await repo.deleteAllFor(startup);
      expect(db.store['invitations']!.keys, ['s2~layan@gmail.com']);
    },
  );

  test('deleting an account deletes every invitation to its email', () async {
    who('l1', 'layan@gmail.com');
    await repo.deleteAllForMe();
    expect(db.store['invitations']!.keys, ['s1~sara@gmail.com']);
    expect(db.store['inviteEmails']!.containsKey('layan@gmail.com'), isFalse);
  });

  test('an unverified email only removes its invite index entry', () async {
    who('l1', 'layan@gmail.com', verified: false);
    await repo.deleteAllForMe();
    expect(db.store['invitations']!.length, 3);
    expect(db.store['inviteEmails']!.containsKey('layan@gmail.com'), isFalse);
  });
}
