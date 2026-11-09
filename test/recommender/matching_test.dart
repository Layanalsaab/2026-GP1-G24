import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/recommender/content_ranker.dart';
import 'package:startsa/recommender/knowledge_filter.dart';

/// The matching rules, checked two ways:
/// 1. hand-checked cases (the same as tests/test_matching_v2.py), and
/// 2. matching_fixture.json: a slice of the real Firestore data plus
///    synthetic tickets, with the results the Python reference
///    (matching_v2.py) gives. Dart must agree.
void main() {
  MatchStartup startup([Map<String, dynamic> over = const {}]) =>
      MatchStartup.fromMap(over['id'] as String? ?? 's1', {
        'name': 'Acme',
        'sector': 'fintech',
        'stage': 'seed',
        'businessModel': 'b2b',
        'lookingFor': ['funding'],
        'fundingRequirement': 2000000,
        'raisedInRound': 0,
        'isPublic': true,
        ...over,
      });

  MatchInvestor investor([Map<String, dynamic> over = const {}]) =>
      MatchInvestor.fromMap(over['id'] as String? ?? 'i1', {
        'fullName': 'Sara Example',
        'preferredSectors': ['Fintech'],
        'preferredStages': ['Seed'],
        'preferredCommerceModels': ['Business-to-Business (B2B)'],
        'ticketSize': 'SAR 100K – 500K',
        'roundSizeMin': null,
        'roundSizeMax': null,
        'hasLedRound': true,
        ...over,
      });

  MatchTicket ticket([Map<String, dynamic> over = const {}]) =>
      MatchTicket.fromMap(over['id'] as String? ?? 'i1-T1', {
        'investorId': 'i1',
        'name': 'Ticket 1',
        'sectors': ['Fintech'],
        'stages': ['Seed'],
        'amountMin': 100000,
        'amountMax': 500000,
        'status': 'open',
        ...over,
      });

  const b2b = {'b2b'};
  List<String> ids(List<MatchResult> r) => [for (final m in r) m.id];
  List<String> rows(MatchResult m) => [for (final r in m.rows) '$r'];

  group('who can appear', () {
    test('private, closed and not raising startups never match a ticket', () {
      final s = [
        startup({'id': 'a'}),
        startup({'id': 'b', 'isPublic': false}),
        startup({'id': 'c', 'status': 'closed'}),
        startup({
          'id': 'd',
          'lookingFor': ['support'],
          'fundingRequirement': null,
        }),
        startup({'id': 'e', 'raisedInRound': 2000000}), // nothing left
      ];
      expect(ids(matchesForTicket(ticket(), b2b, s)), ['a']);
    });

    test('only open tickets match', () {
      expect(
        matchesForTicket(ticket({'status': 'used'}), b2b, [startup()]),
        isEmpty,
      );
      expect(
        matchesForTicket(ticket({'status': 'closed'}), b2b, [startup()]),
        isEmpty,
      );
    });

    test('remaining is the amount minus what is raised', () {
      expect(
        startup({
          'fundingRequirement': 900000,
          'raisedInRound': 400000,
        }).remaining,
        500000,
      );
      expect(
        startup({
          'lookingFor': <String>[],
          'fundingRequirement': 900000,
        }).remaining,
        0,
      );
      expect(startup({'status': 'closed'}).isListed, isFalse);
      expect(startup({'isPublic': false}).isListed, isFalse);
    });
  });

  group('tickets', () {
    test('a perfect match is 100% with its rows', () {
      final r = matchesForTicket(ticket(), b2b, [
        startup({'fundingRequirement': 400000}),
      ]).single;
      expect(r.percent, 100);
      expect(r.close, isFalse);
      expect(rows(r), [
        '+ Sector · Fintech',
        '+ Stage · Seed',
        '+ Commerce model · B2B',
        '+ Amount · SAR 400K left (within your ticket SAR 100K–500K)',
      ]);
    });

    test('the ticket minimum is checked against what is left', () {
      final s = startup({
        'fundingRequirement': 1000000,
        'raisedInRound': 950000,
      }); // 50K left
      expect(matchesForTicket(ticket({'amountMin': 100000}), b2b, [s]), isEmpty);
      final r = matchesForTicket(
        ticket({'amountMin': 10000, 'amountMax': 20000}),
        b2b,
        [s],
      ).single;
      expect(
        '${r.rows.last}',
        '+ Amount · SAR 50K left (your ticket SAR 10K–20K covers up to 40%)',
      );
      expect(r.percent, 93); // (0.88 + 0.12 * 0.4) / 1.0
    });

    test('the score uses the profile commerce models and round fit', () {
      // SAR 2M left, the ticket goes up to 500K: it covers a quarter.
      final t = ticket({
        'sectors': ['Fintech', 'AI'],
      });
      // A ticket's weights add up to 1.0.
      final expected = 0.41 / math.sqrt(2) + 0.29 + 0.18 + 0.12 * 0.25;
      expect(
        matchesForTicket(t, b2b, [startup()]).single.percent,
        (expected * 100).round(),
      );
      expect(matchesForTicket(t, b2b, [startup()]).single.percent, 79);
      // No commerce models in the profile: that part is skipped.
      expect(
        matchesForTicket(ticket(), const {}, [startup()]).single.percent,
        89,
      );
      final r = matchesForTicket(ticket(), {'b2c'}, [startup()]).single;
      expect(r.percent, 73);
      expect('${r.rows[2]}', '- Commerce model · B2B (you prefer B2C)');
    });

    test('round fit breaks ties between otherwise equal startups', () {
      final small = startup({
        'id': 'a',
        'name': 'Zz small',
        'fundingRequirement': 600000,
      }); // the ticket covers 5/6
      final big = startup({
        'id': 'b',
        'name': 'Aa big',
        'fundingRequirement': 24000000,
      }); // the ticket covers 2%
      expect(ids(matchesForTicket(ticket(), b2b, [big, small])), ['a', 'b']);
      expect(roundFit(ticket(), small), 500000 / 600000);
      expect(roundFit(ticket(), big), 500000 / 24000000);
      expect(roundFit(ticket({'amountMax': 900000}), small), 1.0);
      // Profile matches have no fit part.
      expect(scoreParts(investor(), small).containsKey('fit'), isFalse);
    });

    test('close matches come after the exact ones', () {
      final r = matchesForTicket(ticket(), b2b, [
        startup({
          'id': 'no',
          'name': 'Neither',
          'sector': 'media',
          'stage': 'series_a',
        }),
        startup({'id': 'st', 'name': 'Stage off', 'stage': 'series_a'}),
        startup({'id': 'se', 'name': 'Sector off', 'sector': 'media'}),
        startup({'id': 'e', 'name': 'Exact'}),
      ]);
      // Missing the stage keeps the sector (47%), missing the sector keeps
      // the stage (33%).
      expect(ids(r), ['e', 'st', 'se']);
      expect([for (final m in r) m.close], [false, true, true]);
      expect('${r[1].rows[1]}', '- Stage · Series A (your ticket: Seed)');
      expect('${r[2].rows[0]}', '- Sector · Media (your ticket: Fintech)');
    });

    test('typed Other sector, and other sectors count half', () {
      final sports = startup({'sector': 'other', 'sectorOther': 'Sports Tech'});
      expect(
        matchesForTicket(
          ticket({
            'sectors': ['SportsTech'],
          }),
          b2b,
          [sports],
        ).single.close,
        isFalse,
      );
      expect(
        matchesForTicket(
          ticket({
            'sectors': ['Other'],
          }),
          b2b,
          [sports],
        ).single.close,
        isFalse,
      );
      final multi = startup({
        'sector': 'media',
        'otherSectors': ['Fintech'],
      });
      final r = matchesForTicket(ticket(), b2b, [multi]).single;
      expect(r.close, isTrue); // the main sector is the filter
      expect(r.percent, 71); // 0.41 * 0.5 + 0.29 + 0.18 + 0.12 * 0.25
      expect('${r.rows[0]}', '+ Sector · Fintech (one of its other sectors)');
    });

    test('ties by name', () {
      final s = [
        startup({'id': 'x', 'name': 'Zed'}),
        startup({'id': 'y', 'name': 'Bee'}),
        startup({'id': 'w', 'name': 'cat'}),
      ];
      expect(ids(matchesForTicket(ticket(), b2b, s)), ['y', 'w', 'x']);
    });
  });

  group('the founder’s round', () {
    test('a closed or not raising startup gets nothing', () {
      expect(
        matchesForStartup(startup({'status': 'closed'}), [investor()]),
        isEmpty,
      );
      expect(
        matchesForStartup(startup({'lookingFor': <String>[]}), [investor()]),
        isEmpty,
      );
    });

    test('a private startup still gets matches', () {
      expect(
        ids(matchesForStartup(startup({'isPublic': false}), [investor()])),
        ['i1'],
      );
    });

    test('ticket holders first, then profiles, each investor once', () {
      final s = startup({'fundingRequirement': 400000});
      final pool = [
        investor({'id': 'a', 'fullName': 'Aa'}), // profile only
        investor({
          'id': 'b',
          'fullName': 'Bb',
          'preferredSectors': ['Media'],
        }), // only the ticket fits
        investor({'id': 'c', 'fullName': 'Cc'}), // profile and ticket
      ];
      final tickets = [
        ticket({'id': 'b-T1', 'investorId': 'b'}),
        ticket({'id': 'c-T1', 'investorId': 'c'}),
        ticket({
          'id': 'c-T2',
          'investorId': 'c',
          'sectors': ['Fintech', 'AI'],
        }),
      ];
      final r = matchesForStartup(s, pool, tickets: tickets);
      expect(ids(r), ['b', 'c', 'a']);
      // c's best ticket: 100% beats 86%.
      expect([for (final m in r) m.ticketId], ['b-T1', 'c-T1', null]);
      expect(
        '${r[0].rows.last}',
        '+ Their ticket · SAR 100K–500K (SAR 400K left in your round)',
      );
    });

    test('used or closed tickets fall back to the profile', () {
      final r = matchesForStartup(
        startup(),
        [investor()],
        tickets: [ticket({'status': 'used'})],
      );
      expect(r.single.ticketId, isNull);
    });

    test('profile rows; round size uses the round, the ticket what is left',
        () {
      final s = startup({
        'fundingRequirement': 2000000,
        'raisedInRound': 1800000,
      }); // 200K left
      final r = matchesForStartup(s, [
        investor({'roundSizeMin': 1000000, 'roundSizeMax': 5000000}),
      ]).single;
      expect(rows(r), [
        '+ Sector · Fintech',
        '+ Stage · Seed',
        '+ Commerce model · B2B',
        '+ Ticket size · SAR 100K – 500K (SAR 200K left in your round)',
        '+ Round size · SAR 1M–SAR 5M (your round is SAR 2M)',
      ]);
      expect(
        matchesForStartup(s, [investor({'roundSizeMin': 3000000})]),
        isEmpty,
      );
      expect(
        matchesForStartup(s, [investor({'ticketSize': 'SAR 500K – 1M'})]),
        isEmpty,
      );
    });

    test('no lead tie-break: equal scores go by name', () {
      final pool = [
        investor({'id': 'z', 'fullName': 'Zz', 'hasLedRound': true}),
        investor({'id': 'a', 'fullName': 'Aa', 'hasLedRound': false}),
      ];
      expect(
        ids(matchesForStartup(startup({'wantsLeadInvestor': true}), pool)),
        ['a', 'z'],
      );
    });
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
    final tickets = [
      for (final t in fixture['tickets'] as List)
        MatchTicket.fromMap(t['id'] as String, t as Map<String, dynamic>),
    ];
    final investorById = {for (final i in investors) i.id: i};
    final startupById = {for (final s in startups) s.id: s};

    void same(List<MatchResult> got, List<dynamic> want, String who) {
      expect(ids(got), [for (final w in want) w['id']], reason: 'order, $who');
      for (var n = 0; n < want.length; n++) {
        final w = want[n] as Map<String, dynamic>;
        expect(got[n].percent, w['percent'], reason: 'percent, $who #$n');
        expect(got[n].close, w['close'], reason: 'close, $who #$n');
        expect(got[n].ticketId, w['ticketId'], reason: 'ticket, $who #$n');
        expect(
          got[n].score,
          closeTo((w['score'] as num).toDouble(), 1e-8),
          reason: 'score, $who #$n',
        );
        if (w.containsKey('rows')) {
          expect(rows(got[n]), w['rows'], reason: 'rows, $who #$n');
        }
      }
    }

    test('every ticket’s matches', () {
      final want = fixture['forTicket'] as Map<String, dynamic>;
      expect(want.length, tickets.length);
      for (final t in tickets) {
        same(
          matchesForTicket(t, investorById[t.investorId]!.models, startups),
          want[t.id] as List,
          t.id,
        );
      }
    });

    test('founder round matches for 150 startups', () {
      final want = fixture['forStartup'] as Map<String, dynamic>;
      for (final entry in want.entries) {
        same(
          matchesForStartup(
            startupById[entry.key]!,
            investors,
            tickets: tickets,
          ),
          entry.value as List,
          entry.key,
        );
      }
    });
  });
}
