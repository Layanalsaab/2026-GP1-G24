import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/team_member.dart';

void main() {
  final base = PrototypeSeed.rafeeq.copyWith(
    founderId: 'noura',
    memberRoles: const {},
  );

  group('the Founder title follows control', () {
    final moved = base.copyWith(
      founderId: 'layan',
      memberRoles: const {'reem': 'member'},
    );

    test('whoever holds it is its founder', () {
      expect(StartupRole.titleOf(base, 'noura'), StartupRole.founder);
    });

    test('after leaving, the previous founder is no longer on it', () {
      expect(StartupRole.of(moved, 'noura'), isNull);
      expect(StartupRole.titleOf(moved, 'noura'), isNull);
    });

    test('the new founder has control and the Founder title', () {
      expect(StartupRole.of(moved, 'layan'), StartupRole.founder);
      expect(StartupRole.titleOf(moved, 'layan'), StartupRole.founder);
    });

    test('only the founder manages; a co-founder views like a member', () {
      expect(StartupRole.founder.canManage, isTrue);
      expect(StartupRole.coFounder.canManage, isFalse);
      expect(StartupRole.member.canManage, isFalse);
    });

    test('a member keeps their title', () {
      expect(StartupRole.titleOf(moved, 'reem'), StartupRole.member);
      expect(StartupRole.titleOf(moved, 'stranger'), isNull);
    });
  });

  group('where a startup shows', () {
    test('public and active: everywhere', () {
      final s = base.copyWith(isPublic: true);
      expect(s.isListed, isTrue);
      expect(s.isInHub, isTrue);
    });

    test('public and closed: the Hub only', () {
      final s = base.copyWith(isPublic: true, isClosed: true);
      expect(s.isListed, isFalse);
      expect(s.isInHub, isTrue);
    });

    test('private (closed or not): nowhere', () {
      final s = base.copyWith(isPublic: false, isClosed: true);
      expect(s.isListed, isFalse);
      expect(s.isInHub, isFalse);
    });
  });

  test('the ownership fields go to Firestore and back', () {
    final closedAt = DateTime(2026, 11, 8);
    final s = base.copyWith(
      isClosed: true,
      closedAt: closedAt,
      memberRoles: const {'reem': 'member', 'huda': 'coFounder'},
    );
    final map = s.toMap();
    expect(map[StartupFields.status], StartupFields.statusClosed);
    expect(map[StartupFields.coFounderIds], ['huda']);
    expect(map[StartupFields.closedAt], closedAt);
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isTrue);
    expect(back.closedAt, closedAt);
  });

  test('an older document (no status) is active, with no dates', () {
    final map = base.toMap()..remove(StartupFields.status);
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isFalse);
    expect(back.closedAt, isNull);
  });

  test('the profile and menu title: the highest one among my startups', () {
    String title({
      List<Startup> owned = const [],
      List<StartupRole> joined = const [],
    }) => AccountStrings.startupTitle('noura', owned: owned, joined: joined);
    expect(title(owned: [base], joined: [StartupRole.member]), 'Founder');
    expect(
      title(
        owned: [base.copyWith(id: 'handed')],
        joined: [StartupRole.coFounder],
      ),
      'Founder',
    );
    expect(
      title(joined: [StartupRole.member, StartupRole.coFounder]),
      'Co-founder',
    );
    expect(title(joined: [StartupRole.member]), 'Team member');
    expect(title(), 'Founder'); // no startup yet
  });

  test('a person is named by their team card', () {
    final s = base.copyWith(
      memberRoles: const {'layan': 'coFounder'},
      team: const [
        TeamMember(
          name: 'Layan',
          role: 'CTO',
          contribution: '',
          coFounder: true,
          uid: 'layan',
        ),
      ],
    );
    expect(s.nameOf('layan'), 'Layan');
    expect(s.nameOf('nobody', fallback: 'Owner'), 'Owner');
  });
}
