import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/team_member.dart';
import 'package:startsa/shared_ui/widgets/cards/avatars.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> show(WidgetTester t, Widget child) async {
    await t.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: child))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  group('default picture', () {
    testWidgets('no picture: the initials show', (t) async {
      await show(t, const HueAvatar(name: 'Rafeeq Health'));
      expect(find.text('RH'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a picture that cannot load falls back to the initials', (
      t,
    ) async {
      await show(
        t,
        const TileAvatar(
          initials: 'RH',
          imageUrl: 'https://example.invalid/logo.png',
        ),
      );
      expect(find.text('RH'), findsOneWidget);
    });

    testWidgets('a picture that cannot load keeps the Hue avatar initials', (
      t,
    ) async {
      await show(
        t,
        const HueAvatar(
          name: 'Rafeeq Health',
          imageUrl: 'https://example.invalid/logo.png',
        ),
      );
      expect(find.text('RH'), findsOneWidget);
    });

    testWidgets('the startup header tile also falls back', (t) async {
      await show(
        t,
        const HeaderAvatarTile(
          initials: 'RH',
          imageUrl: 'https://example.invalid/logo.png',
        ),
      );
      expect(find.text('RH'), findsOneWidget);
    });

    testWidgets('an empty URL is the same as none', (t) async {
      await show(t, const TileAvatar(initials: 'RH', imageUrl: ''));
      expect(find.text('RH'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('pictures reach the cards', () {
    test('a startup card item carries the logo', () {
      final s = PrototypeSeed.rafeeq.copyWith(logoUrl: 'https://x.test/l.png');
      expect(HomeItem.fromStartup(s).imageUrl, 'https://x.test/l.png');
      expect(HomeItem.fromStartup(s).withJoined('Joined today').imageUrl,
          'https://x.test/l.png');
    });

    test('a team member keeps the photo through copyWith, not in the map', () {
      const m = TeamMember(name: 'Sara', role: 'COO', contribution: 'x');
      final withPhoto = m.copyWith(photoData: 'QUJD');
      expect(withPhoto.photoData, 'QUJD');
      expect(withPhoto.toMap().containsKey('photoData'), isFalse);
      // The photo is not part of the saved team (so editing isn't "dirty").
      expect(withPhoto == m, isTrue);
    });
  });
}
