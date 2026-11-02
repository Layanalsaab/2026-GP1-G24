import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/search/widgets/home_layout.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/features/startups/widgets/role_tag.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';

import '../../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeStartupRepository repo;
  setUp(() {
    repo = FakeStartupRepository();
    StartupRepository.instance = repo;
    AppSession.instance = AppSession();
  });

  Future<void> open(
    WidgetTester t,
    List<MyStartupEntry> team, {
    double width = 412,
  }) async {
    t.view.physicalSize = Size(width, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: MyStartupsScreen(teamStartups: team)));
    await t.pumpAndSettle();
  }

  testWidgets('every startup is the Hub card (HomeCard), nothing separate', (
    t,
  ) async {
    repo.startups.addAll([
      PrototypeSeed.rafeeq,
      PrototypeSeed.daftar.copyWith(isPublic: false),
    ]);
    await open(t, const []);
    expect(find.byType(HomeCard), findsNWidgets(2));
    expect(find.byType(HomeItemCard), findsNWidgets(2));
  });

  testWidgets('allowed differences only: capsules, no bookmark, a button', (
    t,
  ) async {
    repo.startups.addAll([
      PrototypeSeed.rafeeq,
      PrototypeSeed.daftar.copyWith(isPublic: false),
    ]);
    await open(t, const []);
    // The Hub card's own parts are there: name, sector, city, description.
    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('HealthTech'), findsOneWidget);
    expect(find.text('Riyadh'), findsWidgets);
    // Role capsule on both, "Private" only on the private one.
    expect(find.byType(RoleTag), findsNWidgets(2));
    expect(find.byType(PrivateTag), findsOneWidget);
    // Share stays (as in the Hub); the bookmark does not.
    expect(find.bySemanticsLabel('Share'), findsNWidgets(2));
    expect(find.bySemanticsLabel('Add bookmark'), findsNothing);
    expect(find.bySemanticsLabel('Remove bookmark'), findsNothing);
    // Founder: "Manage".
    expect(find.text('Manage'), findsNWidgets(2));
    expect(find.text('View'), findsNothing);
  });

  testWidgets('the capsules hug their text and sit on the name\'s line', (
    t,
  ) async {
    repo.startups.add(PrototypeSeed.daftar.copyWith(isPublic: false));
    // (A wide screen: the test font is much wider than Inter, so on a phone
    // width the capsules would drop under the name, as designed.)
    await open(t, const [], width: 1000);
    final nameY = t.getTopLeft(find.text('Daftar')).dy;
    final role = find.byType(RoleTag);
    final priv = find.byType(PrivateTag);
    // Same line as the name (the capsule is 20 high, the name line 23).
    expect(
      (t.getCenter(role).dy - t.getCenter(find.text('Daftar')).dy).abs(),
      lessThan(4),
    );
    expect(t.getSize(role).height, 20);
    expect(t.getSize(priv).height, 20);
    expect(
      t.getTopLeft(role).dx,
      greaterThan(t.getTopLeft(find.text('Daftar')).dx),
    );
    expect(
      t.getTopLeft(priv).dx,
      greaterThan(t.getTopLeft(role).dx),
      reason: 'Private is next to the role capsule',
    );
    // They hug the text: far narrower than the card.
    expect(t.getSize(role).width, lessThan(120));
    expect(t.getSize(priv).width, lessThan(120));
    expect(nameY, greaterThan(0));
  });

  testWidgets('a team member gets "View", a co-founder "Manage"', (t) async {
    await open(t, [
      MyStartupEntry(
        startup: PrototypeSeed.rafeeq,
        role: StartupRole.member,
        addedAt: DateTime(2026, 10, 1),
      ),
      MyStartupEntry(
        startup: PrototypeSeed.daftar,
        role: StartupRole.coFounder,
        addedAt: DateTime(2026, 10, 2),
      ),
    ]);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Team member'), findsOneWidget);
    expect(find.text('Co-founder'), findsOneWidget);
  });

  testWidgets('tapping the card opens Manage, not the public page', (t) async {
    repo.startups.add(PrototypeSeed.rafeeq);
    await open(t, const []);
    await t.tap(find.text('Rafeeq Health'));
    await t.pumpAndSettle();
    // Manage has its tabs (the public page has Overview / Business / ...).
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Rounds'), findsWidgets);
  });

  testWidgets('Hub card vs My Startups card: same width, same parts', (
    t,
  ) async {
    repo.startups.add(PrototypeSeed.rafeeq);
    await open(t, const [], width: 1000);
    final mine = t.getSize(find.byType(HomeCard));
    // The same startup as a Hub card.
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HomeItemCard(
              item: HomeItem.fromStartup(PrototypeSeed.rafeeq),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final hub = t.getSize(find.byType(HomeCard));
    expect(mine.width, hub.width);
    // The only extra height is the Manage / View line.
    expect(mine.height - hub.height, lessThan(45));
    expect(mine.height, greaterThanOrEqualTo(hub.height));
  });
}
