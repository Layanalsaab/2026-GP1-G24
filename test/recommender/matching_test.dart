import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/recommender/content_ranker.dart';
import 'package:startsa/recommender/knowledge_filter.dart';

/// The matching rules, checked two ways: 1.
void main() {
  MatchStartup startup([Map<String, dynamic> over = const {}]) =>
      MatchStartup.fromMap(over['id'] as String? ?? 's1', {
        'name': 'Acme',
        'sector': 'fintech',
        'stage': 'seed',
        'commerceModel': 'b2b',
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
      final t = ticket({
        'sectors': ['Fintech', 'AI'],
      });
      // A ticket's weights add up to 1.0; the main sector is one of the picks.
      const expected = 0.41 + 0.29 + 0.18 + 0.12 * 0.25;
      expect(
        matchesForTicket(t, b2b, [startup()]).single.percent,
        (expected * 100).round(),
      );
      expect(matchesForTicket(t, b2b, [startup()]).single.percent, 91);
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

  group('criterion satisfaction (PDF 1.9)', () {
    const sectors = ['Fintech', 'AI', 'SaaS', 'EdTech', 'Media'];
    const stages = ['Seed', 'Pre-seed', 'Series A', 'Series B', 'Series C'];
    const models = [
      'Business-to-Business (B2B)',
      'Business-to-Consumer (B2C)',
      'Direct-to-Consumer (D2C)',
    ];

    test('an investor open to many options who fits fully scores 100', () {
      for (final (s, st, m) in [(1, 1, 1), (1, 3, 1), (3, 2, 2), (5, 5, 3)]) {
        final i = investor({
          'preferredSectors': sectors.take(s).toList(),
          'preferredStages': stages.take(st).toList(),
          'preferredCommerceModels': models.take(m).toList(),
        });
        expect(
          matchesForStartup(startup(), [i]).single.percent,
          100,
          reason: 'picks $s, $st, $m',
        );
      }
    });

    MatchInvestor wide() => investor({
      'preferredSectors': ['Fintech', 'AI', 'SaaS'],
      'preferredStages': ['Seed', 'Series A'],
      'preferredCommerceModels': [models[0], models[1]],
    });

    test('worked example A: an exact match scores 100', () {
      final m = matchesForStartup(startup(), [wide()]).single;
      expect(m.close, isFalse);
      expect(m.percent, 100);
    });

    test('worked example B: stage misses, close match at 67', () {
      final s = startup({'stage': 'series_b', 'commerceModel': 'b2c'});
      final m = matchesForStartup(s, [wide()]).single;
      expect(m.close, isTrue);
      expect(m.percent, 67);
    });

    test('worked example C: one pick each, ticket covers half, 94', () {
      final s = startup({'fundingRequirement': 1000000});
      expect(matchesForTicket(ticket(), b2b, [s]).single.percent, 94);
    });

    test('sector outweighs stage', () {
      // Both investors picked 3 sectors, 1 stage and B2B.
      final sectorFits = investor({
        'id': 'p',
        'fullName': 'Zz sector fits',
        'preferredSectors': ['Fintech', 'AI', 'SaaS'],
        'preferredStages': ['Series A'],
      });
      final stageFits = investor({
        'id': 'q',
        'fullName': 'Aa stage fits',
        'preferredSectors': ['AI', 'SaaS', 'Media'],
        'preferredStages': ['Seed'],
      });
      final r = matchesForStartup(startup(), [stageFits, sectorFits]);
      expect(ids(r), ['p', 'q']);
      expect([for (final m in r) m.percent], [67, 53]);
      expect([for (final m in r) m.close], [true, true]);
    });

    test('exact matches stay before close matches', () {
      final exact = investor({
        'id': 'e',
        'fullName': 'Zz exact',
        'preferredCommerceModels': [models[1]],
      });
      final close = investor({
        'id': 'c',
        'fullName': 'Aa close',
        'preferredStages': ['Series A'],
      });
      final r = matchesForStartup(startup(), [close, exact]);
      expect(ids(r), ['e', 'c']);
      expect([for (final m in r) m.percent], [80, 67]);
      // A close ticket match can even score higher than an exact one.
      final exactStartup = startup({
        'id': 'x',
        'name': 'Zz exact',
        'fundingRequirement': 100000000,
      });
      final closeStartup = startup({
        'id': 'y',
        'name': 'Aa close',
        'stage': 'series_a',
        'commerceModel': 'b2c',
        'fundingRequirement': 400000,
      });
      final t = matchesForTicket(ticket(), {'b2c'}, [closeStartup, exactStartup]);
      expect(ids(t), ['x', 'y']);
      expect([for (final m in t) m.percent], [70, 71]);
    });
  });

  group('tie-breakers (PDF 1.7)', () {
    // Every investor here fits the default startup fully (100%).
    MatchTicket covering(String id, String investorId) => ticket({
      'id': id,
      'investorId': investorId,
      'amountMax': 3000000, // more than the 2M left: fit 1
    });

    test('how many investments an investor made does not change the order', () {
      // The team chose not to rank by activity: equal investors go by name.
      final profiles = matchesForStartup(startup(), [
        investor({'id': 'z', 'fullName': 'Zz', 'investmentsCount': '10+'}),
        investor({'id': 'a', 'fullName': 'Aa', 'investmentsCount': '0'}),
        investor({'id': 'm', 'fullName': 'Mm'}), // no answer, as imported data
      ]);
      expect(ids(profiles), ['a', 'm', 'z']);
      expect([for (final m in profiles) m.percent], [100, 100, 100]);
      final tickets = matchesForStartup(
        startup(),
        [
          investor({'id': 'z', 'fullName': 'Zz', 'investmentsCount': '4–6'}),
          investor({'id': 'a', 'fullName': 'Aa', 'investmentsCount': '1–3'}),
        ],
        tickets: [covering('z-T1', 'z'), covering('a-T1', 'a')],
      );
      expect(ids(tickets), ['a', 'z']);
    });

    test('fewer picks breaks a tie', () {
      final r = matchesForStartup(startup(), [
        investor({
          'id': 'a',
          'fullName': 'Aa',
          'preferredSectors': ['Fintech', 'AI', 'SaaS'],
          'preferredStages': ['Seed', 'Series A'],
        }),
        investor({'id': 'z', 'fullName': 'Zz'}),
      ]);
      expect(ids(r), ['z', 'a']);
    });

    test('identical inputs fall back to name, then id', () {
      final r = matchesForStartup(startup(), [
        investor({'id': 'i2', 'fullName': 'b'}),
        investor({'id': 'i1', 'fullName': 'B'}),
      ]);
      expect(ids(r), ['i1', 'i2']);
    });

    test('a close ticket match comes after every exact match (PDF 1.4)', () {
      final r = matchesForStartup(
        startup(),
        [
          investor({'id': 'p', 'fullName': 'Zz exact profile'}),
          investor({'id': 'e', 'fullName': 'Zz exact ticket'}),
          investor({'id': 'c', 'fullName': 'Aa close ticket'}),
        ],
        tickets: [
          covering('e-T1', 'e'),
          ticket({'id': 'c-T1', 'investorId': 'c', 'stages': ['Series A']}),
        ],
      );
      expect(ids(r), ['e', 'p', 'c']);
      expect([for (final m in r) m.close], [false, false, true]);
      expect([for (final m in r) m.ticketId], ['e-T1', null, 'c-T1']);
    });

    test('the best ticket per investor is deterministic', () {
      final r = matchesForStartup(
        startup(),
        [investor()],
        tickets: [covering('i1-T2', 'i1'), covering('i1-T1', 'i1')],
      );
      expect(r.single.ticketId, 'i1-T1');
    });

    test('ticket → startups: equal score and fit go by name', () {
      final r = matchesForTicket(ticket({'amountMax': 3000000}), b2b, [
        startup({'id': 'a', 'name': 'Zz'}),
        startup({'id': 'b', 'name': 'Aa'}),
      ]);
      expect(ids(r), ['b', 'a']);
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
