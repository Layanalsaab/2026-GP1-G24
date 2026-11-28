import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/repositories/invitation_repository.dart';
import 'package:startsa/data_access/repositories/notice_repository.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/models/invitation.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/models/team_member.dart';

import '../support/fakes.dart';
import '../support/recording_firestore.dart';

void main() {
  late RecordingFirestore db;
  late InvitationRepository repo;

  Startup startup(List<TeamMember> extra) => Startup(
    id: 's1',
    founderId: 'f1',
    name: 'Rafeeq',
    description: 'd',
    sector: Sector.fintech,
    stage: StartupStage.seed,
    commerceModel: CommerceModel.b2b,
    location: StartupLocation.riyadh,
    lookingFor: const {LookingFor.talent},
    team: [
      const TeamMember(
        name: 'Fahad',
        role: 'CEO',
        contribution: 'Leads',
        isFounder: true,
        uid: 'f1',
      ),
      ...extra,
    ],
  );

  const invitation = Invitation(
    startupId: 's1',
    startupName: 'Rafeeq',
    emailLower: 'layan@gmail.com',
    role: Invitation.roleOwner,
    invitedBy: 'f1',
    invitedByName: 'Fahad',
  );

  void setUpWith(Startup s) {
    db = RecordingFirestore();
    final auth = FakeAuthService();
    db.as('l1', 'layan@gmail.com');
    auth.signedIn = const AuthAccount(
      uid: 'l1',
      email: 'layan@gmail.com',
      emailVerified: true,
    );
    repo = InvitationRepository(auth: auth, firestore: db);
    NoticeRepository.instance = NoticeRepository(auth: auth, firestore: db);
    PublicProfileRepository.instance = PublicProfileRepository(firestore: db);
    db.store['startups'] = {
      's1': jsonDecode(jsonEncode(s.toMap())) as Map<String, Object?>,
    };
    db.store['invitations'] = {
      invitation.id: {...invitation.toCreateMap(), 'status': 'pending'},
    };
  }

  test(
    'a team member who takes over keeps his role and contribution',
    () async {
      setUpWith(
        startup([
          const TeamMember(
            name: 'Layan',
            email: 'layan@gmail.com',
            role: 'CTO',
            contribution: 'Builds the app',
            uid: 'l1',
          ),
        ]),
      );
      final me = await repo.accept(invitation, fullName: 'Layan');
      expect(me?.role, 'CTO');
      expect(me?.contribution, 'Builds the app');
      final team = Startup.fromMap('s1', db.store['startups']!['s1'])!.team;
      final founder = team.firstWhere((m) => m.isFounder);
      expect(founder.uid, 'l1');
      expect(founder.role, 'CTO');
      expect(team.where((m) => m.email == 'layan@gmail.com'), hasLength(1));
    },
  );

  test('a newcomer who takes over starts with an empty role', () async {
    setUpWith(startup(const []));
    final me = await repo.accept(invitation, fullName: 'Layan');
    expect(me?.isFounder, isTrue);
    expect(me?.role, '');
    expect(me?.contribution, '');
  });
}
