import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/interaction_repository.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/models/connection_request.dart';
import 'package:startsa/models/investor_profile.dart';

void main() {
  setUp(() {
    DiscoveryRepository.instance = DiscoveryRepository.sample();
  });

  group('sample data', () {
    test('has 30 startups and 30 investors for Trending', () {
      expect(PrototypeSeed.startups.length, 30);
      expect(PrototypeSeed.investors.length, 30);
      // A private startup (Daftar in the sample) is never trending.
      expect(
        InteractionRepository().trendingStartups(TrendingRange.week).length,
        29,
      );
    });

    test('the detailed startup has a team and market size', () {
      final r = PrototypeSeed.rafeeq;
      expect(r.team.length, 2);
      expect(r.marketSize, 2400000000);
    });
  });

  group('discovery', () {
    final repo = DiscoveryRepository.sample();

    test('a founder never sees their own startups', () {
      final ids = repo.startups(excludeIds: {'mock-rafeeq'}).map((e) => e.id);
      expect(ids.contains('mock-rafeeq'), isFalse);
      expect(ids.contains('mock-naql'), isTrue);
    });

    test('new on Start.sa carries the Joined lines', () {
      expect(repo.newInvestors().first.joinedLabel, 'Joined yesterday');
    });

    test('bookmark keys follow the s-/i-/p- rule', () {
      expect(repo.startups().first.bookmarkKey, 's-mock-rafeeq');
      expect(repo.investors().first.bookmarkKey, 'i-ahmad');
      // There are no support channels yet.
      expect(repo.programs(), isEmpty);
    });
  });

  group('requests', () {
    test('accepting a request makes the investor an associated investor', () {
      final requests = RequestRepository(sample: true);
      RequestRepository.instance = requests;
      final discovery = DiscoveryRepository.sample();
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
  });

  test('interests: replying marks them seen', () {
    final repo = InterestRepository(sample: true);
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

  group('from the database', () {
    test('an investors document becomes a profile; no name, no profile', () {
      final p = InvestorProfile.fromMap('d1', {
        'fullName': 'Ahmad Hassan',
        'city': 'Riyadh',
        'bio': 'Backs early-stage founders.',
        'preferredSectors': ['HealthTech'],
        'preferredStages': ['Seed'],
        'ticketSize': 'SAR 100K – 500K',
        'linkedinUrl': 'linkedin.com/in/ahmad',
        'offer': 'Introductions',
        'lookingFor': 'Strong teams',
      })!;
      expect(p.name, 'Ahmad Hassan');
      expect(p.sectors, ['HealthTech']);
      expect(p.ticketRange, 'SAR 100K – 500K');
      expect(p.valueOffered, 'Introductions');
      expect(p.hopeToGain, 'Strong teams');
      expect(p.profileBio, 'Backs early-stage founders.');
      expect(InvestorProfile.fromMap('d2', {'city': 'Riyadh'}), isNull);
      expect(p.stageRange, 'Seed');
    });

    test('a repository that was never loaded lists nobody', () {
      final repo = DiscoveryRepository();
      expect(repo.startups(), isEmpty);
      expect(repo.investors(), isEmpty);
    });

    test('joined labels', () {
      final now = DateTime(2026, 10, 19, 12);
      expect(
        DiscoveryRepository.joinedLabel(DateTime(2026, 10, 19), now: now),
        'Joined today',
      );
      expect(
        DiscoveryRepository.joinedLabel(DateTime(2026, 10, 18), now: now),
        'Joined yesterday',
      );
      expect(
        DiscoveryRepository.joinedLabel(DateTime(2026, 10, 16), now: now),
        'Joined 3 days ago',
      );
      expect(
        DiscoveryRepository.joinedLabel(DateTime(2026, 8, 1), now: now),
        'Joined August 2026',
      );
    });
  });
}
