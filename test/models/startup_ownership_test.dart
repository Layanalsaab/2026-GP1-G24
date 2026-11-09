import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/team_member.dart';

/// Closing a startup and the owner leaving (docs: Closing a Startup, Leaving
/// and Deleting an Account): who keeps which title, and where a closed
/// startup shows.
void main() {
  final base = PrototypeSeed.rafeeq.copyWith(
    founderId: 'noura',
    memberRoles: const {},
  );

  group('title and owner are separate', () {
    // Noura created it, then left and named Layan the owner.
    final moved = base.copyWith(
      founderId: 'layan',
      foundedBy: 'noura',
      memberRoles: const {'reem': 'member'},
    );

    test('an older startup: the owner is the founder', () {
      expect(base.originalFounderId, 'noura');
      expect(StartupRole.titleOf(base, 'noura'), StartupRole.founder);
      expect(StartupRole.isTransferredOwner(base, 'noura'), isFalse);
    });

    test('after leaving, the founder is no longer on it', () {
      expect(moved.originalFounderId, 'noura');
      expect(StartupRole.of(moved, 'noura'), isNull);
    });

    test('the new owner has control and is shown as Owner', () {
      expect(StartupRole.of(moved, 'layan'), StartupRole.founder);
      expect(StartupRole.isTransferredOwner(moved, 'layan'), isTrue);
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
    final changed = DateTime(2026, 11, 1);
    final s = base.copyWith(
      foundedBy: 'noura',
      isClosed: true,
      closedAt: closedAt,
      ownerChangedAt: changed,
      memberRoles: const {'reem': 'member', 'huda': 'coFounder'},
    );
    final map = s.toMap();
    expect(map[StartupFields.status], StartupFields.statusClosed);
    expect(map[StartupFields.coFounderIds], ['huda']);
    expect(map[StartupFields.foundedBy], 'noura');
    expect(map[StartupFields.closedAt], closedAt);
    expect(map[StartupFields.ownerChangedAt], changed);
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isTrue);
    expect(back.closedAt, closedAt);
    expect(back.ownerChangedAt, changed);
    expect(back.originalFounderId, 'noura');
  });

  test('an older document (no status) is active, with no dates', () {
    final map = base.toMap()..remove(StartupFields.status);
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isFalse);
    expect(back.closedAt, isNull);
    expect(back.ownerChangedAt, isNull);
  });

  test('the profile and menu title: the highest one among my startups', () {
    // Noura created `base` and still owns it; `handed` was handed to her.
    final handed = base.copyWith(id: 'handed', foundedBy: 'layan');
    String title({
      List<Startup> owned = const [],
      List<StartupRole> joined = const [],
    }) => AccountStrings.startupTitle('noura', owned: owned, joined: joined);
    expect(title(owned: [base], joined: [StartupRole.member]), 'Founder');
    expect(title(owned: [handed], joined: [StartupRole.coFounder]), 'Owner');
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
