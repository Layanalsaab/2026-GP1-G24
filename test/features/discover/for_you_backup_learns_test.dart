import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/for_you_cache.dart';
import 'package:startsa/data_access/repositories/not_interested_repository.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/investor_profile.dart';
import 'package:startsa/models/startup.dart';

import '../../support/recording_firestore.dart';

/// When the server has not answered yet (here: no server address), For You
/// uses the app's own ranking. That ranking must learn from "Not interested"
/// too, so every list the user sees adapts to their taste.
Startup _startup(
  String id,
  String name,
  String sector, {
  List<String> otherSectors = const [],
}) => Startup.fromMap(id, {
  'name': name,
  'sector': sector,
  'otherSectors': otherSectors,
  'stage': 'seed',
  'commerceModel': 'b2c',
  'location': 'riyadh',
  'founderId': 'f-$id',
  'isPublic': true,
})!;

InvestorProfile _investor(String id, String name, List<String> sectors) =>
    InvestorProfile(
      id: id,
      name: name,
      title: '',
      city: 'Riyadh',
      sectors: sectors,
      stages: const ['Seed'],
      ticketRange: '',
      locations: const [],
    );

void main() {
  late NotInterestedRepository hidden;

  setUp(() {
    AppSession.instance.reset();
    final db = RecordingFirestore();
    BookmarkRepository.instance = BookmarkRepository(firestore: db);
    hidden = NotInterestedRepository(firestore: db);
  });

  tearDown(() => AppSession.instance.reset());

  List<String> ids(HomeViewModel vm) => [for (final i in vm.recommended) i.id];

  test(
    'an investor: a startup like the hidden one drops below others',
    () async {
      final vm = HomeViewModel(
        role: SessionRole.investor,
        user: const AppUser(
          uid: 'u1',
          role: AccountRole.investor,
          fullName: 'Test Investor',
          email: 'u1@x.co',
          investorCriteria: InvestorCriteria(
            sectors: ['Fintech', 'HealthTech'],
            stages: ['Seed'],
          ),
        ),
        discovery: DiscoveryRepository.sample(
          startups: [
            _startup('f1', 'Fin One', 'fintech'),
            _startup('f2', 'Fin Two', 'fintech'),
            _startup('h1', 'Health One', 'healthtech'),
          ],
        ),
        forYouCache: ForYouCache(),
        notInterested: hidden,
        forYouQuietTime: Duration.zero,
      );
      addTearDown(vm.dispose);
      expect(ids(vm), ['f1', 'f2', 'h1']);

      await hidden.add('s-f1');
      vm.refreshForYou();
      expect(ids(vm).take(2), ['h1', 'f2']);
    },
  );

  test(
    'a founder: an investor like the hidden one drops below others',
    () async {
      final vm = HomeViewModel(
        role: SessionRole.founder,
        user: const AppUser(
          uid: 'u2',
          role: AccountRole.founder,
          fullName: 'Test Founder',
          email: 'u2@x.co',
        ),
        ownStartups: [
          _startup(
            'mine',
            'My Startup',
            'fintech',
            otherSectors: ['HealthTech'],
          ),
        ],
        discovery: DiscoveryRepository.sample(
          startups: const [],
          investors: [
            _investor('a1', 'Fin Angel One', ['Fintech']),
            _investor('a2', 'Fin Angel Two', ['Fintech']),
            _investor('h1', 'Health Angel', ['HealthTech']),
          ],
        ),
        forYouCache: ForYouCache(),
        notInterested: hidden,
        forYouQuietTime: Duration.zero,
      );
      addTearDown(vm.dispose);
      expect(ids(vm), ['a1', 'a2', 'h1']);

      await hidden.add('i-a1');
      vm.refreshForYou();
      expect(ids(vm).take(2), ['h1', 'a2']);
    },
  );
}
