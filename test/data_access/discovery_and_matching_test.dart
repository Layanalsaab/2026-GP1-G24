import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/interaction_repository.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/recommendation_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/connection_request.dart';
import 'package:startsa/models/investor_criteria.dart';

void main() {
  group('sample data', () {
    test('has 30 startups and 30 investors for Trending', () {
      expect(PrototypeSeed.startups.length, 30);
      expect(PrototypeSeed.investors.length, 30);
      expect(
        InteractionRepository().trendingStartups(TrendingRange.week).length,
        30,
      );
    });

    test('the detailed startup has a team and market size', () {
      final r = PrototypeSeed.rafeeq;
      expect(r.team.length, 2);
      expect(r.tam, 2400000000);
      expect(r.wantsLeadInvestor, isTrue);
    });
  });

  group('discovery', () {
    final repo = DiscoveryRepository();

    test('a founder never sees their own startups', () {
      final ids = repo.startups(excludeIds: {'mock-rafeeq'}).map((e) => e.id);
      expect(ids.contains('mock-rafeeq'), isFalse);
      expect(ids.contains('mock-naql'), isTrue);
    });

    test('new on Start.sa carries the Joined lines', () {
      final firstNew = repo.newStartups().first;
      expect(firstNew.joinedLabel, 'Joined today');
      expect(repo.newInvestors().first.joinedLabel, 'Joined yesterday');
    });

    test('bookmark keys follow the s-/i-/p- rule', () {
      expect(repo.startups().first.bookmarkKey, 's-mock-rafeeq');
      expect(repo.investors().first.bookmarkKey, 'i-ahmad');
      expect(repo.programs().first.bookmarkKey, 'p-taqadam');
    });
  });

  group('requests', () {
    test('accepting a request makes the investor an associated investor', () {
      final requests = RequestRepository();
      RequestRepository.instance = requests;
      final discovery = DiscoveryRepository();
      expect(requests.pendingCount('mock-rafeeq'), 1);
      requests.setStatus('r1', RequestStatus.accepted);
      expect(requests.pendingCount('mock-rafeeq'), 0);
      expect(
        discovery.associatedInvestors('mock-rafeeq').map((i) => i.id),
        containsAll(['ahmad', 'omar']),
      );
      expect(
        requests.inboxFor('mock-rafeeq').first.offerLabel,
        'SAR 300,000 for 15%',
      );
    });

    test('sending twice withdraws', () {
      final requests = RequestRepository();
      expect(requests.toggleOutgoing('s-mock-naql'), isTrue);
      expect(requests.hasSent('s-mock-naql'), isTrue);
      expect(requests.toggleOutgoing('s-mock-naql'), isFalse);
    });
  });

  test('interests: replying marks them seen', () {
    final repo = InterestRepository();
    expect(repo.newCount('mock-rafeeq'), 2);
    repo.markSeen('i1');
    expect(repo.newCount('mock-rafeeq'), 1);
  });

  test('bookmarks toggle and clear', () {
    final repo = BookmarkRepository();
    expect(repo.toggle('s-x'), isTrue);
    expect(repo.count, 1);
    expect(repo.toggle('s-x'), isFalse);
    repo.toggle('i-y');
    repo.clear();
    expect(repo.count, 0);
  });

  group('matching', () {
    const investor = AppUser(
      uid: 'u',
      role: AccountRole.investor,
      fullName: 'Layan Alsaab',
      email: 'l@x.co',
      city: 'Riyadh',
      investorCriteria: InvestorCriteria(
        sectors: ['HealthTech'],
        stages: ['Pre-seed'],
        commerceModels: ['Business-to-Consumer (B2C)'],
      ),
    );

    test('sector, stage, model and region score the highest', () {
      final r = Recommender.investorToStartup(
        investor.investorCriteria!,
        PrototypeSeed.rafeeq,
        investorCity: 'Riyadh',
      )!;
      expect(r.percent, 99);
      expect(r.reason, 'Same sector, stage and region');
    });

    test('no sector or stage in common is no match', () {
      expect(
        Recommender.investorToStartup(
          investor.investorCriteria!,
          PrototypeSeed.naql,
        ),
        isNull,
      );
    });

    test('startups for an investor are best first', () {
      final list = RecommendationRepository().startupsForInvestor(investor);
      expect(list.first.name, 'Rafeeq Health');
      for (var i = 1; i < list.length; i++) {
        expect(list[i - 1].matchPercent! >= list[i].matchPercent!, isTrue);
      }
    });

    test('an investor without answers sees the sample matches', () {
      const blank = AppUser(
        uid: 'u2',
        role: AccountRole.investor,
        fullName: 'No Answers',
        email: 'n@x.co',
      );
      final list = RecommendationRepository().startupsForInvestor(blank);
      expect(list.map((e) => e.matchPercent), [94, 86, 71]);
    });

    test('investors for the sample startup show the sample percentages', () {
      final list = RecommendationRepository().investorsForStartup(
        PrototypeSeed.rafeeq,
      );
      expect(list.map((e) => e.matchPercent), [92, 81, 74]);
    });
  });
}
