import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:startsa/features/search/widgets/home_layout.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

const _investor = AppUser(
  uid: 'me',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

Future<void> _pump(WidgetTester t, Widget home) async {
  await t.binding.setSurfaceSize(const Size(412, 2000));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: Scaffold(body: SingleChildScrollView(child: home)),
    ),
  );
  await t.pump(const Duration(milliseconds: 800));
}

HomeItem _investorItem(String id) =>
    HomeItem.fromInvestor(PrototypeSeed.sara).copyIdForTest(id);

extension on HomeItem {
  HomeItem copyIdForTest(String newId) => HomeItem(
    kind: kind,
    id: newId,
    name: name,
    initials: initials,
    tag: tag,
    city: city,
    line: line,
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppSession.instance.reset());

  testWidgets('an investor can bookmark startups, investors and channels', (
    t,
  ) async {
    AppSession.instance.signIn(_investor);
    await _pump(
      t,
      Column(
        children: [
          HomeItemCard(item: HomeItem.fromStartup(PrototypeSeed.rafeeq)),
          HomeItemCard(item: _investorItem('other')),
          HomeItemCard(
            item: HomeItem.fromProgram(PrototypeSeed.programs.first),
          ),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Add bookmark'), findsNWidgets(3));
  });

  testWidgets('an investor cannot bookmark their own profile', (t) async {
    AppSession.instance.signIn(_investor);
    await _pump(t, HomeItemCard(item: _investorItem('me')));
    expect(find.bySemanticsLabel('Add bookmark'), findsNothing);
  });

  testWidgets('a guest never sees a bookmark button', (t) async {
    AppSession.instance.signInAsGuest();
    await _pump(
      t,
      HomeItemCard(item: HomeItem.fromStartup(PrototypeSeed.rafeeq)),
    );
    expect(find.bySemanticsLabel('Add bookmark'), findsNothing);
  });

  testWidgets('the investor sees all three types by default', (t) async {
    AppSession.instance.signIn(_investor);
    await t.binding.setSurfaceSize(const Size(412, 2000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: BookmarksScreen(
          items: [
            SavedBookmark(
              item: HomeItem.fromStartup(PrototypeSeed.rafeeq),
              savedAt: DateTime(2026, 10, 20),
            ),
            SavedBookmark(
              item: HomeItem.fromInvestor(PrototypeSeed.sara),
              savedAt: DateTime(2026, 10, 18),
            ),
            SavedBookmark(
              item: HomeItem.fromProgram(PrototypeSeed.programs.first),
              savedAt: DateTime(2026, 10, 15),
            ),
          ],
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 800));
    expect(find.text('All types'), findsOneWidget);
    expect(find.text('Newest first'), findsOneWidget);
    expect(find.byType(HomeCard), findsNWidgets(3));
  });
}
