import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/recommender/content_ranker.dart';
import 'package:startsa/recommender/knowledge_filter.dart';

/// The Matches rules, checked two ways:
/// 1. hand-checked cases (the same as tests/test_matching_v2.py), and
/// 2. matching_fixture.json: a slice of the real Firestore data with the
///    results the Python reference (matching_v2.py) gives. Dart must agree.
void main() {
  MatchStartup startup([Map<String, dynamic> over = const {}]) =>
      MatchStartup.fromMap(over['id'] as String? ?? 's1', {
        'name': 'Acme',
        'sector': 'fintech',
        'stage': 'seed',
        'businessModel': 'b2b',
        'location': 'riyadh',
        'lookingFor': ['funding'],
        'fundingRequirement': 2000000,
        'isPublic': true,
        'crunchbaseRank': 10,
        ...over,
      });

  MatchInvestor investor([Map<String, dynamic> over = const {}]) =>
      MatchInvestor.fromMap(over['id'] as String? ?? 'i1', {
        'fullName': 'Sara Example',
        'preferredSectors': ['Fintech'],
        'preferredStages': ['Seed'],
        'preferredCommerceModels': ['Business-to-Business (B2B)'],
        'city': 'Riyadh',
        'ticketSize': 'SAR 100K – 500K',
        'roundSizeMin': null,
        'roundSizeMax': null,
        'investmentsCount': '1–5',
        ...over,
      });

  group('hand-checked cases', () {
    test('a perfect single-choice match is 100%', () {
      final r = matchesForInvestor(investor(), [startup()]);
      expect(r.single.percent, 100);
      expect(r.single.label, 'Raising SAR 2M');
      expect(r.single.reasons, [
        'Same sector (Fintech)',
        'Seed stage',
        'B2B',
        'Fits your ticket',
        'In your region (Riyadh)',
      ]);
    });

    test('score is the weighted cosine without region', () {
      final i = investor({
        'preferredSectors': ['Fintech', 'AI'],
        'preferredStages': ['Pre-seed', 'Seed'],
        'preferredCommerceModels': ['Business-to-Consumer (B2C)'],
      });
      expect(matchesForInvestor(i, [startup()]).single.percent, 56);
    });

    test('blank commerce models spread their weight', () {
      final i = investor({'preferredCommerceModels': <String>[]});
      expect(weightedScore(scoreParts(i, startup())), 1.0);
    });

    test('hard filters', () {
      expect(failedFilters(investor(), startup({'sector': 'media'})), [
        'sector',
      ]);
      expect(failedFilters(investor(), startup({'stage': 'series_a'})), [
        'stage',
      ]);
      expect(
        failedFilters(
          investor({'ticketSize': 'SAR 1M – 5M'}),
          startup({'fundingRequirement': 500000}),
        ),
        ['ticket'],
      );
      expect(
        failedFilters(
          investor({'roundSizeMin': 3000000, 'roundSizeMax': 9000000}),
          startup(),
        ),
        ['round size'],
      );
      final quiet = startup({
        'lookingFor': <String>[],
        'fundingRequirement': null,
      });
      expect(
        failedFilters(
          investor({'ticketSize': 'Over SAR 5M', 'roundSizeMin': 9000000}),
          quiet,
        ),
        isEmpty,
      );
      expect(ticketFits(investor({'ticketSize': 'Other'}), startup()), isNull);
    });

    test('investor side skips private startups; raising-only filter', () {
      final s = [
        startup({'id': 'a'}),
        startup({'id': 'b', 'isPublic': false}),
        startup({
          'id': 'c',
          'lookingFor': <String>[],
          'fundingRequirement': null,
        }),
      ];
      expect(matchesForInvestor(investor(), s).map((m) => m.id), ['a', 'c']);
      expect(
        matchesForInvestor(investor(), s, raisingOnly: true).map((m) => m.id),
        ['a'],
      );
    });

    test('incomplete interests give no matches', () {
      expect(
        matchesForInvestor(investor({'preferredStages': <String>[]}), [
          startup(),
        ]),
        isEmpty,
      );
      expect(
        matchesForStartup(startup(), [
          investor({'preferredSectors': <String>[]}),
        ]),
        isEmpty,
      );
    });

    test('founder side: boosts and order', () {
      final s = startup({'isPublic': false}); // private still gets matches
      final near = investor({
        'id': 'near',
        'fullName': 'Near',
        'city': 'Riyadh',
        'investmentsCount': '1–5',
      });
      final farActive = investor({
        'id': 'far',
        'fullName': 'Far',
        'city': 'Jeddah',
        'investmentsCount': '16+',
      });
      final r = matchesForStartup(s, [farActive, near]);
      expect(r.map((m) => m.id), ['near', 'far']); // 1.055 beats 1.05
      expect(r[0].rankScore, closeTo(1 + 0.05 * 0.5 + 0.03, 1e-12));
      expect(r[0].percent, 100); // capped
      expect(r[1].rankScore, closeTo(1.05, 1e-12));
      expect(r[0].reasons, contains('Based in Riyadh'));
      expect(r[1].reasons, contains('16+ investments'));
    });

    test('ties break on Crunchbase rank, then name', () {
      final s = [
        startup({'id': 'x', 'name': 'Zed', 'crunchbaseRank': null}),
        startup({'id': 'y', 'name': 'Bee', 'crunchbaseRank': 500}),
        startup({'id': 'z', 'name': 'Ace', 'crunchbaseRank': null}),
      ];
      expect(matchesForInvestor(investor(), s).map((m) => m.id), [
        'y',
        'z',
        'x',
      ]);
    });

    test('regions come from cities; amounts round half up', () {
      expect(startup({'location': 'al_khobar'}).region, 'Eastern Province');
      expect(investor({'city': 'Taif'}).region, 'Makkah');
      expect(
        cardLabel(startup({'fundingRequirement': 2250000})),
        'Raising SAR 2.3M',
      );
      expect(
        cardLabel(startup({'fundingRequirement': 500000})),
        'Raising SAR 500K',
      );
    });
  });

  group('close matches', () {
    test('fill the list after the exact ones; ticket still checked', () {
      final r = matchesForInvestor(investor(), [
        startup({'id': 'st', 'name': 'Stage off', 'stage': 'series_b'}),
        startup({
          'id': 'no',
          'name': 'Neither',
          'sector': 'media',
          'stage': 'series_b',
        }),
        startup({
          'id': 'tk',
          'name': 'Ticket off',
          'stage': 'series_b',
          'fundingRequirement': 50000,
        }),
        startup({'id': 'se', 'name': 'Sector off', 'sector': 'media'}),
        startup({'id': 'e', 'name': 'Exact'}),
      ]);
      expect(r.map((m) => m.id), ['e', 'st', 'se']);
      expect(r.map((m) => m.close), [false, true, true]);
      expect(r[1].reasons.take(2), ['Close match', 'Same sector (Fintech)']);
      expect(r[1].reasons, isNot(contains('Seed stage')));
      expect(r[1].percent, lessThan(r[0].percent));
    });

    test('founder side: only when there are fewer than 20 exact', () {
      final s = startup({'isPublic': false});
      final exact = [
        for (var n = 0; n < 25; n++)
          investor({'id': 'x$n', 'fullName': 'Exact $n'}),
      ];
      final close = investor({
        'id': 'c',
        'fullName': 'Close',
        'preferredStages': ['Series A'],
      });
      var r = matchesForStartup(s, [close, ...exact]);
      expect(r.length, topN);
      expect(r.any((m) => m.close), isFalse);
      r = matchesForStartup(s, [close, ...exact.take(3)]);
      expect(r.last.id, 'c');
      expect(r.last.reasons.first, 'Close match');
      expect(r.last.reasons, isNot(contains('Backs Seed startups')));
    });
  });

  test('one-line reason for the card', () {
    expect(shortReason(investor(), startup()), 'Same sector, stage & region');
    expect(
      shortReason(investor({'city': 'Jeddah'}), startup()),
      'Same sector & stage',
    );
    expect(
      shortReason(investor({'city': 'Jeddah'}), startup({'stage': 'series_a'})),
      'Close match · same sector',
    );
    expect(
      shortReason(
        investor({'preferredCommerceModels': <String>[], 'city': null}),
        startup({'sector': 'media'}),
      ),
      'Close match · same stage',
    );
  });

  group('same results as the Python reference (real data)', () {
    final fixture =
        jsonDecode(
              File('test/recommender/matching_fixture.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final startups = [
      for (final s in fixture['startups'] as List)
        MatchStartup.fromMap(s['id'] as String, s as Map<String, dynamic>),
    ];
    final investors = [
      for (final i in fixture['investors'] as List)
        MatchInvestor.fromMap(i['id'] as String, i as Map<String, dynamic>),
    ];
    final byId = {for (final s in startups) s.id: s};

    void same(List<MatchResult> got, List<dynamic> want, String who) {
      expect(
        got.map((m) => m.id).toList(),
        [for (final w in want) w['id']],
        reason: 'order for $who',
      );
      for (var n = 0; n < want.length; n++) {
        final w = want[n] as Map<String, dynamic>;
        expect(got[n].percent, w['percent'], reason: 'percent for $who #$n');
        expect(got[n].close, w['close'], reason: 'close for $who #$n');
        expect(
          got[n].rankScore,
          closeTo((w['rankScore'] as num).toDouble(), 1e-8),
          reason: 'score for $who #$n',
        );
        if (w.containsKey('reasons')) {
          expect(got[n].reasons, w['reasons'], reason: 'reasons for $who #$n');
          expect(got[n].label, w['label'], reason: 'label for $who #$n');
        }
      }
    }

    test('investor Matches for all 104 investors', () {
      final want = fixture['forInvestor'] as Map<String, dynamic>;
      for (final i in investors) {
        same(matchesForInvestor(i, startups), want[i.id] as List, i.id);
      }
    });

    test('investor Matches with "Raising now"', () {
      final want = fixture['forInvestorRaising'] as Map<String, dynamic>;
      for (final i in investors.where((i) => want.containsKey(i.id))) {
        expect(
          matchesForInvestor(i, startups, raisingOnly: true).map((m) => m.id),
          want[i.id],
          reason: i.id,
        );
      }
    });

    test('founder Matches for 120 startups', () {
      final want = fixture['forStartup'] as Map<String, dynamic>;
      for (final entry in want.entries) {
        same(
          matchesForStartup(byId[entry.key]!, investors),
          entry.value as List,
          entry.key,
        );
      }
    });
  });
}
