import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/features/startup_profile/screens/team_member_profile_screen.dart';
import 'package:startsa/models/public_profile.dart';
import 'package:startsa/models/team_member.dart';

class _FakeProfiles implements PublicProfileRepository {
  _FakeProfiles(this.profiles);

  final Map<String, PublicProfile> profiles;

  @override
  Future<PublicProfile?> get(String id) async => profiles[id];

  @override
  Future<List<ProfileStartupRef>> startupsOf(PublicProfile profile) async =>
      profile.startups;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

PublicProfile _profile({
  String? email,
  String? phone,
  bool emailPublic = false,
  bool phonePublic = false,
}) => PublicProfile(
  id: 'seed-1',
  fullName: 'Khaled Zaatarah',
  city: 'Riyadh',
  bio: 'Founder of VUZ, a media startup in Riyadh.',
  sectors: const ['Media'],
  email: email,
  phone: phone,
  emailPublic: emailPublic,
  phonePublic: phonePublic,
  startups: const [
    ProfileStartupRef(id: 's1', name: 'VUZ', role: 'founder'),
    ProfileStartupRef(id: 's2', name: 'Naql', role: 'coFounder'),
  ],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const member = TeamMember(
    name: 'Khaled Zaatarah',
    role: 'Founder',
    contribution: '',
    isFounder: true,
    uid: 'seed-1',
  );

  Future<void> pump(WidgetTester t, PublicProfile? profile) async {
    t.view.physicalSize = const Size(412, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: TeamMemberProfileScreen(
          member: member,
          startupName: 'VUZ',
          repository: _FakeProfiles({'seed-1': ?profile}),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  group('PublicProfile', () {
    test('a private e-mail or phone is never read, even if stored', () {
      final p = PublicProfile.fromMap('x', {
        'fullName': 'Sara Alamri',
        'email': 'sara@gmail.com',
        'phone': '551234567',
        'emailPublic': false,
        'phonePublic': true,
      })!;
      expect(p.email, isNull);
      expect(p.phone, '551234567');
    });
  });

  group('Team member profile', () {
    testWidgets('shows the full profile, both contacts private', (t) async {
      await pump(t, _profile());
      expect(find.text('Khaled Zaatarah'), findsOneWidget);
      expect(find.textContaining('Riyadh'), findsWidgets);
      expect(
        find.text('Founder of VUZ, a media startup in Riyadh.'),
        findsOneWidget,
      );
      expect(find.text('Startups'), findsOneWidget);
      expect(find.text('VUZ'), findsWidgets);
      expect(find.text('Co-founder'), findsOneWidget);
      // Both private: no Contact section at all.
      expect(find.text('Contact'), findsNothing);
    });

    testWidgets('only the email is public: only the email shows', (t) async {
      await pump(t, _profile(email: 'k@gmail.com', emailPublic: true));
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('k@gmail.com'), findsOneWidget);
      expect(find.textContaining('+966'), findsNothing);
    });

    testWidgets('only the phone is public: only the phone shows', (t) async {
      await pump(t, _profile(phone: '551234567', phonePublic: true));
      expect(find.text('Contact'), findsOneWidget);
      expect(find.text('+966 551234567'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('no profile: falls back to what the startup knows', (t) async {
      await pump(t, null);
      expect(find.text('Khaled Zaatarah'), findsOneWidget);
      expect(find.text('Founder'), findsWidgets);
      expect(find.text('Contact'), findsNothing);
      expect(find.text('Startups'), findsNothing);
    });
  });
}
