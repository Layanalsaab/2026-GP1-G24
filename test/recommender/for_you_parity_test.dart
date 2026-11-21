import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/recommender/for_you.dart';

/// The backend (backend/app) must rank exactly like this file's For You code.
/// The fixture is written by: cd backend && .venv/bin/python -m tests.make_parity_fixture
Features _features(Object? raw) {
  final groups = (raw as Map).cast<String, dynamic>();
  return Features({
    for (final g in groupWeights.keys)
      g: {
        for (final v in (groups[g] as List? ?? const []))
          v as String: 1.0,
      },
  });
}

void main() {
  test('the Python backend and the Dart For You rank the same way', () {
    final data =
        jsonDecode(
              File(
                'backend/tests/fixtures/for_you_parity.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final now = DateTime.parse(data['now'] as String);
    final signals = [
      for (final like in data['likes'] as List)
        Signal(
          _features(like['groups']),
          DateTime.parse(like['at'] as String),
          strength: (like['strength'] as num).toDouble(),
        ),
    ];
    final taste = Taste.build(_features(data['base']), signals, now: now);
    final candidates = [
      for (final c in data['candidates'] as List)
        Candidate<String>(
          c['id'] as String,
          c['name'] as String,
          _features(c['groups']),
          c['mainSector'] as String?,
        ),
    ];

    final picks = recommendBest(
      [taste],
      candidates,
      limit: data['limit'] as int,
    );

    final expected = data['expected'] as List;
    expect([for (final p in picks) p.item], [
      for (final e in expected) e['id'],
    ]);
    for (var k = 0; k < picks.length; k++) {
      expect(
        picks[k].score,
        closeTo((expected[k]['score'] as num).toDouble(), 1e-9),
      );
    }
  });
}
