import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/features/startups/widgets/role_tag.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/team_member.dart';

TeamMember _member({
  bool founder = false,
  bool co = false,
  String uid = 'seed-a-0',
}) => TeamMember(
  name: 'Sara Alamri',
  role: 'CEO',
  contribution: 'x',
  isFounder: founder,
  coFounder: co,
  uid: uid,
);

StartupRole? _roleOf(List<dynamic> tags) => (tags.first as RoleTag).role;

void main() {
  group('team tags of a sample startup', () {
    test('the card flagged as founder shows Founder', () {
      final tags = teamTagsOf(
        _member(founder: true),
        isYou: false,
        ownerId: 'crunchbase-dataset',
      );
      expect(_roleOf(tags), StartupRole.founder);
    });

    test('a co-founder and a member keep their own tags', () {
      expect(
        _roleOf(
          teamTagsOf(
            _member(co: true),
            isYou: false,
            ownerId: 'crunchbase-dataset',
          ),
        ),
        StartupRole.coFounder,
      );
      expect(
        _roleOf(
          teamTagsOf(_member(), isYou: false, ownerId: 'crunchbase-dataset'),
        ),
        StartupRole.member,
      );
    });
  });

  group('team tags of a startup with a real owner', () {
    test('the founder is whoever holds the startup', () {
      expect(
        _roleOf(teamTagsOf(_member(uid: 'u1'), isYou: false, ownerId: 'u1')),
        StartupRole.founder,
      );
      expect(
        _roleOf(
          teamTagsOf(
            _member(founder: true, uid: 'u2'),
            isYou: false,
            ownerId: 'u1',
          ),
        ),
        StartupRole.member,
      );
    });
  });
}
