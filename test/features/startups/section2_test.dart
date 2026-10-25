import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/profiles/view_models/account_view_model.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/features/startups/widgets/startup_ask.dart';

import '../../support/fakes.dart';

const _me = AppUser(
  uid: 'u9',
  role: AccountRole.founder,
  fullName: 'Layla Alharbi',
  email: 'layla@gmail.com',
);

void main() {
  late FakeStartupRepository repo;
  late AppSession session;

  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    session = AppSession();
    AppSession.instance = session;
    session.signIn(_me);
  });

  group('Part 7: roles', () {
    test('saving an edited section re-checks my role first', () async {
      // I was a co-founder when the editor opened...
      final s = PrototypeSeed.rafeeq.copyWith(
        id: 'x1',
        memberRoles: {'u9': 'coFounder'},
      );
      repo.startups.add(s);
      repo.memberOf.add(s);
      final vm = StartupStepsViewModel(initial: s);
      addTearDown(vm.dispose);
      // ...and was turned into a team member before pressing Save.
      repo.memberOf
        ..clear()
        ..add(s.copyWith(memberRoles: {'u9': 'member'}));
      repo.startups
        ..clear()
        ..add(s.copyWith(memberRoles: {'u9': 'member'}));
      expect(await vm.save(), isNull);
      expect(vm.lostPermission, isTrue);
      expect(
        vm.saveError,
        'You don’t have permission to edit this startup anymore.',
      );
    });

    test('a co-founder can still save', () async {
      final s = PrototypeSeed.rafeeq.copyWith(
        id: 'x2',
        memberRoles: {'u9': 'coFounder'},
      );
      repo.startups.add(s);
      final vm = StartupStepsViewModel(initial: s);
      addTearDown(vm.dispose);
      vm.name.text = 'Rafeeq Care';
      expect(await vm.save(), isNotNull);
    });

    test('session keeps my role in each startup I belong to', () {
      session.setMemberRoles({'a': StartupRole.coFounder});
      session.setMemberStartupIds(['a']);
      expect(session.memberRoleOf('a'), StartupRole.coFounder);
      expect(session.memberRoleOf('b'), isNull);
      session.signOut();
      expect(session.memberRoleOf('a'), isNull);
    });

    test('Leave from the profile removes the membership', () async {
      final naql = PrototypeSeed.naql;
      final real = naql.copyWith(id: 'real1', memberRoles: {'u9': 'coFounder'});
      repo.memberOf.add(real);
      final vm = AccountViewModel(
        user: _me,
        userRepository: FakeUserRepository(),
        startupRepository: repo,
        session: session,
      );
      await vm.reload();
      expect(vm.startupEntries.any((e) => e.startup.id == 'real1'), isTrue);
      await vm.leave('real1');
      expect(vm.startupEntries.any((e) => e.startup.id == 'real1'), isFalse);
      expect(repo.left, contains('real1'));
    });
  });

  group('Parts 8 and 10: the new answers', () {
    final s = PrototypeSeed.rafeeq.copyWith(
      fundingRequirement: 500000,
      raisedInRound: 200000,
      wantsLeadInvestor: true,
      partnerTypes: ['Technology', 'Distribution'],
      supportTypes: ['Mentorship'],
    );

    test('funding line and partner / support rows', () {
      expect(
        StartupAsk.fundingDetail(s),
        'Raising SAR 500,000 · SAR 200,000 raised so far · Looking for a lead investor',
      );
      expect(StartupAsk.partners(s), ['Technology', 'Distribution']);
      expect(StartupAsk.support(s), ['Mentorship']);
      expect(StartupAsk.partnership(s), isTrue);
      expect(StartupAsk.supportSelected(s), isTrue);
      expect(
        StartupAsk.fundingDetail(s.copyWith(wantsLeadInvestor: false)),
        endsWith('No lead investor needed'),
      );
    });
  });
}
