import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/features/startups/view_models/my_startups_view_model.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup.dart';

import '../../support/fakes.dart';

void main() {
  final withMembers = PrototypeSeed.rafeeq.copyWith(
    id: 'real-1',
    founderId: 'founder-uid',
    memberRoles: const {'co-uid': 'coFounder', 'member-uid': 'member'},
  );

  group('the memberships live inside the startup document', () {
    test('they are written as memberIds and memberRoles and read back', () {
      final map = withMembers.toMap();
      expect(map[StartupFields.memberIds], ['co-uid', 'member-uid']);
      expect(map[StartupFields.memberRoles], {
        'co-uid': 'coFounder',
        'member-uid': 'member',
      });
      final back = Startup.fromMap('real-1', {
        ...map,
        StartupFields.founderId: 'founder-uid',
      })!;
      expect(back.memberRoles, withMembers.memberRoles);
      expect(back.memberIds, ['co-uid', 'member-uid']);
    });

    test('an older startup without members reads as having none', () {
      final old = Startup.fromMap(
        'x',
        {...PrototypeSeed.rafeeq.toMap()}..remove(StartupFields.memberRoles),
      )!;
      expect(old.memberRoles, isEmpty);
    });

    test('editing a startup in the form keeps its members', () async {
      final repo = FakeStartupRepository()..startups.add(withMembers);
      final vm = StartupStepsViewModel(initial: withMembers, repository: repo);
      addTearDown(vm.dispose);
      final saved = await vm.save();
      expect(saved, isNotNull);
      expect(saved!.memberRoles, withMembers.memberRoles);
      expect(repo.startups.single.memberRoles, withMembers.memberRoles);
    });
  });

  group('My Startups and leaving', () {
    late FakeStartupRepository repo;
    setUp(() {
      repo = FakeStartupRepository();
      AppSession.instance = AppSession()
        ..signIn(
          const AppUser(
            uid: 'co-uid',
            role: AccountRole.founder,
            fullName: 'Co Founder',
            email: 'co@gmail.com',
          ),
        );
    });

    test(
      'a real membership shows with the role stored in the startup',
      () async {
        repo.memberOf.add(withMembers);
        final vm = MyStartupsViewModel(
          repository: repo,
          teamStartups: const [],
        );
        addTearDown(vm.dispose);
        await vm.load();
        final entry = vm.entries.single;
        expect(entry.role, StartupRole.coFounder);
        expect(entry.startup.id, 'real-1');
      },
    );

    test('Leave removes only the user from a real startup', () async {
      repo.memberOf.add(withMembers);
      final vm = MyStartupsViewModel(repository: repo, teamStartups: const []);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.leave('real-1');
      expect(repo.left, ['real-1']);
      expect(vm.entries, isEmpty);
    });

    test(
      'a sample startup is left locally, without touching the backend',
      () async {
        final vm = MyStartupsViewModel(repository: repo);
        addTearDown(vm.dispose);
        await vm.load();
        final sampleId = PrototypeSeed.sampleTeamStartups.first.startup.id;
        await vm.leave(sampleId);
        expect(repo.left, isEmpty);
        expect(vm.entries.any((e) => e.startup.id == sampleId), isFalse);
      },
    );
  });
}
