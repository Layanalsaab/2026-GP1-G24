import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/team_member.dart';

/// Deleting, closing and transferring a startup: what the owner may do and
/// who keeps which title.
void main() {
  final base = PrototypeSeed.rafeeq.copyWith(
    founderId: 'noura',
    memberRoles: const {},
  );

  group('the one way the owner can end a startup', () {
    test('nobody else on it: delete', () {
      expect(base.ownerOption, OwnerOption.delete);
    });

    test('a joined co-founder: transfer ownership', () {
      final s = base.copyWith(
        memberRoles: const {'layan': 'coFounder', 'reem': 'member'},
      );
      expect(s.ownerOption, OwnerOption.transfer);
    });

    test('only team members: close', () {
      final s = base.copyWith(memberRoles: const {'reem': 'member'});
      expect(s.ownerOption, OwnerOption.close);
    });
  });

  group('title and owner are separate', () {
    final moved = base.copyWith(
      founderId: 'layan',
      foundedBy: 'noura',
      memberRoles: const {'noura': 'coFounder', 'reem': 'member'},
    );

    test('an older startup: the owner is the founder', () {
      expect(base.originalFounderId, 'noura');
      expect(StartupRole.titleOf(base, 'noura'), StartupRole.founder);
      expect(StartupRole.isTransferredOwner(base, 'noura'), isFalse);
    });

    test('after a transfer the person who created it stays Founder', () {
      expect(StartupRole.of(moved, 'noura'), StartupRole.coFounder);
      expect(StartupRole.titleOf(moved, 'noura'), StartupRole.founder);
    });

    test('the new owner has full control and is a co-founder', () {
      expect(StartupRole.of(moved, 'layan'), StartupRole.founder);
      expect(StartupRole.titleOf(moved, 'layan'), StartupRole.coFounder);
      expect(StartupRole.isTransferredOwner(moved, 'layan'), isTrue);
    });

    test('a member keeps their title', () {
      expect(StartupRole.titleOf(moved, 'reem'), StartupRole.member);
      expect(StartupRole.titleOf(moved, 'stranger'), isNull);
    });
  });

  test('the ownership fields go to Firestore and back', () {
    final s = base.copyWith(
      foundedBy: 'noura',
      formerFounderId: 'old-founder',
      isClosed: true,
      memberRoles: const {'reem': 'member', 'huda': 'coFounder'},
    );
    final map = s.toMap();
    expect(map[StartupFields.status], StartupFields.statusClosed);
    expect(map[StartupFields.coFounderIds], ['huda']);
    expect(map[StartupFields.foundedBy], 'noura');
    expect(map[StartupFields.formerFounderId], 'old-founder');
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isTrue);
    expect(back.formerFounderId, 'old-founder');
    expect(back.originalFounderId, 'noura');
    expect(back.isListed, isFalse, reason: 'a closed startup is not listed');
  });

  test('an older document (no status) is active', () {
    final map = base.toMap()..remove(StartupFields.status);
    final back = Startup.fromMap('x', map)!;
    expect(back.isClosed, isFalse);
  });

  test('the first co-founder in the team list takes over', () {
    final s = base.copyWith(
      memberRoles: const {'huda': 'coFounder', 'layan': 'coFounder'},
      team: const [
        TeamMember(
          name: 'Noura',
          role: 'CEO',
          contribution: '',
          isFounder: true,
          uid: 'noura',
        ),
        TeamMember(
          name: 'Layan',
          role: 'CTO',
          contribution: '',
          coFounder: true,
          uid: 'layan',
        ),
        TeamMember(
          name: 'Huda',
          role: 'COO',
          contribution: '',
          coFounder: true,
          uid: 'huda',
        ),
      ],
    );
    expect(s.coFoundersInTeamOrder, ['layan', 'huda']);
    expect(s.nameOf('layan'), 'Layan');
    expect(s.nameOf('nobody', fallback: 'a co-founder'), 'a co-founder');
  });
}
